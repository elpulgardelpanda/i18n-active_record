#  This extension stores translation stub records for missing translations to
#  the database.
#
#  This is useful if you have a web based translation tool. It will populate
#  the database with untranslated keys as the application is being used. A
#  translator can then go through these and add missing translations.
#
#  Example usage:
#
#     I18n::Backend::Chain.send(:include, I18n::Backend::ActiveRecord::Missing)
#     I18n.backend = I18n::Backend::Chain.new(I18n::Backend::ActiveRecord.new, I18n::Backend::Simple.new)
#
#  Stub records for pluralizations will also be created for each key defined
#  in i18n.plural.keys.
#
#  For example:
#
#    # en.yml
#    en:
#      i18n:
#        plural:
#          keys: [:zero, :one, :other]
#
#    # pl.yml
#    pl:
#      i18n:
#        plural:
#          keys: [:zero, :one, :few, :other]
#
#  It will also persist interpolation keys in Translation#interpolations so
#  translators will be able to review and use them.
module I18n
  module Backend
    class ActiveRecord
      module Missing
        include Flatten

        def store_default_translations(locale, key, options = {})
          count, scope, default_value, separator = options.values_at(:count, :scope, :default, :separator)
          separator ||= I18n.default_separator
          key = normalize_flat_keys(locale, key, scope, separator)

          unless ActiveRecord::Translation.locale(locale).lookup(key).exists?
            interpolations = options.keys - I18n::RESERVED_KEYS
            keys = count ? I18n.t('i18n.plural.keys', :locale => locale).map { |k| [key, k].join(FLATTEN_SEPARATOR) } : [key]
            keys.each { |the_key| store_default_translation(locale, the_key, interpolations, default_value) }
          end
        end

        def store_default_translation(locale, key, interpolations, default_value)
          translation = ActiveRecord::Translation.new :locale => locale.to_s, :key => key, :value => default_value
          translation.interpolations = interpolations
          translation.save
          I18n.backend.reload! #invalidate cache
        end

        module ::I18n
          module Backend
            class Chain
              module Implementation

                # This is the entry point to make the translation.
                # We need to override this method to store missing translations:
                # 1st backend is AR, if it misses then we want to store the translation
                # as missed, but if there is a default value or it is translated in other
                # backend, we want to store that value, instead of nil.
                def translate(locale, key, default_options = {})
                  namespace = nil
                  options = default_options
                  final_translation = nil
                  should_store_in_db = false

                  backends.each do |backend|
                    catched_value = catch(:exception) do
                      if backend == backends.last
                        # for the last backend, but back the default value if it exists
                        options = default_options
                      end
                      translation = backend.translate(locale, key, options)
                      if namespace_lookup?(translation, options)
                        namespace = translation.merge(namespace || {})
                      elsif !translation.nil?
                        if options[:default].present?
                          final_translation = default(locale, key, translation, options)
                        else
                          final_translation = translation
                        end
                        break
                      end
                    end
                    if catched_value.class == MissingTranslation
                      should_store_in_db = true
                    end
                    if final_translation != nil
                      break
                    end
                  end

                  if final_translation.nil?
                    final_translation = namespace
                  end

                  if should_store_in_db and !key.to_s.include?("i18n.plural.rule")
                    default_options[:default] ||= I18n.backend.backends.last.send(:lookup, locale, key)
                    I18n.backend.backends.first.store_default_translations(locale, key, default_options)
                  end

                  throw(:exception, I18n::MissingTranslation.new(locale, key, options)) if final_translation.nil?

                  final_translation = final_translation.dup if final_translation.is_a?(String)

                  final_translation = pluralize(locale, final_translation, options[:count]) if options[:count]

                  values = options.except(*RESERVED_KEYS)
                  final_translation = interpolate(locale, final_translation, values) if values

                  final_translation
                end

              end
            end
          end
        end


      end
    end
  end
end

