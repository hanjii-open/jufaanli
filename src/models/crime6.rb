class Crime6 < ActiveRecord::Base
  NAME = '掩饰、隐瞒犯罪所得、犯罪所得收益罪'.freeze
  ATTRS = {
    d1: '是否掩饰行为',
    d2: '是否隐瞒行为',
    d3: '行为对象是否犯罪所得',
    d4: '行为对象是否犯罪所得收益',
    d5: '掩饰、隐瞒犯罪所得、犯罪所得收益的价值总额',
    d6: '掩饰、隐瞒犯罪所得、犯罪所得收益的次数',
    d7: '掩饰、隐瞒的犯罪所得是否特殊',
    d8: '是否严重妨害司法机关对上游犯罪追究',
    d9: '退赃退赔',
    d10: '未遂',
    d11: '从犯',
    d12: '自首',
    d13: '坦白',
    d14: '当庭自愿认罪',
    d15: '积极赔偿',
    d16: '谅解',
    d17: '刑事和解',
    d18: '羁押期间表现良好',
    d19: '认罪认罚',
    d20: '累犯',
    d21: '前科',
    d22: '上游犯罪种类',
    d23: '是否拘役',
    d24: '拘役月数',
    d24t: '拘役月数*',
    d25: '是否判处缓刑',
    d26: '缓刑长度',
    d26t: '缓刑长度*',
    d27: '是否判处罚金',
    d28: '罚金数额',
    d28t: '罚金数额*',
    d29: '是否管制',
    d30: '管制月数',
    d30t: '管制月数*',
    d31: '是否有期徒刑',
    d32: '有期徒刑刑期',
    d32t: '有期徒刑刑期*'
  }.with_indifferent_access.freeze

  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :crime6s do |t|
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
        committing = $~[0] if /[^#{Doc::PUNS} ]被告人[^#{Doc::PUNS} ]*犯[^#{Doc::PUNS} ]*罪[^#{Doc::PUNS} ]/.match(line)
        {
          doc_id: doc.id,
          d1: /掩饰/.match?(committing),
          d2: /隐瞒/.match?(committing),
          d3: /犯罪所得/.match?(committing),
          d4: /犯罪所得收益/.match?(committing),
          d5: 'TODO',
          d6: 'TODO',
          d7: /(电力设备|交通设施|广播电视设施|公用电信设施|军事设施|救灾|抢险|防汛|优抚|扶贫|移民|救济款物)/.match?(line),
          d8: /严重妨害司法机关/.match?(line),
          d9: /积极退赃/.match?(line),
          d10: /未遂/.match?(conclusion),
          d11: /从犯/.match?(conclusion),
          d12: /自首/.match?(conclusion),
          d13: /坦白/.match?(conclusion),
          d14: /当庭自愿认罪/.match?(conclusion),
          d15: /积极赔偿/.match?(conclusion),
          d16: /谅解/.match?(conclusion),
          d17: /刑事和解/.match?(conclusion),
          d18: /羁押期间表现良好/.match?(conclusion),
          d19: /认罪认罚/.match?(conclusion),
          d20: /累犯/.match?(conclusion),
          d21: /前科/.match?(conclusion),
          d22: /(被盗|盗窃|偷窃)/.match?(line) ? '盗窃罪' : /诈骗/.match?(line) ? '诈骗罪' : /受贿/.match?(line) ? '受贿罪' : /贪污/.match?(line) ? '贪污罪' : /抢劫/.match?(line) ? '抢劫罪' : /抢夺/.match?(line) ? '抢夺罪' : /明知([^#{Doc::PUNS}]+罪)/.match(line)&.[](1),
          d23: d23 = /拘役/.match?(conclusion),
          d24: d24 = d23.presence && /拘役[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d24t: Doc.translate_date(d24),
          d25: d25 = /缓刑/.match?(conclusion),
          d26: d26 = d25.presence && /缓刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d26t: Doc.translate_date(d26),
          d27: d27 = /罚金/.match?(conclusion),
          d28: d28 = d27.presence && /罚金[^#{Doc::PUNS}]*?(#{Doc::RMB_EXP})/.match(conclusion)&.[](1),
          d28t: Doc.translate_rmb(d28),
          d29: d29 = /管制/.match?(conclusion),
          d30: d30 = d29.presence && /管制[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d30t: Doc.translate_date(d30),
          d31: d31 = /有期徒刑/.match?(conclusion),
          d32: d32 = d31.presence && /有期徒刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d32t: Doc.translate_date(d32)
        }
      end
      upsert_all(batch) if batch.any?
    end
    puts "#{Time.current}... #{self.name} #{__method__} #{count}"
  end
end
