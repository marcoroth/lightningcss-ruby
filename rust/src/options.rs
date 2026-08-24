use std::collections::HashMap;

use lightningcss::css_modules::{Config as CssModulesConfig, Pattern};
use lightningcss::targets::{Browsers, Targets};
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct TransformOptions {
  pub filename: Option<String>,
  pub minify: bool,
  pub error_recovery: bool,
  pub targets: Option<HashMap<String, u32>>,
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

impl TransformOptions {
  pub fn to_targets(&self) -> Targets {
    let Some(versions) = &self.targets else {
      return Targets::default();
    };

    let mut browsers = Browsers::default();

    for (name, version) in versions {
      let encoded = Some(version << 16);

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

    Targets::from(browsers)
  }
}

#[derive(Debug, Serialize)]
pub struct TransformResult {
  pub code: String,
  #[serde(skip_serializing_if = "Option::is_none")]
  pub exports: Option<HashMap<String, String>>,
  pub warnings: Vec<String>,
}
