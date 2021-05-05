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
WebMaker にはフックの機能を提供していないため、rake web 後に hook_afterbackmatter.rb での作業内容を流用して \_rv\_index.xhtml を作り、これを目次に追加する必要がある。
