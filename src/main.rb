def init_db
  require 'active_record'
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/database.sqlite3')

  Dir.glob(File.join('src', 'models', '*.rb')).each do |path|
    load path
  end
  Doc::Migration.migrate(:up)
  Crime1::Migration.migrate(:up)
end

init_db

Doc.seed if ARGV.include?('all') && ARGV.include?('seed')
Doc.etl if ARGV.include?('all') && ARGV.include?('etl')
