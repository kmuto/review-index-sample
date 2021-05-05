#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 全HTML変換後に索引をソートしてHTMLファイルを作成する (Web版)
require_relative 'hook_afterbackmatter_common'
require 'fileutils'

h = HookIndex.new
h.main(['.'], nil)
File.open('webroot/indices.html') do |fi|
  File.open('webroot/indices.html-n', 'w') do |fw|
    fi.each_line do |l|
      if l =~ /◆REPLACE◆/
        fw.print File.read('_rv_index.xhtml')
        next
      end
      fw.print l
    end
  end
end
FileUtils.mv('webroot/indices.html-n', 'webroot/indices.html')
