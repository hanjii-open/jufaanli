class Doc < ActiveRecord::Base
  NAME = '文书'
  ATTRS = {
    url: '原始链接',
    code: '案号',
    name: '案件名称',
    court: '法院',
    region: '所属地区',
    trial: '审理程序',
    trial_day: '裁判日期',
    publish_day: '公开日期',
    client: '当事人',
    cause: '案由',
    law: '法律依据',
    content: '全文'
  }.with_indifferent_access.freeze

  NUMS = '0123456789零○〇一二三四五六七八九十百千万\.\,'
  PUNS = '，。；：！？'
  DATES = '年个月日天'

  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :docs do |t|
        t.string :url, index: true
        t.string :code, index: true
        t.string :name, index: true
        t.string :court, index: true
        t.string :region, index: true
        t.string :trial, index: true
        t.string :trial_day, index: true
        t.string :publish_day, index: true
        t.string :client
        t.string :cause
        t.string :law
        t.text :content
      end
    end
  end

  has_many :crime1s, dependent: :destroy
  has_many :crime2s, dependent: :destroy
  has_many :crime3s, dependent: :destroy
  has_many :crime4s, dependent: :destroy
  has_many :crime5s, dependent: :destroy
  has_many :crime6s, dependent: :destroy

  scope :match, -> (*ss) { ss.flatten.reduce(self) { _1.where("content LIKE ?", "%#{_2}%") } }

  def self.crime_klasses
    [Crime1, Crime2, Crime3, Crime4, Crime5, Crime6]
  end

  def self.unzip dir = File.join('tmp', 'zip')
    tmp_filename = File.join('tmp', '_.csv')
    Dir.glob('*.zip', base: dir).each do |filename|
      Zip::File.open(File.join(dir, filename)) do |zip_file|
        puts "#{Time.current}... #{self.name} #{__method__} #{zip_file.name}"
        zip_file.each do |entry|
          next unless entry.name.end_with?('.csv')
          File.delete(tmp_filename) if File.exist?(tmp_filename)
          entry.extract(tmp_filename)
          Doc.transaction do
            CSV.foreach(tmp_filename, headers: true, encoding: 'bom|utf-8') do |row|
              next if row['案件类型'] != '刑事案件'
              url = row['原始链接'].presence
              name = row['案件名称'].presence
              code = row['案号'].presence || url || name
              trial_day = row['裁判日期'].presence
              # break if Doc.where("trial_day LIKE '%#{trial_day[0...7]}%'").exists?
              next if code && Doc.where(code:).exists?
              puts "#{Time.current}... #{self.name} #{__method__} #{trial_day} #{code}"
              Doc.create(
                url:,
                code:,
                name:,
                court: row['法院'].presence,
                region: row['所属地区'].presence,
                trial: row['审理程序'].presence,
                trial_day:,
                publish_day: row['公开日期'].presence,
                client: row['当事人'].presence,
                cause: row['案由'].presence,
                law: row['法律依据'].presence,
                content: row['全文'].presence
              )
            end
          end
        end
      end
    ensure
      File.delete(tmp_filename) if File.exist?(tmp_filename)
    end
  end

  def self.import
    unzip
  end

  def self.scrape
    crime_klasses.each do |klass|
      klass.scrape
    end
  end

  def self.export
    crime_klasses.each do |klass|
      puts "#{Time.current}... #{klass.name} #{__method__} #{klass.count}"
      CSV.open(File.join('tmp', "#{klass.model_name.singular}_#{klass::NAME}.csv"), 'w') do |csv|
        crime_attrs = klass.attribute_names - %w[id doc_id]
        doc_attrs = Doc.attribute_names - %w[id]
        csv << crime_attrs.map { klass::ATTRS[_1] } + doc_attrs.map { Doc::ATTRS[_1] }
        klass.includes(:doc).find_each do |crime|
          csv << crime.values_at(crime_attrs) + crime.doc.values_at(doc_attrs)
        end
      end
    end
  end
end
