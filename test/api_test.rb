require File.expand_path('../test_helper', __FILE__)

class I18nActiveRecordApiTest < Test::Unit::TestCase
  class I18n::Backend::ActiveRecord
    include I18n::Backend::ActiveRecord::Missing
    include I18n::Backend::Memoize
  end

  def setup
    I18n.backend = I18n::Backend::Chain.new(I18n::Backend::ActiveRecord.new, I18n::Backend::Simple.new)
    I18n::Backend::ActiveRecord::Translation.send(:include, I18n::Backend::ActiveRecord::StoreProcs)
    I18n::Backend::ActiveRecord::Translation.delete_all
    I18n.backend.store_translations(:en, :bar => 'Bar', :i18n => { :plural => { :keys => [:zero, :one, :other] } })
    super
  end

  def self.can_store_procs?
    I18n::Backend::ActiveRecord::Translation.respond_to?(:bl)
  end

  include I18n::Tests::Basics
  include I18n::Tests::Defaults
  include I18n::Tests::Interpolation
  include I18n::Tests::Link
  include I18n::Tests::Lookup
  include I18n::Tests::Pluralization
  include I18n::Tests::Procs if can_store_procs?

  include I18n::Tests::Localization::Date
  include I18n::Tests::Localization::DateTime
  include I18n::Tests::Localization::Time
  include I18n::Tests::Localization::Procs if can_store_procs?

end if defined?(ActiveRecord)

