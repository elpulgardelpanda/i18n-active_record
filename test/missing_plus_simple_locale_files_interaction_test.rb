require File.expand_path('../test_helper', __FILE__)

class I18nActiveRecordMissingTest < Test::Unit::TestCase
  class Backend < I18n::Backend::ActiveRecord
    include I18n::Backend::ActiveRecord::Missing
    include I18n::Backend::Memoize
  end

  def setup
    I18n.backend = I18n::Backend::Chain.new(Backend.new, I18n::Backend::Simple.new)
    I18n::Backend::ActiveRecord::Translation.delete_all
    I18n.backend.store_translations(:en, :bar => 'Bar', :i18n => { :plural => { :keys => [:zero, :one, :other] } })
  end

  test "missing_plus_simple: if translated in simple backend, then store that value in AR" do
    simple = I18n.backend.backends.last
    simple.store_translations(:en, :a_translation => 'I am translated')
    assert_equal 'I am translated', I18n.t(:a_translation)
    assert_equal 'I am translated', I18n::Backend::ActiveRecord::Translation.locale(:en).lookup(:a_translation).first.value
  end

  test "missing_plus_simple: if translated in simple backend with interpolation, then store that value in AR keeping interpolations" do
    simple = I18n.backend.backends.last
    simple.store_translations(:en, :a_translation => 'I am %{translated}')
    assert_equal 'I am done', I18n.t(:a_translation, translated: "done")
    assert_equal 'I am finished', I18n.t(:a_translation, translated: "finished")
    assert_equal 'I am %{translated}', I18n::Backend::ActiveRecord::Translation.locale(:en).lookup(:a_translation).first.value
  end

end if defined?(ActiveRecord)

