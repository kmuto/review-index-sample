# -*- coding: utf-8 -*-
module ReVIEW
  module Book
    class Base
      attr_accessor :indices
    end
  end

  module HTMLBuilderOverride
    def builder_init_file
      super
      # 索引カウンタが初期化されていなければ初期化
      @book.indices ||= []
    end

    def idxlabel(str)
      label = escape_comment(escape(str))
      no = sprintf('%04d', @book.indices.size)
      # 登場順でソートしやすいように頭にも通しナンバーを入れ、切り分け記号†を付けておく
      @book.indices.push([label, "#{no}†#{@chapter.name}.#{@book.config['htmlext']}#_RVIDX_#{no}"])
      %Q(<span id="_RVIDX_#{no}" class="rv_index_target"></span>)
    end

    def inline_idx(str)
      %Q(#{idxlabel(str)}#{escape(str)})
    end

    def inline_hidx(str)
      idxlabel(str)
    end

    def result
      # 無駄めだが最後のコンテンツまで繰り返し上書きすることで最終的なすべての索引を入手できる
      File.open('_RVIDX_index_raw.txt', 'w') do |f|
        @book.indices.each do |pair|
          pair[0].gsub!('&lt;&lt;&gt;&gt;', '<<>>') # 子索引
          f.puts "#{pair[0]}\t#{pair[1]}"
        end
      end
      super
    end
  end

  class HTMLBuilder
    prepend HTMLBuilderOverride
  end
end
