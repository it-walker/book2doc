# エラーハンドリングの強化

## 概要
OCR処理やネットワークエラー時の対応を改善し、より安定した処理を実現します。

## 優先度
高

## タスク
- [ ] OCR処理の失敗時のリトライ機能の実装
  - 一時的なネットワークエラー時の自動リトライ
  - 画像認識精度が低い場合の再試行
- [ ] ネットワークエラー時の対応
  - オフライン時の処理
  - API制限に達した場合の待機処理

## 関連ファイル
- `main.py`
- `ocr.applescript`

## ラベル
- enhancement
- high-priority 