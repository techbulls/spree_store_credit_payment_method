source 'https://rubygems.org'

gem 'spree', '~> 2.2.6'
# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-2-stable'

gemspec

group :assets do
  gem 'coffee-rails'
  gem 'sass-rails'
end

group :test do
  gem 'with_model'
end

group :test, :development do
  gem 'pry-byebug'
end
