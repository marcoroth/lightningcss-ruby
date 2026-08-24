use lightningcss_ffi::{
  lightningcss_result_free, lightningcss_transform, lightningcss_transform_style_attribute, LightningCssResult,
};

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

type Call = unsafe extern "C" fn(*const c_char, *const c_char) -> LightningCssResult;

fn answer(result: LightningCssResult) -> Result<String, String> {
  let outcome = if result.error.is_null() {
    Ok(unsafe { CStr::from_ptr(result.value) }.to_str().unwrap().to_string())
  } else {
    Err(unsafe { CStr::from_ptr(result.error) }.to_str().unwrap().to_string())
  };

  unsafe { lightningcss_result_free(result) };

  outcome
}

fn call(function: Call, code: &str, options: &str) -> Result<String, String> {
  let code = CString::new(code).unwrap();
  let options = CString::new(options).unwrap();

  answer(unsafe { function(code.as_ptr(), options.as_ptr()) })
}

#[test]
fn transform_answers_json_for_a_stylesheet_it_read() {
  let answer = call(lightningcss_transform, ".a { color: #ff0000 }", r#"{"minify":true}"#);

  assert_eq!(answer, Ok(r#"{"code":".a{color:red}","warnings":[]}"#.to_string()));
}

#[test]
fn transform_prints_what_it_was_given_when_it_was_not_asked_to_minify() {
  let answer = call(lightningcss_transform, ".a { color: red }", "{}");

  assert_eq!(
    answer,
    Ok(r#"{"code":".a {\n  color: red;\n}\n","warnings":[]}"#.to_string())
  );
}

#[test]
fn transform_reads_no_options_at_all_as_the_defaults() {
  let code = CString::new(".a { color: red }").unwrap();
  let answer = answer(unsafe { lightningcss_transform(code.as_ptr(), ptr::null()) });

  assert_eq!(
    answer,
    Ok(r#"{"code":".a {\n  color: red;\n}\n","warnings":[]}"#.to_string())
  );
}

#[test]
fn transform_answers_an_error_for_css_it_could_not_read() {
  let answer = call(lightningcss_transform, ". { color: red }", "{}");

  assert_eq!(
    answer,
    Err("Expected identifier in class selector, got WhiteSpace(\" \") at :0:2".to_string())
  );
}

#[test]
fn transform_refuses_an_option_it_does_not_read() {
  let answer = call(lightningcss_transform, ".a {}", r#"{"nonsense":true}"#);

  assert_eq!(
    answer,
    Err("Invalid options: unknown field `nonsense`, expected one of `filename`, `minify`, `error_recovery`, `targets`, `css_modules`, `scope` at line 1 column 11".to_string())
  );
}

#[test]
fn transform_refuses_a_null_stylesheet() {
  let options = CString::new("{}").unwrap();

  assert_eq!(
    answer(unsafe { lightningcss_transform(ptr::null(), options.as_ptr()) }),
    Err("code is null".to_string())
  );
}

#[test]
fn transform_refuses_a_stylesheet_that_is_not_utf8() {
  let code = CString::new(vec![0xff, 0xfe]).unwrap();
  let options = CString::new("{}").unwrap();

  assert_eq!(
    answer(unsafe { lightningcss_transform(code.as_ptr(), options.as_ptr()) }),
    Err("Invalid UTF-8 in code: invalid utf-8 sequence of 1 bytes from index 0".to_string())
  );
}

#[test]
fn a_style_attribute_is_a_declaration_list_without_a_selector_around_it() {
  let answer = call(
    lightningcss_transform_style_attribute,
    "color: #ff0000",
    r#"{"minify":true}"#,
  );

  assert_eq!(answer, Ok(r#"{"code":"color:red","warnings":[]}"#.to_string()));
}
