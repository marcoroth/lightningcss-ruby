use lightningcss_ffi::{lightningcss_bundle, lightningcss_result_free, LightningCssErrorCode};

use std::ffi::{CStr, CString};

const ENTRY: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../test/fixtures/bundle/entry.css");
const MISSING: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../test/fixtures/bundle/missing.css");
const BROKEN: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../test/fixtures/bundle/broken.css");

fn bundle(path: &str, options: &str) -> Result<String, String> {
  let path = CString::new(path).unwrap();
  let options = CString::new(options).unwrap();

  let result = unsafe { lightningcss_bundle(path.as_ptr(), options.as_ptr()) };

  let outcome = if result.error.is_null() {
    Ok(unsafe { CStr::from_ptr(result.value) }.to_str().unwrap().to_string())
  } else {
    Err(unsafe { CStr::from_ptr(result.error) }.to_str().unwrap().to_string())
  };

  unsafe { lightningcss_result_free(result) };

  outcome
}

#[test]
fn bundle_resolves_the_imports_a_stylesheet_was_written_with() {
  let answer = bundle(ENTRY, r#"{"minify":true}"#);

  assert_eq!(
    answer,
    Ok(r#"{"code":":root{--brand:red}.layout{display:grid}.entry{color:var(--brand)}","warnings":[]}"#.to_string())
  );
}

#[test]
fn bundle_narrows_everything_it_read_by_a_scope() {
  let answer = bundle(ENTRY, r#"{"minify":true,"scope":"[s]"}"#);

  assert_eq!(
    answer,
    Ok(
      r#"{"code":":root[s]{--brand:red}.layout[s]{display:grid}.entry[s]{color:var(--brand)}","warnings":[]}"#
        .to_string()
    )
  );
}

#[test]
fn bundle_answers_an_error_for_a_file_that_is_not_there() {
  assert_eq!(
    bundle(MISSING, "{}"),
    Err("No such file or directory (os error 2)".to_string())
  );
}

fn bundle_code(path: &str, options: &str) -> LightningCssErrorCode {
  let path = CString::new(path).unwrap();
  let options = CString::new(options).unwrap();

  let result = unsafe { lightningcss_bundle(path.as_ptr(), options.as_ptr()) };
  let answer = result.code;

  unsafe { lightningcss_result_free(result) };

  answer
}

#[test]
fn a_file_it_cannot_read_carries_the_bundle_code() {
  assert_eq!(bundle_code(MISSING, "{}"), LightningCssErrorCode::Bundle);
}

#[test]
fn css_it_cannot_parse_carries_the_parse_code_wherever_it_was_imported_from() {
  assert_eq!(bundle_code(BROKEN, "{}"), LightningCssErrorCode::Parse);
}
