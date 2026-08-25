#include <ruby.h>
#include <ruby/encoding.h>
#include "include/lightningcss.h"

static VALUE rb_mLightningCSS;
static VALUE rb_mBackend;
static VALUE rb_eError;
static VALUE rb_eParseError;
static VALUE rb_eOptionError;
static VALUE rb_eBundleError;

static VALUE make_utf8_string(const char *cstring) {
  return rb_enc_str_new_cstr(cstring, rb_utf8_encoding());
}

static VALUE take_utf8_string(char *cstring) {
  if (!cstring) return Qnil;

  VALUE string = make_utf8_string(cstring);
  lightningcss_string_free(cstring);

  return string;
}

static VALUE error_class_for(enum LightningCssErrorCode code) {
  switch (code) {
    case LIGHTNING_CSS_ERROR_CODE_PARSE: return rb_eParseError;
    case LIGHTNING_CSS_ERROR_CODE_OPTION: return rb_eOptionError;
    case LIGHTNING_CSS_ERROR_CODE_BUNDLE: return rb_eBundleError;
    default: return rb_eError;
  }
}

static VALUE unwrap(struct LightningCssResult result) {
  if (result.error) {
    VALUE message = make_utf8_string(result.error);
    VALUE error_class = error_class_for(result.code);

    lightningcss_result_free(result);

    rb_raise(error_class, "%s", StringValueCStr(message));
  }

  if (!result.value) {
    lightningcss_result_free(result);

    rb_raise(rb_eError, "Lightning CSS returned no result");
  }

  VALUE value = make_utf8_string(result.value);

  lightningcss_result_free(result);

  return value;
}

static VALUE rb_transform(VALUE self, VALUE code, VALUE options) {
  (void) self;

  return unwrap(lightningcss_transform(StringValueCStr(code), StringValueCStr(options)));
}

static VALUE rb_transform_style_attribute(VALUE self, VALUE code, VALUE options) {
  (void) self;

  return unwrap(lightningcss_transform_style_attribute(StringValueCStr(code), StringValueCStr(options)));
}

static VALUE rb_bundle(VALUE self, VALUE path, VALUE options) {
  (void) self;

  return unwrap(lightningcss_bundle(StringValueCStr(path), StringValueCStr(options)));
}

static VALUE rb_native_version(VALUE self) {
  (void) self;

  return take_utf8_string(lightningcss_version());
}

static VALUE rb_lightningcss_version(VALUE self) {
  (void) self;

  return take_utf8_string(lightningcss_lightningcss_version());
}

void Init_lightningcss(void) {
  rb_mLightningCSS = rb_define_module("LightningCSS");
  rb_mBackend = rb_define_module_under(rb_mLightningCSS, "Backend");

  rb_eError = rb_define_class_under(rb_mLightningCSS, "Error", rb_eStandardError);
  rb_eParseError = rb_define_class_under(rb_mLightningCSS, "ParseError", rb_eError);
  rb_eOptionError = rb_define_class_under(rb_mLightningCSS, "OptionError", rb_eError);
  rb_eBundleError = rb_define_class_under(rb_mLightningCSS, "BundleError", rb_eError);

  rb_define_singleton_method(rb_mBackend, "transform", rb_transform, 2);
  rb_define_singleton_method(rb_mBackend, "transform_style_attribute", rb_transform_style_attribute, 2);
  rb_define_singleton_method(rb_mBackend, "bundle", rb_bundle, 2);
  rb_define_singleton_method(rb_mBackend, "version", rb_native_version, 0);
  rb_define_singleton_method(rb_mBackend, "lightningcss_version", rb_lightningcss_version, 0);
}
