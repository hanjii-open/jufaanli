class Crime1 < ActiveRecord::Base
  NAME = '非法吸收公众存款罪'.freeze
  ATTRS = {
    d1: '吸收公众存款的数额',
    d2: '是否数额巨大',
    d3: '是否数额特别巨大',
    d4: '吸收公众存款对象的人数',
    d5: '给集资参与人造成直接经济损失的数额',
    d6: '吸收存款的方式',
    d7: '退赃退赔情况',
    d8: '是否从犯',
    d9: '是否自首',
    d10: '是否坦白',
    d11: '是否当庭自愿认罪',
    d12: '是否积极赔偿',
    d13: '是否获得谅解',
    d14: '是否刑事和解',
    d15: '是否羁押期间表现良好',
    d16: '是否认罪认罚',
    d17: '是否累犯',
    d18: '是否有前科',
    d19: '有期徒刑年数',
    d20: '罚金数额',
    d21: '是否判处缓刑',
    d22: '缓刑长度',
    d23: '法院所处省份',
    d24: '判决时间',
    d25: '主观恶性大小',
    d26: '人身危险性大小'
  }.with_indifferent_access.freeze

  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :crime1s do |t|
        t.references :doc, null: false, foreign_key: true
        ATTRS.each do |name, _|
          t.string name
        end
      end
    end
  end

  belongs_to :doc

  def self.scrape
    delete_all
    Doc.match(NAME).find_in_batches do |doc_batch|
      batch = doc_batch.map do |doc|
        line = doc.content.gsub(/[\r\n]+/, '  ')
        conclusion = $~[1] if /本院认为(.+)/.match(line)
        sentences = line.split(/[#{Doc::PUNS}]\s*/)
        d1s = []
        d5s = []
        d7s = []
        sentences.each do |sentence|
          next if sentence.end_with?('的')
          d1s << $~[2] if /(吸收|募集)[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+元)/.match(sentence)
          d5s << $~[1] if /损失[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+元)/.match(sentence)
          case
          when /赔偿.*部分损失/.match?(sentence) then d7s << '部分赔偿'
          when /赔偿.*全部损失/.match?(sentence) then d7s << '全部赔偿'
          when /尚未赔偿.*全部损失/.match?(sentence) then d7s << '部分赔偿'
          end
        end
        {
          doc_id: doc.id,
          d1: d1s.presence && d1s.to_csv(row_sep: nil),
          d2: d2 = /数额巨大/.match?(conclusion),
          d3: !d2 && /数额特别巨大/.match?(conclusion),
          d4: 'TODO',
          d5: d5s.presence && d5s.to_csv(row_sep: nil),
          d6: 'TODO',
          d7: d7s.any? ? d7s.to_csv(row_sep: nil) : '未赔偿',
          d8: /从犯/.match?(conclusion),
          d9: /自首/.match?(conclusion),
          d10: /坦白/.match?(conclusion),
          d11: /自愿认罪/.match?(conclusion),
          d12: 'TODO',
          d13: /谅解/.match?(conclusion),
          d14: /和解/.match?(conclusion),
          d15: /羁押期间表现良好/.match?(conclusion),
          d16: /认罪认罚/.match?(conclusion),
          d17: /累犯/.match?(conclusion),
          d18: /前科/.match?(conclusion),
          d19: /有期徒刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d20: /罚金[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+元)/.match(conclusion)&.[](1),
          d21: d21 = /缓刑/.match?(conclusion),
          d22: d21.presence && /缓刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d23: doc.region,
          d24: doc.short_trial_day, # /审 *判 *员.+([#{Doc::NUMS}]年[#{Doc::NUMS}]月[#{Doc::NUMS}]日)/.match(line)&.[](1),
          d25: /主观恶性大/.match?(conclusion),
          d26: /人身危险性大/.match?(conclusion)
        }
      end
      upsert_all(batch) if batch.any?
    end
    puts "#{Time.current}... #{self.name} #{__method__} #{count}"
  end
end
