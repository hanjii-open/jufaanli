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
    d9: '轻微伤人数',
    d10: '轻伤人数',
    d11: '重伤人数',
    d12: '未遂',
    d13: '从犯',
    d14: '自首',
    d15: '坦白',
    d16: '当庭自愿认罪',
    d17: '赔偿金额',
    d18: '谅解',
    d19: '刑事和解',
    d20: '羁押期间表现良好',
    d21: '认罪认罚',
    d22: '累犯',
    d23: '前科',
    d24: '是否死刑',
    d25: '是否无期徒刑',
    d26: '有期徒刑年数',
    d27: '是否判处缓刑',
    d28: '缓刑长度'
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
        conclusion = $~[1] if /本院认为(.+)/ =~ line
        {
          doc_id: doc.id,
          d1: nil,
          d2: nil,
          d3: nil,
          d4: nil,
          d5: /公共场所/.match?(conclusion),
          d6: /轮奸/.match?(line) && !/(不构成轮奸|不具有轮奸情节)/.match?(line),
          d7: /(不满十周岁|未满十周岁)/.match?(line),
          d8: /幼女[^#{Doc::PUNS}]*(轻伤|轻微伤|重伤)/.match?(line),
          d9: nil,
          d10: nil,
          d11: nil,
          d12: /未遂/.match?(conclusion),
          d13: /从犯/.match?(conclusion),
          d14: /自首/.match?(conclusion),
          d15: /坦白/.match?(conclusion),
          d16: /当庭自愿认罪/.match?(conclusion),
          d17: /赔偿金额[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+元)/.match(conclusion)&.[](1),
          d18: /谅解/.match?(conclusion),
          d19: /刑事和解/.match?(conclusion),
          d20: /羁押期间表现良好/.match?(conclusion),
          d21: /认罪认罚/.match?(conclusion),
          d22: /累犯/.match?(conclusion),
          d23: /前科/.match?(conclusion),
          d24: /死刑/.match?(conclusion),
          d25: /无期徒刑/.match?(conclusion),
          d26: /有期徒刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d27: d27 = /缓刑/.match?(conclusion),
          d28: d27.presence && /缓刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1)
        }
      end
      upsert_all(batch) if batch.any?
    end
    puts "#{Time.current}... #{self.name} #{__method__} #{count}"
  end
end
