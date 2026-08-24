# frozen_string_literal: true

module LightningCSS
  module Backend
    module Unavailable
      #: (String, String) -> String
      def transform(_code, _options_json)
        unavailable(__method__)
      end

      #: (String, String) -> String
      def transform_style_attribute(_code, _options_json)
        unavailable(__method__)
      end

      #: (String, String) -> String
      def bundle(_path, _options_json)
        unavailable(__method__)
      end

      #: () -> String
      def version
        unavailable(__method__)
      end

      private

      #: (Symbol?) -> bot
      def unavailable(name)
        raise NotImplementedError, "LightningCSS::Backend.#{name} is defined by the native extension, which did not load"
      end
    end

    extend Unavailable
  end
end
