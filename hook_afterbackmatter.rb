#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 全HTML変換後に索引をソートしてHTMLファイルを作成する
require_relative 'hook_afterbackmatter_common'

h = HookIndex.new
h.main(ARGV)

# XXX: ほかのhook_afterbackmatterを呼び出したいときにはこのあとにsystem()などを使って呼び出す
