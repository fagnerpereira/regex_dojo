# frozen_string_literal: true

module RegexDojo
  module Views
    # Locale access for Phlex components, which live outside hanami-view and
    # its helper mixins. Delegates to the app's registered i18n provider, so
    # the thread-local locale set by actions applies here automatically.
    module Translatable
      private

      def t(key, **opts)
        Hanami.app["i18n"].t(key, **opts)
      end

      def t!(key, **opts)
        Hanami.app["i18n"].t!(key, **opts)
      end

      def l(value, **opts)
        Hanami.app["i18n"].l(value, **opts)
      end
    end
  end
end
