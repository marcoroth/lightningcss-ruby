//! Confining a stylesheet's selectors to a scope.
//!
//! The scope is given as a selector fragment, which is appended to what each rule already matches.
//! `parcel_selectors` stores a selector in reverse match order, so `Selector::append` lands the
//! fragment in the last compound and before any pseudo-element, which is where a scope belongs:
//!
//!     .card .title    ->  .card .title[data-herb-scope-abc]
//!     .item::before   ->  .item[data-herb-scope-abc]::before
//!
//! A fragment is anything that parses as one compound selector, so an attribute and a `:where()`
//! carrying its own alternatives are both expressible.

use std::convert::Infallible;

use lightningcss::selector::{Component, Selector, SelectorList};
use lightningcss::stylesheet::ParserOptions;
use lightningcss::traits::ParseWithOptions;
use lightningcss::visit_types;
use lightningcss::visitor::{VisitTypes, Visitor};

pub struct Scoper<'i> {
  components: Vec<Component<'i>>,
}

impl<'i> Scoper<'i> {
  pub fn parse(fragment: &'i str) -> Result<Self, String> {
    let list = SelectorList::parse_string_with_options(fragment, ParserOptions::default()).map_err(|error| {
      format!(
        "Invalid scope selector {fragment:?} at :{}:{}",
        error.location.line, error.location.column
      )
    })?;

    let selector = list
      .0
      .first()
      .ok_or_else(|| format!("Scope selector {fragment:?} is empty"))?;

    if list.0.len() > 1 {
      return Err(format!("Scope selector {fragment:?} has to be a single selector"));
    }

    Ok(Self {
      components: selector.iter_raw_match_order().cloned().collect(),
    })
  }
}

impl<'i> Visitor<'i> for Scoper<'i> {
  type Error = Infallible;

  fn visit_types(&self) -> VisitTypes {
    visit_types!(SELECTORS)
  }

  fn visit_selector(&mut self, selector: &mut Selector<'i>) -> Result<(), Self::Error> {
    for component in &self.components {
      selector.append(component.clone());
    }

    Ok(())
  }
}
