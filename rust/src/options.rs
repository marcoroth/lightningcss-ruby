use std::collections::HashMap;

use lightningcss::css_modules::{Config as CssModulesConfig, Pattern};
use lightningcss::error::Error;
use lightningcss::targets::{Browsers, Targets};
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct TransformOptions {
  pub filename: Option<String>,
  pub minify: bool,
  pub error_recovery: bool,
  pub targets: Option<HashMap<String, Version>>,
  pub css_modules: Option<CssModulesOptions>,
  pub scope: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct CssModulesOptions {
  pub pattern: Option<String>,
  pub dashed_idents: bool,
  pub animation: bool,
  pub grid: bool,
  pub container: bool,
  pub custom_idents: bool,
  pub pure: bool,
}

impl Default for CssModulesOptions {
  fn default() -> Self {
    Self {
      pattern: None,
      dashed_idents: false,
      animation: true,
      grid: true,
      container: true,
      custom_idents: true,
      pure: false,
    }
  }
}

impl CssModulesOptions {
  pub fn to_config(&self) -> Result<CssModulesConfig, String> {
    let pattern = match &self.pattern {
      Some(pattern) => Pattern::parse(pattern).map_err(|_| format!("Invalid CSS modules pattern {pattern:?}"))?,
      None => Pattern::default(),
    };

    Ok(CssModulesConfig {
      pattern,
      dashed_idents: self.dashed_idents,
      animation: self.animation,
      grid: self.grid,
      container: self.container,
      custom_idents: self.custom_idents,
      pure: self.pure,
    })
  }
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum Version {
  Major(u32),
  Float(f64),
  String(String),
}

impl Version {
  /// Encodes a version the way Lightning CSS reads it, as `major << 16 | minor << 8 | patch`.
  fn encode(&self) -> Option<u32> {
    match self {
      Version::Major(major) => (*major <= 0xffff).then(|| major << 16),
      Version::Float(float) => Self::parse(&float.to_string()),
      Version::String(string) => Self::parse(string),
    }
  }

  fn parse(version: &str) -> Option<u32> {
    let mut parts = version.trim().split('.');

    let major: u16 = parts.next()?.parse().ok()?;
    let minor: u8 = parts.next().map_or(Some(0), |part| part.parse().ok())?;
    let patch: u8 = parts.next().map_or(Some(0), |part| part.parse().ok())?;

    if parts.next().is_some() {
      return None;
    }

    Some(u32::from(major) << 16 | u32::from(minor) << 8 | u32::from(patch))
  }

  fn describe(&self) -> String {
    match self {
      Version::Major(major) => major.to_string(),
      Version::Float(float) => float.to_string(),
      Version::String(string) => format!("{string:?}"),
    }
  }
}

impl TransformOptions {
  pub fn to_targets(&self) -> Result<Targets, String> {
    let Some(versions) = &self.targets else {
      return Ok(Targets::default());
    };

    let mut browsers = Browsers::default();

    for (name, version) in versions {
      let encoded = Some(
        version
          .encode()
          .ok_or_else(|| format!("Invalid version {} for {name} in targets", version.describe()))?,
      );

      match name.as_str() {
        "android" => browsers.android = encoded,
        "chrome" => browsers.chrome = encoded,
        "edge" => browsers.edge = encoded,
        "firefox" => browsers.firefox = encoded,
        "ie" => browsers.ie = encoded,
        "ios_saf" | "ios" => browsers.ios_saf = encoded,
        "opera" => browsers.opera = encoded,
        "safari" => browsers.safari = encoded,
        "samsung" => browsers.samsung = encoded,
        _ => {}
      }
    }

    Ok(Targets::from(browsers))
  }
}

#[derive(Debug, Serialize)]
pub struct ParseResult<T> {
  pub stylesheet: T,
  pub warnings: Vec<Diagnostic>,
}

#[derive(Debug, Serialize)]
pub struct TransformResult {
  pub code: String,
  #[serde(skip_serializing_if = "Option::is_none")]
  pub exports: Option<HashMap<String, String>>,
  pub warnings: Vec<Diagnostic>,
}

#[derive(Debug, Serialize)]
pub struct Diagnostic {
  pub message: String,
  #[serde(rename = "type", skip_serializing_if = "Option::is_none")]
  pub kind: Option<String>,
  #[serde(skip_serializing_if = "Option::is_none")]
  pub location: Option<Location>,
}

#[derive(Debug, Serialize)]
pub struct Location {
  pub filename: Option<String>,
  pub line: u32,
  pub column: u32,
}

impl Diagnostic {
  pub fn from_error<T: std::fmt::Display + Serialize>(error: &Error<T>) -> Self {
    Self {
      message: error.kind.to_string(),
      kind: serde_json::to_value(&error.kind).ok().as_ref().and_then(type_of),
      location: error.loc.as_ref().map(|location| Location {
        filename: (!location.filename.is_empty()).then(|| location.filename.clone()),
        line: location.line + 1,
        column: location.column.saturating_sub(1),
      }),
    }
  }
}

impl From<String> for Diagnostic {
  fn from(message: String) -> Self {
    Self {
      message,
      kind: None,
      location: None,
    }
  }
}

impl From<&str> for Diagnostic {
  fn from(message: &str) -> Self {
    Self::from(message.to_string())
  }
}

fn type_of(value: &serde_json::Value) -> Option<String> {
  match value {
    serde_json::Value::String(name) => Some(name.clone()),
    serde_json::Value::Object(fields) => match fields.get("type") {
      Some(serde_json::Value::String(name)) => Some(name.clone()),
      _ if fields.len() == 1 => fields.iter().next().map(|(name, inner)| match inner.get("type") {
        Some(serde_json::Value::String(inner_name)) => inner_name.clone(),
        _ => name.clone(),
      }),
      _ => None,
    },
    _ => None,
  }
}
