class Doc < ActiveRecord::Base
  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :docs, if_not_exists: true do |t|
        t.string :url # 原始链接
        t.string :code, index: true # 案号
        t.string :name, index: true # 案件名称
        t.string :court # 法院
        t.string :region # 所属地区
        t.string :trial # 审理程序
        t.string :trial_day, index: true # 裁判日期
        t.string :publish_day # 公开日期
        t.string :client # 当事人
        t.string :cause # 案由
        t.string :law # 法律依据
        t.text :content # 全文
      end
    end
  end

  scope :match, -> (s) { where("content LIKE ?", "%#{s}%") }
  scope :match_crime1, -> { match('非法吸收公众存款罪') }
  scope :match_crime2, -> { match('诈骗罪') }
  scope :match_crime3, -> { match('强奸罪') }
  scope :match_crime4, -> { match('妨害公务罪') }
  scope :match_crime5, -> { match('醉酒型危险驾驶罪') }
  scope :match_crime6, -> { match('掩饰、隐瞒犯罪所得、犯罪所得收益罪') }

  def self.unzip dir = File.join('downloads', 'zip')
    require 'zip'
    require 'csv'
    tmp_filename = File.join('downloads', '_.csv')
    Dir.glob('*.zip', base: dir).each do |filename|
      Zip::File.open(File.join(dir, filename)) do |zip_file|
        puts "#{Time.current}... #{zip_file.name}"
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
              puts "#{Time.current}... #{trial_day} #{code}"
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

  def self.seed
    unzip
  end

  def self.etl
    Crime1.etl
  end
end
