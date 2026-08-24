use lightningcss_ffi::{
  lightningcss_lightningcss_version, lightningcss_string_free, lightningcss_version, LIGHTNINGCSS_VERSION, VERSION,
};

use std::ffi::CStr;

fn take(value: *mut std::os::raw::c_char) -> String {
  let taken = unsafe { CStr::from_ptr(value) }.to_str().unwrap().to_string();

  unsafe { lightningcss_string_free(value) };

  taken
}

#[test]
fn the_crate_reports_the_version_it_was_built_from() {
  assert_eq!(take(unsafe { lightningcss_version() }), VERSION);
}

#[test]
fn the_crate_reports_the_lightningcss_version_it_was_built_against() {
  assert_eq!(
    take(unsafe { lightningcss_lightningcss_version() }),
    LIGHTNINGCSS_VERSION
  );
}

#[test]
fn the_version_it_reports_is_the_one_cargo_lock_pins() {
  let lock = include_str!("../Cargo.lock");
  let marker = "name = \"lightningcss\"\nversion = \"";
  let start = lock.find(marker).unwrap() + marker.len();
  let end = lock[start..].find('"').unwrap() + start;

  assert_eq!(LIGHTNINGCSS_VERSION, &lock[start..end]);
}
