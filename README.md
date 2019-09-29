# NFCリーダーサンプル

## 参考にしたサイトたち

* [iOS13のCoreNFCを使ってみた。](https://qiita.com/HAL27241/items/e567f021c99e10d148a7)
    * プロジェクトの初期設定など
    * あまり詳しくない
* [TRETJapanNFCReader](https://github.com/treastrain/TRETJapanNFCReader)
    * NFCタグリーダーのライブラリ
    * READMEを見ると色々とNFCのコードなどが書いてある
    * 実装はまだちゃんと見ていない
* [【WWDC19】Core NFC で FeliCa(Suica) を読み取るサンプル【iOS 13 以降】](https://qiita.com/treastrain/items/23d343d2c215ab53ecbf)
    * NFCを読み取って、デバッグ出力するまでのサンプル
    * 結構詳しく書いてある
* [iOS13 CoreNFC NFC type-Bの読み取り](https://qiita.com/nekonekodou-mike/items/7c6c6f609d3dc4ee9db8#_reference-2912fa86b34a64e0fd1c)
    * 一つ前のサンプルをもとに、一歩進んで読み取ってる？
    * 要調査
* [iOSでSuicaの履歴を読み取る](https://qiita.com/m__ike_/items/7dc3e643396cf3381167)
    * 読み取ったデータの解析を本格的に行っているように見える
    * 要調査

## CoreNFC

* iOS11とiPhone7以降の端末でNFCタグを読めるようになった。
* ただ、扱えたのはシールなどであるNFCタグ程度
* iOS13では、ICカードも行けるようになった。ただし制限あり。

## 扱うには、以下が必要

* iOS13以降
* iPhone7以降
* Xcode11以降

