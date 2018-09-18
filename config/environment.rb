require 'bundler'
Bundler.require

db_config = YAML.load_file('config/database.yml')
ActiveRecord::Base.establish_connection(db_config['development'])
# ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'kloivier')
# conn = PG.connect( dbname: 'sales' )
require_rel '../app'
require_rel '../lib'

ActiveSupport::Inflector.inflections do |inflect|
    inflect.irregular "owned_cookie", "owned_cookies"
end
