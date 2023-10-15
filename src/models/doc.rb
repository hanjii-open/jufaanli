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

  NUMS = '0123456789○〇零一二三四五六七八九十百千万亿\.,'
  RMB_EXP = "[123456789一二三四五六七八九十][#{NUMS} ]*元"
  NUM_VALS = {
    '0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6, '7' => 7, '8' => 8, '9' => 9,
    '零' => 0, '一' => 1, '二' => 2, '三' => 3, '四' => 4, '五' => 5, '六' => 6, '七' => 7, '八' => 8, '九' => 9,
    '○' => 0, '〇' => 0,
  }

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

  scope :match, -> (*ss) do
    relation = where(trial: '一审')
    ss.flatten.reduce(relation) do
      _1.where("content LIKE ?", "%#{_2}%")
    end
  end

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
              # puts "#{Time.current}... #{self.name} #{__method__} #{trial_day} #{code}"
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

  def self.translate_num s
    weight = wan = 1
    acc = 0
    (arr = s.split('').reverse).each.with_index do |c, i|
      case
      when NUM_VALS.key?(c)
        acc += NUM_VALS[c] * weight
      when c == '十'
        weight = wan * 10
        acc += weight if NUM_VALS.keys.exclude?(arr[i + 1])
      when c == '百'
        weight = wan * 100
      when c == '千'
        weight = wan * 1000
      when c == '万'
        weight = wan = (wan > 10000 ? wan * 10000 : 10000)
      when c == '亿'
        weight = wan = (wan > 100000000 ? wan * 100000000 : 100000000)
      end
    end
    acc
  end

  def self.translate_rmb s
    return nil if !s
    return s if s.is_a?(Numeric)
    s = s.gsub(/[ ,元]/, '')
    return (s.include?('.') ? s.to_f : s.to_i) * ($~[1] ? 10000 : 1) if /^[\d\.]+(万)?$/.match(s)
    translate_num(s)
  end

  def self.translate_date s
    return nil if !s
    s.gsub(/ /, '').scan(/[#{NUMS}]+[#{DATES}]+/).map do |s|
      case s
      when /([#{NUMS}]+)年/ then translate_num($~[1]) * 360
      when /([#{NUMS}]+)个?月/ then translate_num($~[1]) * 30
      when /([#{NUMS}]+)(日|天)/ then translate_num($~[1])
      else 0
      end
    end.sum
  end

  def short_trial_day
    trial_day.presence && trial_day.gsub('-', '')
  end
end
