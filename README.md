# Riftbound

SwiftUIで作った、iPhone / iPad向けの縦持ちローグライクRPGプロトタイプです。

## 遊べる内容

- タイトル画面から新しいランを開始
- 1フロア4部屋のルート探索
- 通常戦闘（通常攻撃 / 重攻撃 / 回復）
- 祠イベントの選択
- 休息による回復とWard獲得
- 宝箱からのゴールド・回復薬・Ward獲得
- 3階のボス「The Hollow Crown」との戦闘
- 勝利 / 敗北後のリスタート

## 開き方

1. `Riftbound.xcodeproj` をXcodeで開く
2. iOS Simulator（iOS 17以降）を選択
3. `Riftbound` スキームでRun

Apple Developer Teamを設定していない場合、Simulator実行だけなら自動署名の設定でそのまま確認できます。

## 構成

- `RiftboundApp.swift` — アプリのエントリポイントと共有ゲーム状態
- `ContentView.swift` — タイトル、探索、戦闘、イベント、結果画面
- `GameModels.swift` — 部屋、敵、イベント、ログのモデル
- `GameStore.swift` — ランの状態遷移と戦闘ルール
- `RiftboundTheme.swift` — 色、パネル、ボタン、共通コンポーネント

最低デプロイターゲットは iOS 17.0 です。外部画像や外部ライブラリは使っていません。
