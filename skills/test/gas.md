# /test — GAS アプリの場合の追加ルール

> SKILL.md の考え方（safety net / 新仕様のテストは赤から / 触る範囲だけ）はそのまま使う。道具と対象だけ GAS 向けに読み替える。

## 役割分担（GAS のとき）

| 工程 | 担当 |
|---|---|
| 利用者への説明（下の「利用者への説明の例」）・自動テストにする AC の確認 | 伴走役（tech-lead） |
| `package.json`・`tests/gas-loader.js`・`.claspignore` の準備、テストを書く・実行する、`clasp status` で送られるファイルを確かめる | テスト担当（tester） |
| 実行結果の翻訳報告 | 伴走役 |

伴走役は委譲文に、spec の AC のうち **「確かめ方: 自動テスト」のものだけ** を抜粋して渡す。

## GAS アプリのテストの考え方

GAS のコード（`.gs`）は Google の中で動くが、**判定・計算・整形の部分は PC の中でもそのまま動かせる**。そこで：

- **アプリのコードは書き換えない**。テスト側の小さな道具（`tests/gas-loader.js`）が `.gs` ファイルを読み込み、関数を呼び出して確かめる
- **自動テストにするのは、spec の AC で「確かめ方: 自動テスト」になっているものだけ**。「確認用 URL」の AC は `/implement` の最後に利用者と画面で確かめる
- テストのファイル一式（`tests/`・`package.json`・`node_modules/`）は **PC にだけ置き、Google には送らない**

利用者への説明の例：

> 「GAS のアプリは Google の中で動きますが、『締切を過ぎたか』のような判定の部分は、あなたの PC の中でも確かめられます。アプリのコードはそのままで、テスト用の道具がコードを読み込んで確かめます。画面の見た目やスプレッドシートへの保存は、あとで確認用 URL を開いて一緒に確かめましょう」

## 前提の準備（SKILL.md「前提」の読み替え）

`package.json` がなければ、`templates/gas/package.json` をコピーして、Vitest だけを入れる（jsdom・React 用の部品は要らない）：

```bash
npm install -D vitest
```

あわせて次の 2 つをそろえる：

1. `templates/gas/gas-loader.js` を `tests/gas-loader.js` にコピーする
2. `.claspignore`（Google に送るファイルの指定）を確認する。なければ `templates/gas/.claspignore` をコピーする。**`tests/`・`package.json`・`node_modules/` が送られない指定になっているか** を `clasp status`（送られるファイルの一覧を出すコマンド）で確かめる

> サーバー側のコードを `.js` で書いているプロジェクト（`clasp pull` で取ってきた場合など）は、`.claspignore` の `!*.gs` を、そのファイル名（例：`!Code.js`）に合わせて直す。合っていないと、push でコードが送られなくなる

## テストを書く（SKILL.md「3. テスト書き」の読み替え）

`templates/gas/example.test.js` を参考にする：

```js
import { describe, it, expect } from 'vitest'
import { loadGas } from './gas-loader.js'

const gas = loadGas(['Code.gs'])

describe('締切の判定', () => {
  it('AC-2 締切を過ぎたタスクは期限切れと判定される', () => {
    expect(gas.isOverdue('2026-11-01', '2026-11-04')).toBe(true)
  })
})
```

- `loadGas` には、テストしたい関数が入っている `.gs` ファイルを渡す。GAS は複数の `.gs` が 1 つの場所を共有して動くので、関数が別ファイルの関数を呼ぶなら、そのファイルも一緒に渡す
- テストファイルは `.js` で書く（TypeScript にしない。GAS のコードと書き方をそろえるため）

## 何を自動テストにするか

| 対象 | 自動テスト | 理由 |
|---|---|---|
| 判定・計算・整形・入力チェックの関数 | する | 答えが 1 つに決まる |
| Gemini に送る指示文の組み立て | する | 入力が同じなら同じ文になる |
| Gemini の返答を読み取る部分（JSON の取り出し、想定外の値のときの扱い） | する | 返答の「形」は決めておける |
| Gemini の返答の中身（文章の良し悪し） | しない | 毎回変わる。確認用 URL で人が見る |
| スプレッドシートへの保存・読み込み | 原則しない | Google の中でしか本物は動かない。確認用 URL で確かめる |
| 画面（`.html`）の見た目・操作 | しない | 確認用 URL で確かめる |

### Google の道具を使う関数をテストしたいとき（代役）

判定の途中で `SpreadsheetApp`・`UrlFetchApp`（外部 API の呼び出し）・`Utilities` などを使っている関数は、`loadGas` の 2 つ目の引数で **決まった答えを返す代役** を渡すとテストできる：

```js
const gas = loadGas(['Code.gs'], {
  UrlFetchApp: {
    fetch: () => ({ getContentText: () => JSON.stringify({ candidates: [{ content: { parts: [{ text: '{"status":"ok"}' }] } }] }) }),
  },
  PropertiesService: { getScriptProperties: () => ({ getProperty: () => 'dummy-key' }) },
})
```

- 代役は **「返答の読み取り」をテストしたいときだけ** 使う。代役を作り込みすぎると、テストが本物と違う動きを確かめることになるため
- 代役に本物の API キーを書かない（`'dummy-key'` のような偽の値にする）
- 判定がひとまとまりの大きな関数に埋もれていて代役がたくさん要るときは、テスト担当はテストを無理に書かず、その旨を伴走役に報告する。伴走役が `/implement` で「判定の部分だけ小さな関数に分ける」ことを利用者に提案する（既存の動きを変える変更なので、承認を得てから実装担当に委譲）

## 実行・確認

SKILL.md と同じく、テスト担当が実行し、伴走役が結果をかみ砕いて利用者に伝える：

```bash
npm run test
```

テストは PC の中だけで動く。**Google への保存（push）をしなくても実行できる** ことを利用者に伝える。

## やらないこと（追加）

- テストのためにアプリのコード（`.gs`）を書き換えない（分ける提案は `/implement` で、承認を得てから）
- `tests/` や `package.json` を Google に送らない
- Gemini の返答の中身を自動テストで固定しない
