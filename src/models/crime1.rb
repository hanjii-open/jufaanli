class Crime1 < ActiveRecord::Base
  class Migration < ActiveRecord::Migration[7.0]
    def change
      create_table :crime1s, if_not_exists: true do |t|
        t.references :doc, null: false, foreign_key: true
        t.string :d1 # 吸收公众存款的数额
        t.boolean :d2 # 是否数额巨大
        t.boolean :d3 # 是否数额特别巨大
        t.string :d4 # 吸收公众存款对象的人数（这个变量在裁判文书中大多不显示，不然不提了）
        t.string :d5 # 给集资参与人造成直接经济损失的数额
        t.string :d6 # 吸收存款的方式（房产销售、林权、种植、养殖、商品回购、发行股票、债券、投资入股、保险等等）→这个似乎比较难实现？
        t.string :d7 # 退赃退赔情况：
        t.boolean :d8 # 是否从犯
        t.boolean :d9 # 是否自首（本院认为之后，出现“自首”，则为“是”，否则为“否”）
        t.boolean :d10 # 是否坦白（本院认为之后，出现“坦白”，则为“是”，否则为“否”）
        t.boolean :d11 # 是否当庭自愿认罪（本院认为之后，出现“自愿认罪”，则为“是”，否则为“否”）
        t.boolean :d12 # 是否积极赔偿
        t.boolean :d13 # 是否获得谅解 （本院认为之后，出现“谅解”，则为“是”，否则为“否”）
        t.boolean :d14 # 是否刑事和解（本院认为之后，出现“和解”，则为“是”，否则为“否”）
        t.boolean :d15 # 是否羁押期间表现良好（本院认为之后，出现“羁押期间表现良好”，则为“是”，否则为“否”）
        t.boolean :d16 # 是否认罪认罚（本院认为之后，出现“认罪认罚”，则为“是”，否则为“否”）
        t.boolean :d17 # 是否累犯（本院认为之后，出现“累犯”，则为“是”，否则为“否”）
        t.boolean :d18 # 是否有前科（本院认为之后，出现“前科”，则为“是”，否则为“否”）
        t.string :d19 # 有期徒刑年数
        t.string :d20 # 罚金数额
        t.boolean :d21 # 是否判处缓刑
        t.string :d22 # 缓刑长度
        t.string :d23 # 法院所处省份
        t.string :d24 # 判决时间
        t.boolean :d25 # 主观恶性大小（本院认为之后，出现“主观恶性大”，则为“大”，否则为“小”）
        t.boolean :d26 # 人身危险性大小（本院认为之后，出现“人身危险性大”，则为“大”，否则为“小”）
      end
    end
  end

  def self.etl
    delete_all
    Doc.match_crime1.find_in_batches do |batch|
      transaction do
        batch.each do |doc|
          content_line = doc.content.gsub(/[\r\n]+/, '  ')
          sentences = content_line.split(/[，。；：]\s*/)
          d1s = []
          d5s = []
          d7s = []
          sentences.each do |sentence|
            d1s << sentence if /(吸收|募集).+元/ =~ sentence
            d5s << sentence if /损失.+元/ =~ sentence
            case
            when /赔偿.*部分损失/ =~ sentence then d7s << '部分赔偿'
            when /赔偿.*全部损失/ =~ sentence then d7s << '全部赔偿'
            when /尚未赔偿.*全部损失/ =~ sentence then d7s << '部分赔偿'
            end
          end
          conclusion = $~[1] if /本院认为(.+)/ =~ content_line
          puts "#{Time.current}... #{doc.trial_day} #{doc.code}"
          create(
            doc_id: doc.id,
            d1: d1s.join(','),
            d2: d2 = /数额巨大/.match?(conclusion),
            d3: !d2 && /数额特别巨大/.match?(conclusion),
            d4: nil,
            d5: d5s.join(','),
            d6: nil,
            d7: d7s.any? ? d7s.join(',') : '未赔偿',
            d8: /从犯/.match?(conclusion),
            d9: /自首/.match?(conclusion),
            d10: /坦白/.match?(conclusion),
            d11: /自愿认罪/.match?(conclusion),
            d12: nil,
            d13: /谅解/.match?(conclusion),
            d14: /和解/.match?(conclusion),
            d15: /羁押期间表现良好/.match?(conclusion),
            d16: /认罪认罚/.match?(conclusion),
            d17: /累犯/.match?(conclusion),
            d18: /前科/.match?(conclusion),
            d19: /判处有期徒刑.+?[年月]/.match(conclusion)&.[](0),
            d20: /并处罚金.+?元/.match(conclusion)&.[](0),
            d21: /缓刑/.match?(conclusion),
            d22: /缓刑.+?[年月]/.match(conclusion)&.[](0),
            d23: doc.region || nil,
            d24: doc.trial_day || /审 *判 *员.+([#{t = '0123456789零○〇一二三四五六七八九'}]年[#{t}]月[#{t}]日)/.match(content_line)&.[](1),
            d25: /主观恶性大/.match?(conclusion),
            d26: /人身危险性大/.match?(conclusion),
          )
        end
      end
    end
    puts "#{Time.current}... #{name} #{count}"
  end
end
