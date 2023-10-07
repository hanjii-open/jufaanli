def init reset = false
  require 'zip'
  require 'csv'
  require 'active_record'

  database = 'tmp/database.sqlite3'
  File.delete(database) if reset && File.exist?(database)
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database:)

  Dir.glob(File.join('src', 'models', '*.rb')).each do |path|
    load path
  end

  Doc::Migration.migrate(:up) unless Doc.table_exists?
  Crime1::Migration.migrate(:up) unless Crime1.table_exists?
  Crime2::Migration.migrate(:up) unless Crime2.table_exists?
end

init(ARGV.include?('reset'))

Doc.import if ARGV.include?('all') || ARGV.include?('import')
Doc.scrape if ARGV.include?('all') || ARGV.include?('scrape')
Doc.export if ARGV.include?('all') || ARGV.include?('export')
