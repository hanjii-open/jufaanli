def init reset = false
  require 'zip'
  require 'csv'
  require 'active_record'

  database = 'tmp/database.sqlite3'
  File.delete(database) if reset == :all && File.exist?(database)
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database:)
  # ActiveRecord::Base.logger = ActiveSupport::Logger.new(File.join('tmp', 'main.log'))
  # https://www.devdungeon.com/content/ruby-activerecord-without-rails-tutorial

  Dir.glob(File.join('src', 'models', '*.rb')).each do |path|
    load path
  end

  Doc::Migration.migrate(:up) unless Doc.table_exists?
  Doc.crime_klasses.each do |klass|
    klass::Migration.migrate(:down) if klass.table_exists? && reset
    klass::Migration.migrate(:up) unless klass.table_exists?
  end
end

init(ARGV.include?('reset!') ? :all : ARGV.include?('reset'))

Doc.import if ARGV.include?('all') || ARGV.include?('import')
Doc.scrape if ARGV.include?('all') || ARGV.include?('scrape')
Doc.export if ARGV.include?('all') || ARGV.include?('export')
