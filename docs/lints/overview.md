# Flutter Compositions Lint 指南

使用這組自訂 lint 規則，可以確保 CompositionWidget 保持響應式並維持一致的寫法。

- **在 `setup()` 內優先呼叫 `widget()` / `this.widget()`**，直接讀取欄位會跳過響應式系統。
- **避免在 Widget 類別上使用可變欄位**，所有可變狀態應存放於 `ref` 或 `ComputedRef`。
- **驗證 `provide` / `inject` 的型別**，確保兩者泛型一致。
- **禁止 `setup()` 使用 async**，必須同步回傳 builder。
- **針對未釋放的控制器發出警告**，強制使用 `use*` 輔助函式或自行 `dispose()`。

`custom_lint` 設定範例：

```yaml
custom_lint:
  rules:
    - flutter_compositions_ensure_reactive_props
    - flutter_compositions_no_async_setup
    - flutter_compositions_controller_lifecycle
```

建議修正步驟：

- 將直接使用的 props 包裝成 `widget()`，必要時搭配 computed selector。
- 將手動建立／釋放控制器改寫成 `use*` 輔助函式。
