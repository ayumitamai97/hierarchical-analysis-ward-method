# frozen_string_literal: true

require 'natto'

class MorphAnalysis
  MECAB_DIC_DIRPATH = '/usr/local/lib/mecab/dic/mecab-ipadic-neologd'

  attr_reader :nm, :text

  def initialize(text:)
    @nm = Natto::MeCab.new(dicdir: MECAB_DIC_DIRPATH, output_formatt_type: :chasen)
    @text = text
  end

  def execute
    nodes = []
    nm.parse(text) do |morph|
      next if morph.stat == 3 # 3 means 'sentence end'

      features = morph.feature.split(',')
      next if %w[記号 助詞 助動詞].include?(features[0])
      next if %w[固有名詞].include?(features[1])

      nodes << features[-3]
    end
    nodes.delete_if { |t| t == '*' }
  end
end
