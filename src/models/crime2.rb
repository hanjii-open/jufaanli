class Crime2 < ActiveRecord::Base
  NAME = '诈骗罪'.freeze
  ATTRS = {
    d1: '诈骗数额',
    d2: '是否数额较大',
    d3: '是否数额巨大',
    d4: '是否数额特别巨大',
    d5: '是否多次诈骗',
    d6: '诈骗手段是否恶劣',
    d7: '诈骗罪对象是否特殊',
    d8: '是否诈骗有特定用途的款物',
    d9: '是否造成严重后果',
    d10: '未遂',
    d11: '从犯',
    d12: '自首',
    d13: '坦白',
    d14: '当庭自愿认罪',
    d15: '退赃退赔',
    d16: '立功',
    d17: '积极赔偿',
    d18: '谅解',
    d19: '刑事和解',
    d20: '羁押期间表现良好',
    d21: '认罪认罚',
    d22: '累犯',
    d23: '前科',
    d24: '是否拘役',
    d25: '拘役时长',
    d26: '是否管制',
    d27: '管制时长',
    d28: '是否有期徒刑',
    d29: '有期徒刑刑期',
    d30: '是否无期徒刑',
    d31: '是否死刑',
    d32: '是否缓刑',
    d33: '缓刑刑期',
    d34: '是否判处罚金刑',
    d35: '罚金数额'
  }.with_indifferent_access.freeze

  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :crime2s do |t|
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
        sentences.each do |sentence|
          next if sentence.end_with?('的')
          d1s << $~[1] if /骗取[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+元)/ =~ sentence
        end
        {
          doc_id: doc.id,
          d1: d1s.presence && d1s.to_csv(row_sep: nil),
          d2: d2 = /数额较大/.match?(conclusion),
          d3: d3 = !d2 && /数额巨大/.match?(conclusion),
          d4: !d2 && !d3 && /数额特别巨大/.match?(conclusion),
          d5: /多次/.match?(line),
          d6: /(冒充国家机关工作人员|电信网络诈骗团伙|境外|募捐[^#{Doc::PUNS}]*名义|慈善[^#{Doc::PUNS}]*名义)/.match?(line),
          d7: /(残疾人|老年人|学生|丧失劳动力|患者|病人)/.match?(line),
          d8: /(救灾|抢险|防汛|优抚|扶贫|移民|救济|医疗)/.match?(line),
          d9: /(自杀|死亡|精神失常)/.match?(line),
          d10: /未遂/.match?(conclusion),
          d11: /从犯/.match?(conclusion),
          d12: /自首/.match?(conclusion),
          d13: /坦白/.match?(conclusion),
          d14: /当庭自愿认罪/.match?(conclusion),
          d15: /退赃退赔/.match?(conclusion),
          d16: /立功/.match?(conclusion),
          d17: /积极赔偿/.match?(conclusion),
          d18: /谅解/.match?(conclusion),
          d19: /刑事和解/.match?(conclusion),
          d20: /羁押期间表现良好/.match?(conclusion),
          d21: /认罪认罚/.match?(conclusion),
          d22: /累犯/.match?(conclusion),
          d23: /前科/.match?(conclusion),
          d24: d24 = /拘役/.match?(conclusion),
          d25: d24.presence && /拘役[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d26: d26 = /管制/.match?(conclusion),
          d27: d26.presence && /管制[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d28: d28 = /有期徒刑/.match?(conclusion),
          d29: d28.presence && /有期徒刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d30: /无期徒刑/.match?(conclusion),
          d31: /死刑/.match?(conclusion),
          d32: d32 = /缓刑/.match?(conclusion),
          d33: d32.presence && /缓刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d34: d34 = /罚金/.match?(conclusion),
          d35: d34.presence && /罚金[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+元)/.match(conclusion)&.[](1)
        }
      end
      upsert_all(batch) if batch.any?
    end
    puts "#{Time.current}... #{self.name} #{__method__} #{count}"
  end
end
