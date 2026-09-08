// SpecDrivenCoder template: Vitest の最小サンプル
//
// このファイルは自分のプロジェクトにコピーして使う雛形です。
// 実際のテストは src/ の対応するロジック・コンポーネントを対象に書きます。

import { describe, it, expect, beforeEach } from 'vitest'

// --- 例1：純粋関数のテスト ---

const sum = (a: number, b: number) => a + b

describe('sum', () => {
  it('1 + 2 は 3 になる', () => {
    expect(sum(1, 2)).toBe(3)
  })

  it('負の数でも正しく計算できる', () => {
    expect(sum(-1, 1)).toBe(0)
  })
})

// --- 例2：localStorage 永続化のテスト（jsdom 環境前提） ---

const STORAGE_KEY = 'systemPrompt'

const saveSystemPrompt = (value: string) => {
  localStorage.setItem(STORAGE_KEY, value)
}

const loadSystemPrompt = (): string | null => {
  return localStorage.getItem(STORAGE_KEY)
}

describe('SystemPrompt 永続化', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('保存した値が読み出せる', () => {
    saveSystemPrompt('テスト用プロンプト')
    expect(loadSystemPrompt()).toBe('テスト用プロンプト')
  })

  it('未設定なら null を返す', () => {
    expect(loadSystemPrompt()).toBeNull()
  })

  it('上書き保存ができる', () => {
    saveSystemPrompt('A')
    saveSystemPrompt('B')
    expect(loadSystemPrompt()).toBe('B')
  })
})
