require File.expand_path('../test_helper', __FILE__)
class I18nBackendActiveRecordTest < Test::Unit::TestCase
  def setup
    I18n.backend = I18n::Backend::ActiveRecord.new
    I18n.backend.store_translations(:en, :foo => { :bar => 'bar', :baz => 'baz' })
  end

  def teardown
    I18n::Backend::ActiveRecord::Translation.destroy_all
    super
  end

  test "store_translations does not allow ambiguous keys (1)" do
    I18n::Backend::ActiveRecord::Translation.delete_all
    I18n.backend.store_translations(:en, :foo => 'foo')
    I18n.backend.store_translations(:en, :foo => { :bar => 'bar' })
    I18n.backend.store_translations(:en, :foo => { :baz => 'baz' })

    translations = I18n::Backend::ActiveRecord::Translation.locale(:en).lookup('foo').all
    assert_equal %w(bar baz), translations.map(&:value)

    assert_equal({ :bar => 'bar', :baz => 'baz' }, I18n.t(:foo))
  end

  test "store_translations does not allow ambiguous keys (2)" do
    I18n::Backend::ActiveRecord::Translation.delete_all
    I18n.backend.store_translations(:en, :foo => { :bar => 'bar' })
    I18n.backend.store_translations(:en, :foo => { :baz => 'baz' })
    I18n.backend.store_translations(:en, :foo => 'foo')

    translations = I18n::Backend::ActiveRecord::Translation.locale(:en).lookup('foo').all
    assert_equal %w(foo), translations.map(&:value)

    assert_equal 'foo', I18n.t(:foo)
  end

  test "can store translations with keys that are translations containing special chars" do
    I18n.backend.store_translations(:es, :"Pagina's" => "Pagina's" )
    assert_equal "Pagina's", I18n.t(:"Pagina's", :locale => :es)
  end

  test "stores translations in all languages if the instance for the language does not exist" do
    I18n::Backend::ActiveRecord::Translation.delete_all
    # add 2 translations in different locales so available_locales = 2
    I18n.backend.store_translations(:en, :foo => 'foo')
    I18n.backend.store_translations(:es, :lala => 'foo')

    I18n.backend.store_translations(:es, :hum => "la")
    assert_equal 2, I18n::Backend::ActiveRecord::Translation.where(key: :hum).count
  end

  def test_expand_keys
    assert_equal %w(foo foo.bar foo.bar.baz), I18n.backend.send(:expand_keys, :'foo.bar.baz')
  end

end if defined?(ActiveRecord)

