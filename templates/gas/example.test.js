// SpecDrivenCoder template: GAS アプリのテストの最小サンプル（Vitest）
//
// このファイルは雛形です。対象プロジェクトの tests/ にコピーし、
// spec の AC のうち「確かめ方: 自動テスト」のものだけを書きます。

import { describe, it, expect } from 'vitest'
import { loadGas } from './gas-loader.js'

// テストしたい関数が入っている .gs ファイルを読み込む
const gas = loadGas(['Code.gs'])

// --- 例1：判定の関数のテスト ---
describe('締切の判定（spec/deadline.md）', () => {
  it('AC-2 締切を過ぎたタスクは期限切れと判定される', () => {
    expect(gas.isOverdue('2026-11-01', '2026-11-04')).toBe(true)
  })

  it('AC-2 締切当日はまだ期限切れではない', () => {
    expect(gas.isOverdue('2026-11-04', '2026-11-04')).toBe(false)
  })

  it('AC-4 締切なしのタスクは期限切れにならない', () => {
    expect(gas.isOverdue('', '2026-11-04')).toBe(false)
  })
})

// --- 例2：Gemini の返答を読み取る関数のテスト（代役を使う） ---
// UrlFetchApp（外部 API の呼び出し）の代わりに、決まった返答を返す代役を渡す。
// 本物の API キーは書かない。
const geminiReply = (text) => ({
  getResponseCode: () => 200,
  getContentText: () => JSON.stringify({ candidates: [{ content: { parts: [{ text }] } }] }),
})

describe('Gemini の返答の読み取り', () => {
  it('返答の JSON からステータスを取り出せる', () => {
    const app = loadGas(['Code.gs'], {
      UrlFetchApp: { fetch: () => geminiReply('{"status":"warning"}') },
      PropertiesService: { getScriptProperties: () => ({ getProperty: () => 'dummy-key' }) },
    })
    expect(app.askStatus('今日の困りごと').status).toBe('warning')
  })

  it('想定外の値が返ったときは unknown として扱う', () => {
    const app = loadGas(['Code.gs'], {
      UrlFetchApp: { fetch: () => geminiReply('{"status":"すごく良い"}') },
      PropertiesService: { getScriptProperties: () => ({ getProperty: () => 'dummy-key' }) },
    })
    expect(app.askStatus('今日の困りごと').status).toBe('unknown')
  })
})
