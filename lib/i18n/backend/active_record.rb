require 'i18n/backend/base'
require 'i18n/backend/active_record/translation'

module I18n
  module Backend
    class ActiveRecord
      autoload :Missing,     'i18n/backend/active_record/missing'
      autoload :StoreProcs,  'i18n/backend/active_record/store_procs'
      autoload :Translation, 'i18n/backend/active_record/translation'

      module Implementation
        include Base, Flatten

        def available_locales
          begin
            Translation.available_locales
          rescue ::ActiveRecord::StatementInvalid
            []
          end
        end

        def store_translations(locale, data, options = {})
          escape = options.fetch(:escape, true)
          flatten_translations(locale, data, escape, false).each do |key, value|
            Translation.locale(locale).lookup(expand_keys(key)).delete_all
            Translation.create(:locale => locale.to_s, :key => key.to_s, :value => value)
          end
        end

        def translate(locale, key, options = {})
          raise InvalidLocale.new(locale) unless locale
          entry = key && lookup(locale, key, options[:scope], options)

          entry = resolve(locale, key, entry, options.except(:default))
          count = options[:count]
          values = options.except(*RESERVED_KEYS)

          throw(:exception, I18n::MissingTranslation.new(locale, key, options)) if entry.nil?

          entry = entry.dup if entry.is_a?(String)

          entry = pluralize(locale, entry, count) if count
          entry = interpolate(locale, entry, values) if values
          entry
        end

      protected

        def lookup(locale, key, scope = [], options = {})
          key = normalize_flat_keys(locale, key, scope, options[:separator])
          result = Translation.locale(locale).lookup(key)

          if result.empty?
            nil
          elsif result.first.key == key
            if options[:default] and result.first.value == options[:default]
              return default(locale, key, result.first.value)
            else
              return result.first.value
            end
          else
            chop_range = (key.size + FLATTEN_SEPARATOR.size)..-1
            result = result.inject({}) do |hash, r|
              hash[r.key.slice(chop_range)] = r.value
              hash
            end
            result.deep_symbolize_keys
          end
        end

        # For a key :'foo.bar.baz' return ['foo', 'foo.bar', 'foo.bar.baz']
        def expand_keys(key)
          key.to_s.split(FLATTEN_SEPARATOR).inject([]) do |keys, the_key|
            keys << [keys.last, the_key].compact.join(FLATTEN_SEPARATOR)
          end
        end
      end

      include Implementation
    end
  end
end

