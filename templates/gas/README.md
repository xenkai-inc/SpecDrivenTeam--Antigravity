# <プロジェクト名>

<このアプリは何をするか、1行で>

> この README は **技術仕様** をまとめた入口です。
> 機能ごとの詳しい仕様は [`spec/`](spec/) ディレクトリにあります。

---

## 概要

### 解決したい課題
- <課題1>
- <課題2>

### 想定ユーザー
<誰が使うか（自分だけ / 社内の人 / 社外の人も）>

---

## 技術スタック

- **実行場所**：Google Apps Script（GAS）の Web アプリ
- **画面**：HtmlService（`Index.html`。CSS・JS も同じファイル）
- **データの保存先**：Google スプレッドシート（<シート名>）
- **AI API**：Gemini API（`UrlFetchApp` で呼び出す）
- **開発の道具**：clasp（PC のコードを Google に送る）
- **テスト**：Vitest（PC の中だけで動く。Google には送らない）

---

## アーキテクチャ

```
ブラウザ（Index.html）
  → google.script.run で呼び出し
  → Code.gs（Google のサーバーで動く）  ※ API キーはスクリプトプロパティから読む
      → スプレッドシート（保存・読み込み）
      → Gemini API
```

---

## ディレクトリ構成

```
<プロジェクト名>/
├── README.md          # 技術仕様（このファイル）           ← PC だけ
├── spec/              # 機能ごとの仕様書                     ← PC だけ
├── appsscript.json    # GAS の設定（公開範囲・タイムゾーン）  ← Google に送る
├── Code.gs            # サーバー側の処理                     ← Google に送る
├── Index.html         # 画面                                 ← Google に送る
├── .claspignore       # Google に送るファイルの指定
├── .clasp.json        # Google 側のファイルとのひも付け（clasp create で作られる）
├── package.json       # テスト用の設定                       ← PC だけ
└── tests/             # テスト                               ← PC だけ
    ├── gas-loader.js
    └── <機能>.test.js
```

---

## セットアップ

1. テストの道具を入れる（初回のみ）
   ```bash
   npm install
   ```
2. Google 側にファイルを作る（初回のみ。すでに `.clasp.json` があれば不要）
   ```bash
   cp appsscript.json appsscript.json.bak
   clasp create --type webapp --title "<アプリ名>"
   mv appsscript.json.bak appsscript.json
   ```
   `clasp create` は `appsscript.json` を上書きするため、控えを取って戻す
3. Gemini の API キーを入れる（初回のみ・自分の手で）
   - Apps Script のエディタ →「プロジェクトの設定」→「スクリプトプロパティ」
   - プロパティ名 `GEMINI_API_KEY`、値に取得したキー

---

## 秘密情報の扱い（大事）

- API キーなどの秘密情報は **スクリプトプロパティにだけ** 入れる（コードに直接書かない）
- 画面（`Index.html`）や、画面に返す値に秘密情報を入れない
- スクリプトプロパティは、このファイルの **編集者なら読める**。ファイルを共有する相手に注意する
- 人に URL を渡す（公開する）前は `/secure`（公開前の安全チェック）を通す

---

## 保存して確認する

```bash
clasp push --force
```

`--force` を付けないと、`appsscript.json` を変えたときに「Skipping push.」と出て送られないことがあります。結果に「Pushed N files」と出れば送れています。

確認用 URL（自分だけが開ける、最新の内容）：`https://script.google.com/macros/s/<@HEAD の ID>/dev`
（ID は `clasp deployments` の `@HEAD` の行で分かります）

---

## テスト

```bash
npm run test
```

テストは PC の中だけで動きます。Google への保存（push）をしなくても実行できます。

---

## 公開

`/secure` を通してから：

```bash
clasp deploy --description "<変更内容>"
```

- 公開範囲・実行ユーザー：`appsscript.json` の `webapp`（現在：<自分だけ / 組織内 / 全員> × <作った人 / 使う人>）
- 公開用 URL（`/exec`）は公開した時点の内容で固定される。直した内容を反映するには、もう一度公開する

---

## 仕様（spec/）

機能ごとの詳しい仕様は [`spec/`](spec/) にあります。
一覧は [`spec/index.md`](spec/index.md) を参照してください。
