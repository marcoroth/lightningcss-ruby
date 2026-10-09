use lightningcss_ffi::{lightningcss_parse, lightningcss_result_free, LightningCssErrorCode, LightningCssResult};

use std::ffi::{CStr, CString};

fn parse(code: &str, options: &str) -> LightningCssResult {
  let code = CString::new(code).unwrap();
  let options = CString::new(options).unwrap();

  unsafe { lightningcss_parse(code.as_ptr(), options.as_ptr()) }
}

fn answer(code: &str, options: &str) -> Result<serde_json::Value, String> {
  let result = parse(code, options);

  let outcome = if result.error.is_null() {
    let json = unsafe { CStr::from_ptr(result.value) }.to_str().unwrap();

    Ok(serde_json::from_str(json).unwrap())
  } else {
    Err(unsafe { CStr::from_ptr(result.error) }.to_str().unwrap().to_string())
  };

  unsafe { lightningcss_result_free(result) };

  outcome
}

#[test]
fn answers_the_stylesheet_as_lightning_css_serializes_it() {
  let parsed = answer(".a { color: red }", "{}").unwrap();

  assert_eq!(parsed["stylesheet"]["rules"][0]["type"], "style");
  assert_eq!(
    parsed["stylesheet"]["rules"][0]["value"]["declarations"]["declarations"][0]["property"],
    "color"
  );
  assert_eq!(parsed["warnings"], serde_json::json!([]));
}

#[test]
fn names_the_file_it_read() {
  let parsed = answer(".a {}", r#"{"filename":"a.css"}"#).unwrap();

  assert_eq!(parsed["stylesheet"]["sources"], serde_json::json!(["a.css"]));
}

#[test]
fn collects_warnings() {
  let parsed = answer(".a:deep(.b) {}", "{}").unwrap();

  assert_eq!(parsed["warnings"].as_array().unwrap().len(), 1);
}

#[test]
fn a_stylesheet_it_cannot_read_carries_the_parse_code() {
  let result = parse(". {}", "{}");
  let code = result.code;

  unsafe { lightningcss_result_free(result) };

  assert_eq!(code, LightningCssErrorCode::Parse);
}
