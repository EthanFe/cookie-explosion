require 'bundler'
Bundler.require

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/development.db')

require_rel '../app'
require_rel '../lib'

ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular "owned_cookie", "owned_cookies"
end
