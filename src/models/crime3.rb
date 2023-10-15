class Crime3 < ActiveRecord::Base
  NAME = '强奸罪'.freeze
  ATTRS = {
    d1: '强奸妇女的人数',
    d2: '强奸妇女的次数',
    d3: '奸淫幼女的人数',
    d4: '奸淫幼女的次数',
    d5: '是否在公共场所',
    d6: '是否轮奸',
    d7: '是否奸淫不满十周岁的幼女',
    d8: '是否造成幼女伤害',
    d9: '是否造成轻微伤',
    d10: '轻微伤人数',
    d11: '是否造成轻伤',
    d12: '轻伤人数',
    d13: '是否造成重伤',
    d14: '重伤人数',
    d15: '未遂',
    d16: '从犯',
    d17: '自首',
    d18: '坦白',
    d19: '当庭自愿认罪',
    d20: '赔偿金额',
    d20t: '赔偿金额*',
    d21: '谅解',
    d22: '刑事和解',
    d23: '羁押期间表现良好',
    d24: '认罪认罚',
    d25: '累犯',
    d26: '前科',
    d27: '是否死刑',
    d28: '是否无期徒刑',
    d29: '有期徒刑年数',
    d29t: '有期徒刑年数*',
    d30: '是否判处缓刑',
    d31: '缓刑长度',
    d31t: '缓刑长度*'
  }.with_indifferent_access.freeze

  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :crime3s do |t|
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
        {
          doc_id: doc.id,
          d1: 'TODO',
          d2: 'TODO',
          d3: 'TODO',
          d4: 'TODO',
          d5: /公共场所/.match?(conclusion),
          d6: /轮奸/.match?(line) && !/(不构成轮奸|不具有轮奸情节)/.match?(line),
          d7: /(不满十周岁|未满十周岁)/.match?(line),
          d8: /幼女[^#{Doc::PUNS}]*(轻微伤|轻伤|重伤)/.match?(line),
          d9: /轻微伤/.match?(line),
          d10: 'TODO',
          d11: /轻伤/.match?(line),
          d12: 'TODO',
          d13: /重伤/.match?(line),
          d14: 'TODO',
          d15: /未遂/.match?(conclusion),
          d16: /从犯/.match?(conclusion),
          d17: /自首/.match?(conclusion),
          d18: /坦白/.match?(conclusion),
          d19: /当庭自愿认罪/.match?(conclusion),
          d20: d20 = /赔偿金额[^#{Doc::PUNS}]*?(#{Doc::RMB_EXP})/.match(conclusion)&.[](1),
          d20t: Doc.translate_rmb(d20),
          d21: /谅解/.match?(conclusion),
          d22: /刑事和解/.match?(conclusion),
          d23: /羁押期间表现良好/.match?(conclusion),
          d24: /认罪认罚/.match?(conclusion),
          d25: /累犯/.match?(conclusion),
          d26: /前科/.match?(conclusion),
          d27: /死刑/.match?(conclusion),
          d28: /无期徒刑/.match?(conclusion),
          d29: d29 = /有期徒刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d29t: Doc.translate_date(d29),
          d30: d30 = /缓刑/.match?(conclusion),
          d31: d31 = d30.presence && /缓刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d31t: Doc.translate_date(d31)
        }
      end
      upsert_all(batch) if batch.any?
    end
    puts "#{Time.current}... #{self.name} #{__method__} #{count}"
  end
end
