class Crime4 < ActiveRecord::Base
  NAME = '妨害公务罪'.freeze
  ATTRS = {
    d1: '妨害公务次数',
    d2: '是否致人轻伤',
    d3: '轻伤人数',
    d3t: '轻伤人数*',
    d4: '是否致人轻微伤',
    d5: '轻微伤人数',
    d5t: '轻微伤人数*',
    d6: '是否使用暴力手段',
    d7: '是否使用威胁手段',
    d8: '是否造成财物毁损',
    d9: '造成财物损失的数额',
    d9t: '造成财物损失的数额*',
    d10: '是否袭警',
    d11: '是否煽动群众阻碍依法执行职务、履行职责',
    d12: '是否持械',
    d13: '是否烧毁警用、公务车辆',
    d14: '执行公务是否规范',
    d15: '自首',
    d16: '坦白',
    d17: '当庭自愿认罪',
    d18: '积极赔偿',
    d19: '羁押期间表现良好',
    d20: '认罪认罚',
    d21: '累犯',
    d22: '前科',
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
      create_table :crime4s do |t|
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
          d2: d2 = /轻伤/.match?(line),
          d3: d3 = d2 ? /致([#{Doc::NUMS} ]+?)人轻伤/.match(conclusion)&.[](1) || 1 : 0,
          d3t: Doc.translate_rmb(d3),
          d4: d4 = /轻微伤/.match?(line),
          d5: d5 = d4 ? /致([#{Doc::NUMS} ]+?)人轻微伤/.match(conclusion)&.[](1) || 1 : 0,
          d5t: Doc.translate_rmb(d5),
          d6: /暴力/.match?(conclusion),
          d7: /威胁/.match?(conclusion),
          d8: /财物毁损/.match?(conclusion),
          d9: d9 = /财物毁损[^#{Doc::PUNS}]*?(#{Doc::RMB_EXP})/.match(conclusion)&.[](1),
          d9t: Doc.translate_rmb(d9),
          d10: /袭警/.match?(conclusion),
          d11: /煽动群众/.match?(conclusion),
          d12: /持械/.match?(conclusion),
          d13: 'TODO',
          d14: /#{d14a = '执行公务不规范'}/.match?(line) ? /#{d14a}[^#{Doc::PUNS}]*[#{Doc::PUNS}]?[^#{Doc::PUNS}]*#{d14b = '不予采纳'}/.match?(line) || /#{d14b}[^#{Doc::PUNS}]*#{d14a}/.match?(line) || /#{d14a}.{0,150}#{d14b}/.match?(line) : true,
          d15: /自首/.match?(conclusion),
          d16: /坦白/.match?(conclusion),
          d17: /当庭自愿认罪/.match?(conclusion),
          d18: /积极赔偿/.match?(conclusion),
          d19: /羁押期间表现良好/.match?(conclusion),
          d20: /认罪认罚/.match?(conclusion),
          d21: /累犯/.match?(conclusion),
          d22: /前科/.match?(conclusion),
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
