# Re:VIEWでEPUB索引をなんとかしてみるサンプル

索引のソートに TeXLive 内の upmendex、および読みに MeCab を利用しているため、これが動くようになっていること (vvakame/review Docker などを使うのがよい)。

- **config.yml** : hook_afterbackmatter で hook_afterbackmatter.rb を呼び出すようにしている
- **hook_afterbackmatter.rb** : EPUB の各コンテンツ HTML ファイルを作成したあとに索引テキストデータを upmendex に通し、\_rv\_index.xhtml を作成する
- **mendex_html.ist** : EPUB での索引スタイル定義ファイル
- **review-ext.rb** : EPUB での idx, hidx の処理
- **mendex.ist** : https://qiita.com/munepi/items/2e1524859e24b5fb44bc の TeX PDF 用索引スタイル定義ファイル
- **sty/review-custom.sty** : https://qiita.com/munepi/items/2e1524859e24b5fb44bc の TeX PDF 用索引スタイル

## 仕組み
1. idx, hidx の内容が \_RVIDX\_index_raw.txt にブック全体のシリアルナンバーとともに書き出される。
2. EPUBMaker のフックで \_RVIDX\_index_raw.txt を開いて TeX の idx 形式に変換、および読みを MeCab から拾う。
3. upmendex に通してソートし、作業フォルダに \_RVIDX\_index.ind という名前で書き出す。
4. ind ファイルを HTML に変換し、\_rv\_index.xhtml として書き出し、目次に追加する。
5. 残りの EPUB 生成作業を続ける。

## WebMaker での利用
WebMaker にはフックの機能を提供していないのと、目次の作り方がよりシンプルで割り込みをかけるタイミングが難しい。

そこで、次のようなテクニックを使ってみる。

- ダミー索引ページ indices.re を作り、これをカタログに追加する。ただ、普通のカタログと混ぜるのはうまくないので、catalog-with-dummy-index.yml を作った。
- WebMaker のみこのカタログを利用するよう、config-web.yml を用意する。デフォルトと異なるファイルとなるため、rake 実行時には `REVIEW_CONFIG_FILE=config-web.yml rake web` と実行する必要がある。
- WebMaker 固有のフックとして、hook-afterbackmatter-web.rb を用意する。このフックスクリプトでは、WebMaker で indices.re から変換した HTML ファイル内の「◆REPLACE◆」行を、自動生成の索引 HTML コンテンツで置き換えるようにしている。
- hook-afterbackmatter-web.rb は後で手動実行でもよいが、手間を減らすために lib/tasks/z02_webindex.rake ルールを用意した。これは rake web を実行したときに最後にフックスクリプトを呼び出してくれる。

以上で、`REVIEW_CONFIG_FILE=config-web.yml rake web` により索引付きの Web ページができる。(なお、環境変数指示を忘れて普通の config.yml を読むとカタログファイルが違うので「No such file or directory @ rb_sysopen - webroot/indices.html (Errno::ENOENT)」となる)
