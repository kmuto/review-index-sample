#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 全HTML変換後に索引をソートしてHTMLファイルを作成する
require 'yaml'
require 'cgi'

class HookIndex
  def initialize
    # 利用css
    @stylesheet = ['style.css']
    # リンクマーク
    @linkmark = '□'
    # mecab利用
    @makeindex_mecab = true
    # 辞書ファイル
    @makeindex_dic = nil
    # mecabオプション
    @makeindex_mecab_opts = '-Oyomi'
    # upmendexオプション
    @makeindex_options = "-f -r -s #{__dir__}/mendex_html.ist"

    @metachars = {
        '{' => '\{',
        '}' => '\}',
        '\\' => '◆backslash◆'
      }
    @metachars_re = /[#{Regexp.escape(@metachars.keys.join(''))}]/u
    @metachars_invert = @metachars.invert
  end

  def setup_index
    @index_db = {}
    @index_mecab = nil
    if @makeindex_dic
      @index_db = load_idxdb(File.join(__dir__, @makeindex_dic))
    end

    return true unless @makeindex_mecab

    begin
      begin
        require 'MeCab'
      rescue LoadError
        require 'mecab'
      end
      require 'nkf'
      @index_mecab = MeCab::Tagger.new(@makeindex_mecab_opts)
    rescue LoadError
      warn 'not found MeCab'
    end
  end

  def load_idxdb(file)
    table = {}
    File.foreach(file) do |line|
      key, value = *line.strip.split(/\t+/, 2)
      table[key] = value
    end
    table
  end

  def escape(str)
      str.gsub(@metachars_re) { |s| @metachars[s] or raise "unknown trans char: #{s}" }
  end

  def escape_index(str)
    str.gsub(/[@!|"]/) { |s| '"' + s }
  end

  def escape_mendex_key(str)
    str.gsub('"|', '｜').tr('{', '\{').tr('}', '\}')
  end

  def escape_mendex_display(str)
    str.gsub('\\{', '◆｛◆').gsub('\\}', '◆｝◆')
  end

  def modify_label(str)
    sa = str.split('<<>>')
    sa.map! do |item|
      item = item.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&amp;', '&').gsub('&#45;', '-')
      if @index_db[item]
        escape_mendex_key(escape_index(@index_db[item])) + '@' + escape_mendex_display(escape_index(escape(item)))
      else
        if item =~ /\A[[:ascii:]]+\Z/ || @index_mecab.nil?
          esc_item = escape_mendex_display(escape_index(escape(item)))
            if esc_item == item
              esc_item
            else
              "#{escape_mendex_key(escape_index(item))}@#{esc_item}"
            end
        else
          yomi = NKF.nkf('-w --hiragana', @index_mecab.parse(item).force_encoding('UTF-8').chomp)
          escape_mendex_key(escape_index(yomi)) + '@' + escape_mendex_display(escape_index(escape(item)))
        end
      end
    end
    sa.join('!')
  end

  def main
    return true unless File.exist?(File.join(__dir__, '_RVIDX_index_raw.txt'))
    setup_index
    File.open(File.join(__dir__, '_RVIDX_index_raw.txt')) do |fi|
      File.open(File.join(ARGV[0], '_RVIDX_index.tex'), 'w') do |fw|
        fi.each_line do |l|
          label, nmbl = l.chomp.split("\t")
          fw.puts "\\indexentry{#{modify_label(label)}}{#{nmbl}}"
        end
      end
    end
    # _RVIDX_index.indは中間ファイルなのでARGV[0]内で完結させてもいいのだが、確認したいときも多そうなので作業フォルダに書き出すようにしておく
    Dir.chdir(__dir__) do
      system("upmendex #{@makeindex_options} #{File.join(ARGV[0], '_RVIDX_index.tex')} -o _RVIDX_index.ind")
    end
    if File.exist?(File.join(__dir__, '_RVIDX_index.ind'))
      write_index_html(File.join(__dir__, '_RVIDX_index.ind'))
      add_index_to_toc_file
    else
      raise '索引作成に失敗 (おそらく辞書読み失敗)'
    end
  end

  def write_index_html(srcind)
    File.open(File.join(ARGV[0], '_rv_index.xhtml'), 'w') do |fw|
      fw.puts <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xmlns:ops="http://www.idpf.org/2007/ops" xml:lang="ja">
<head>
  <meta charset="UTF-8" />
EOT

      @stylesheet.each do |sty|
fw.puts <<EOT
  <link rel="stylesheet" type="text/css" href="#{sty}" />
EOT
      end

      fw.puts <<EOT
  <meta name="generator" content="Re:VIEW" />
  <title>索引</title>
</head>
<body>
<div class="rv_index">
<h1>索引</h1>
EOT

      parse_ind(srcind, fw)

      fw.puts <<EOT
</div>
</body>
</html>
EOT
    end
  end

  def parse_ind(srcind, fw)
    # indを解析して書き出し。レベル解析が怪しめ
    idx = 0
    File.open(srcind) do |fi|
      fi.each_line do |l|
        l = l.chomp.gsub('◆｛◆', '{').gsub('◆｝◆', '}').gsub('◆backslash◆', '\\')
        case l
        when /■H■(.+)/ # 見出し
          label = $1
          if idx > 0
            1.upto(idx).each { fw.puts '</li></ul>' }
            idx = 0
          end
          l = "<h2>#{CGI.escape_html(label)}</h2>"
        when /■L1■(.+)/ # レベル1索引
          labelp = $1
          if idx == 0
            fw.puts '<ul>'
          elsif idx > 1
            2.upto(idx).each { fw.puts '</li></ul>' }
            idx = 1
          end
          if idx > 0
            fw.puts '</li>'
          end
          idx = 1
          l = make_line(labelp)
        when /■L2■(.+)/ # レベル2索引
          labelp = $1
          if idx == 1
            fw.puts '<ul>'
          elsif idx > 2
            3.upto(idx).each { fw.puts '</li></ul>' }
            idx = 2
          end
          if idx > 1
            fw.puts '</li>'
          end
          idx = 2
          l = make_line(labelp)
        when /■L3■(.+)/ # レベル3索引
          labelp = $1
          if idx == 2
            fw.puts '<ul>'
          end
          if idx > 2
            fw.puts '</li>'
          end
          idx = 3
          l = make_line(labelp)
        end
        fw.puts l
      end
    end

    if idx > 0
      1.upto(idx).each { fw.puts '</li></ul>' }
    end
  end

  def make_line(labelp)
    label, nmbls = labelp.split("\t", 2)
    nmbl_array = nmbls.split(/, /).map do |nmbl|
      # XXX:†前に索引カウンタが入っているので、ただ消さずに何かリンクマークと連携させる方法を考えられるかもしれない
      %Q(<span class="rv_index_nmbl"><a href="#{nmbl.sub(/.+†/, '')}">#{@linkmark}</a></span>)
    end
    l = %Q(<li><span class="rv_index_label">#{CGI.escape_html(label)}</span><span class="rv_index_delimiter">...</span>#{nmbl_array.join('<span class="rv_index_nmbl_delimiter">, </span>')})
  end

  def add_index_to_toc_file
    File.open(File.join(ARGV[0], 'toc-html.txt'), 'a') do |f|
      f.puts %Q(1\t_rv_index.xhtml\t索引\tchaptype=post)
    end
  end
end

h = HookIndex.new
h.main

# XXX: ほかのhook_afterbackmatterを呼び出したいときにはこのあとにsystem()などを使って呼び出す
