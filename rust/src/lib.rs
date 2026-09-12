//! C FFI bindings for Lightning CSS.
//!
//! # Safety
//!
//! Every function here requires that pointer arguments are valid, NUL-terminated C strings unless
//! documented as nullable. Returned pointers are owned by the caller and must be released with
//! `lightningcss_string_free` or `lightningcss_result_free`.

#![allow(clippy::missing_safety_doc)]

mod options;
mod scope;

use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;
use std::sync::{Arc, RwLock};

use lightningcss::bundler::{BundleErrorKind, Bundler, FileProvider};
use lightningcss::stylesheet::{MinifyOptions, ParserOptions, PrinterOptions, StyleAttribute, StyleSheet};
use lightningcss::visitor::Visit;

use crate::options::{TransformOptions, TransformResult};
use crate::scope::Scoper;

pub const VERSION: &str = env!("GEM_VERSION");
pub const LIGHTNINGCSS_VERSION: &str = env!("LIGHTNINGCSS_VERSION");

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LightningCssErrorCode {
  None = 0,
  Parse,
  Option,
  Bundle,
  Internal,
}

#[repr(C)]
pub struct LightningCssResult {
  pub value: *mut c_char,
  pub error: *mut c_char,
  pub code: LightningCssErrorCode,
}

impl LightningCssResult {
  fn ok(value: String) -> Self {
    Self {
      value: into_c_string(value),
      error: ptr::null_mut(),
      code: LightningCssErrorCode::None,
    }
  }

  fn err(failure: Failure) -> Self {
    Self {
      value: ptr::null_mut(),
      error: into_c_string(failure.message),
      code: failure.code,
    }
  }
}

pub struct Failure {
  code: LightningCssErrorCode,
  message: String,
}

impl Failure {
  fn parse(message: impl Into<String>) -> Self {
    Self {
      code: LightningCssErrorCode::Parse,
      message: message.into(),
    }
  }

  fn option(message: impl Into<String>) -> Self {
    Self {
      code: LightningCssErrorCode::Option,
      message: message.into(),
    }
  }

  fn bundle(message: impl Into<String>) -> Self {
    Self {
      code: LightningCssErrorCode::Bundle,
      message: message.into(),
    }
  }

  fn internal(message: impl Into<String>) -> Self {
    Self {
      code: LightningCssErrorCode::Internal,
      message: message.into(),
    }
  }
}

fn into_c_string(value: impl Into<Vec<u8>>) -> *mut c_char {
  CString::new(value).unwrap_or_default().into_raw()
}

unsafe fn borrow_str<'a>(pointer: *const c_char, label: &str) -> Result<&'a str, Failure> {
  if pointer.is_null() {
    return Err(Failure::internal(format!("{label} is null")));
  }

  CStr::from_ptr(pointer)
    .to_str()
    .map_err(|error| Failure::internal(format!("Invalid UTF-8 in {label}: {error}")))
}

unsafe fn borrow_options(pointer: *const c_char) -> Result<TransformOptions, Failure> {
  if pointer.is_null() {
    return Ok(TransformOptions::default());
  }

  let json = borrow_str(pointer, "options")?;

  if json.trim().is_empty() {
    return Ok(TransformOptions::default());
  }

  serde_json::from_str(json).map_err(|error| Failure::option(format!("Invalid options: {error}")))
}

fn transform_source(code: &str, options: &TransformOptions) -> Result<TransformResult, Failure> {
  let filename = options.filename.clone().unwrap_or_default();
  let css_modules = match &options.css_modules {
    Some(modules) => Some(modules.to_config().map_err(Failure::option)?),
    None => None,
  };

  let collected = Arc::new(RwLock::new(Vec::new()));

  let parser_options = ParserOptions {
    filename: filename.clone(),
    css_modules,
    error_recovery: options.error_recovery,
    warnings: Some(collected.clone()),
    ..ParserOptions::default()
  };

  let mut stylesheet = StyleSheet::parse(code, parser_options).map_err(|error| Failure::parse(error.to_string()))?;

  if let Some(fragment) = &options.scope {
    let mut scoper = Scoper::parse(fragment).map_err(Failure::option)?;

    stylesheet
      .visit(&mut scoper)
      .map_err(|error| Failure::internal(format!("Failed to scope stylesheet: {error:?}")))?;
  }

  let targets = options.to_targets();

  if options.minify {
    stylesheet
      .minify(MinifyOptions {
        targets,
        ..MinifyOptions::default()
      })
      .map_err(|error| Failure::internal(format!("Failed to minify: {error}")))?;
  }

  let printed = stylesheet
    .to_css(PrinterOptions {
      minify: options.minify,
      source_map: None,
      project_root: None,
      targets,
      analyze_dependencies: None,
      pseudo_classes: None,
    })
    .map_err(|error| Failure::internal(format!("Failed to print: {error}")))?;

  let exports = printed.exports.map(|exports| {
    exports
      .into_iter()
      .map(|(local, export)| (local, export.name))
      .collect::<HashMap<String, String>>()
  });

  let warnings = collected
    .read()
    .map(|warnings| warnings.iter().map(|warning| warning.to_string()).collect())
    .unwrap_or_default();

  Ok(TransformResult {
    code: printed.code,
    exports,
    warnings,
  })
}

fn bundle_source(path: &str, options: &TransformOptions) -> Result<TransformResult, Failure> {
  let css_modules = match &options.css_modules {
    Some(modules) => Some(modules.to_config().map_err(Failure::option)?),
    None => None,
  };

  let provider = FileProvider::new();
  let collected = Arc::new(RwLock::new(Vec::new()));

  let parser_options = ParserOptions {
    css_modules,
    error_recovery: options.error_recovery,
    warnings: Some(collected.clone()),
    ..ParserOptions::default()
  };

  let mut bundler = Bundler::new(&provider, None, parser_options);

  let mut stylesheet = bundler
    .bundle(std::path::Path::new(path))
    .map_err(|error| match &error.kind {
      BundleErrorKind::ParserError(_) => Failure::parse(error.to_string()),
      _ => Failure::bundle(error.to_string()),
    })?;

  if let Some(fragment) = &options.scope {
    let mut scoper = Scoper::parse(fragment).map_err(Failure::option)?;

    stylesheet
      .visit(&mut scoper)
      .map_err(|error| Failure::internal(format!("Failed to scope stylesheet: {error:?}")))?;
  }

  let targets = options.to_targets();

  if options.minify {
    stylesheet
      .minify(MinifyOptions {
        targets,
        ..MinifyOptions::default()
      })
      .map_err(|error| Failure::internal(format!("Failed to minify: {error}")))?;
  }

  let printed = stylesheet
    .to_css(PrinterOptions {
      minify: options.minify,
      targets,
      ..PrinterOptions::default()
    })
    .map_err(|error| Failure::internal(format!("Failed to print: {error}")))?;

  let exports = printed.exports.map(|exports| {
    exports
      .into_iter()
      .map(|(local, export)| (local, export.name))
      .collect::<HashMap<String, String>>()
  });

  let warnings = collected
    .read()
    .map(|warnings| warnings.iter().map(|warning| warning.to_string()).collect())
    .unwrap_or_default();

  Ok(TransformResult {
    code: printed.code,
    exports,
    warnings,
  })
}

fn transform_attribute(code: &str, options: &TransformOptions) -> Result<TransformResult, Failure> {
  let parser_options = ParserOptions {
    filename: options.filename.clone().unwrap_or_default(),
    error_recovery: options.error_recovery,
    ..ParserOptions::default()
  };

  let mut attribute = StyleAttribute::parse(code, parser_options).map_err(|error| Failure::parse(error.to_string()))?;

  let targets = options.to_targets();

  attribute.minify(MinifyOptions {
    targets,
    ..MinifyOptions::default()
  });

  let printed = attribute
    .to_css(PrinterOptions {
      minify: options.minify,
      targets,
      ..PrinterOptions::default()
    })
    .map_err(|error| Failure::internal(format!("Failed to print: {error}")))?;

  Ok(TransformResult {
    code: printed.code,
    exports: None,
    warnings: Vec::new(),
  })
}

fn to_result(outcome: Result<TransformResult, Failure>) -> LightningCssResult {
  match outcome {
    Ok(result) => match serde_json::to_string(&result) {
      Ok(json) => LightningCssResult::ok(json),
      Err(error) => LightningCssResult::err(Failure::internal(format!("Failed to serialize result: {error}"))),
    },
    Err(failure) => LightningCssResult::err(failure),
  }
}

#[no_mangle]
pub unsafe extern "C" fn lightningcss_transform(
  code: *const c_char,
  options_json: *const c_char,
) -> LightningCssResult {
  let code = match borrow_str(code, "code") {
    Ok(code) => code,
    Err(failure) => return LightningCssResult::err(failure),
  };

  let options = match borrow_options(options_json) {
    Ok(options) => options,
    Err(failure) => return LightningCssResult::err(failure),
  };

  to_result(transform_source(code, &options))
}

#[no_mangle]
pub unsafe extern "C" fn lightningcss_transform_style_attribute(
  code: *const c_char,
  options_json: *const c_char,
) -> LightningCssResult {
  let code = match borrow_str(code, "code") {
    Ok(code) => code,
    Err(failure) => return LightningCssResult::err(failure),
  };

  let options = match borrow_options(options_json) {
    Ok(options) => options,
    Err(failure) => return LightningCssResult::err(failure),
  };

  to_result(transform_attribute(code, &options))
}

#[no_mangle]
pub unsafe extern "C" fn lightningcss_bundle(path: *const c_char, options_json: *const c_char) -> LightningCssResult {
  let path = match borrow_str(path, "path") {
    Ok(path) => path,
    Err(failure) => return LightningCssResult::err(failure),
  };

  let options = match borrow_options(options_json) {
    Ok(options) => options,
    Err(failure) => return LightningCssResult::err(failure),
  };

  to_result(bundle_source(path, &options))
}

#[no_mangle]
pub unsafe extern "C" fn lightningcss_version() -> *mut c_char {
  into_c_string(VERSION)
}

#[no_mangle]
pub unsafe extern "C" fn lightningcss_lightningcss_version() -> *mut c_char {
  into_c_string(LIGHTNINGCSS_VERSION)
}

#[no_mangle]
pub unsafe extern "C" fn lightningcss_string_free(value: *mut c_char) {
  if !value.is_null() {
    drop(CString::from_raw(value));
  }
}

#[no_mangle]
pub unsafe extern "C" fn lightningcss_result_free(result: LightningCssResult) {
  lightningcss_string_free(result.value);
  lightningcss_string_free(result.error);
}
