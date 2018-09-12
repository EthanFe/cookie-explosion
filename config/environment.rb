require 'bundler'
Bundler.require

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/development.db')
require_all 'lib'
require_all 'app'

ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular "owned_cookie", "owned_cookies"
end