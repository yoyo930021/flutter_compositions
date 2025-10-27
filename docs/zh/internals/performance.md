# 效能考量

## 最小化重建

- builder 只會在讀取到的 `ref` 或 `computed` 變化時重新執行。
- 搭配 `ComputedBuilder` 或拆成小部件，可進一步縮小重建範圍。

## 批次更新

- 多次 `.value = ...` 操作會在同一個 microtask 中批次觸發，避免重複 rebuild。
- 若需要立即看到中間狀態，可使用 `await Future.microtask((){})` 強制切割更新。

## 建議實務

- 用 `computed` 快取昂貴的計算，例如排序、過濾或統計。
- 在 builder 中只讀取必要的 ref，其餘資料可透過 `const` widget 或拆成子 widget。
- 利用 `provide` / `inject` 傳遞 `Ref`，而非直接傳遞大型物件，可確保真正使用者才會重建。

## 監控與除錯

- 使用 `watchEffect` 臨時觀察依賴，搭配 `debugPrint` 確認哪些值觸發更新。
- 若遇到 Hot Reload 後狀態錯亂，檢查 `ref` 宣告順序是否被改動。

## 延伸閱讀

- [最佳實務指南](../guide/best-practices.md)
- [Technical Deep Dive](./technical-deep-dive.md)
