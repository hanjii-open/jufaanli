class Crime5 < ActiveRecord::Base
  NAME_PARTS = %w[醉酒 危险驾驶罪].freeze
  NAME = '醉酒型危险驾驶罪'.freeze
  ATTRS = {
    d1: '血液中酒精浓度',
    d2: '机动车的类型',
    d3: '事故责任程度',
    d4: '是否逃逸',
    d5: '是否在高速公路或城市快速路上驾驶',
    d6: '是否营运车辆',
    d7: '是否造成死亡',
    d8: '是否抗拒执法',
    d9: '是否造成重伤 ',
    d10: '重伤人数',
    d11: '是否造成财产损失',
    d12: '造成财产损失严重程度',
    d13: '是否造成轻伤 ',
    d14: '轻伤人数',
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
    d25: '是否判处缓刑',
    d26: '缓刑长度',
    d27: '是否判处罚金',
    d28: '罚金数额'
  }.with_indifferent_access.freeze

  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :crime5s do |t|
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
    Doc.match(NAME_PARTS).find_in_batches do |doc_batch|
      batch = doc_batch.map do |doc|
        line = doc.content.gsub(/[\r\n]+/, '  ')
        conclusion = $~[1] if /本院认为(.+)/ =~ line
        {
          doc_id: doc.id,
          d1: /含量[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+(?i:mg) *\/ *100 *(?i:ml))/.match(conclusion)&.[](1),
          d2: /(摩托车|电动车)/.match(line)&.[](1) || '汽车',
          d3: /负事故(全部责任|主要责任)/.match(line)&.[](1) || '其他',
          d4: /逃逸/.match?(conclusion),
          d5: /(高速公路|快速路)/.match?(line),
          d6: /(运营|营运)/.match?(line),
          d7: /(死亡)/.match?(line),
          d8: /(抗拒执法)/.match?(line),
          d9: /(重伤)/.match?(line),
          d10: /重伤[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+)/.match(line)&.[](1),
          d11: /(财物损失|财产损失)/.match?(line),
          d12: nil,
          d13: /(轻伤)/.match?(line),
          d14: /轻伤[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+)/.match(line)&.[](1),
          d15: /自首/.match?(conclusion),
          d16: /坦白/.match?(conclusion),
          d17: /当庭自愿认罪/.match?(conclusion),
          d18: /积极赔偿/.match?(conclusion),
          d19: /羁押期间表现良好/.match?(conclusion),
          d20: /认罪认罚/.match?(conclusion),
          d21: /累犯/.match?(conclusion),
          d22: /前科/.match?(conclusion),
          d23: d23 = /拘役/.match?(conclusion),
          d24: d23.presence && /拘役[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d25: d25 = /缓刑/.match?(conclusion),
          d26: d25.presence && /缓刑[^#{Doc::PUNS}]*?([#{Doc::NUMS}#{Doc::DATES} ]+)/.match(conclusion)&.[](1),
          d27: d27 = /罚金/.match?(conclusion),
          d28: d27.presence && /罚金[^#{Doc::PUNS}]*?([#{Doc::NUMS} ]+元)/.match(conclusion)&.[](1)
        }
      end
      upsert_all(batch) if batch.any?
    end
    puts "#{Time.current}... #{self.name} #{__method__} #{count}"
  end
end
