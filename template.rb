require 'bundler'

# .gitignore
ignore_setting = run('gibo OSX Ruby Rails SASS', capture: true)
append_file '.gitignore', ignore_setting

# Ruby Version
ruby_version =
  run('ruby -v', capture: true).scan(/\d\.\d\.\d/).flatten.first
run "echo '#{ruby_version}' > ./.ruby-version"
insert_into_file('Gemfile',
                 "\nruby '#{ruby_version}'",
                 after: "source 'https://rubygems.org'")

# add to Gemfile
append_file 'Gemfile', <<-RUBY

gem 'bootstrap-sass'
gem 'font-awesome-rails'
gem 'hamlit'
gem 'record_tag_helper'
gem 'simple_form'

group :development do
  gem 'bootstrap-generators'
  gem 'erb2haml'
  gem 'hamlit-rails'
end

group :test do
  gem 'database_rewinder'
  gem 'faker'
end

group :development, :test do
  gem 'factory_girl_rails'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails'
end

RUBY

Bundler.with_clean_env do
  run 'bundle install --path vendor/bundle --jobs=4 --without production'
end

application  do
  %q{
    # Set timezone
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

    I18n.enforce_available_locales = true
    config.i18n.load_path +=
      Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja

    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
      g.test_framework :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.view_specs false
      g.controller_specs true
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
  }
end

# set Japanese locale
get 'https://raw.githubusercontent.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml',
    'config/locales/ja.yml'

# edit view template
Bundler.with_clean_env do
  run 'bundle exec rails haml:replace_erbs'
  run 'bundle exec rails g bootstrap:install -f'
  run 'bundle exec rails g simple_form:install --bootstrap -f'
end

# Rspec
# ----------------------------------------------------------------
Bundler.with_clean_env do
  run 'bundle exec rails g rspec:install'
end

run "echo '--color -f d' > .rspec"

insert_into_file 'spec/rails_helper.rb', %(
  config.order = 'random'

  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end

  config.before :all do
    FactoryGirl.reload
    FactoryGirl.factories.clear
    FactoryGirl.sequences.clear
    FactoryGirl.find_definitions
  end

  config.include FactoryGirl::Syntax::Methods

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end
), after: 'RSpec.configure do |config|'

insert_into_file('spec/rails_helper.rb',
                 "\nrequire 'factory_girl_rails'",
                 after: "require 'rspec/rails'")
run 'rm -rf test'

# Git: Initialize
# ==================================================
git :init
git add: '.'
git commit: "-a -m 'Initial commit'"
