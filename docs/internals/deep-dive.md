# 深入理解 Flutter Compositions

本文整合了 Flutter Compositions 的核心架構、響應式系統原理、設計取捨與效能考量，幫助你深入理解框架的運作方式。

## 架構概覽

Flutter Compositions 在原生 `StatefulWidget` 之上建構一層極薄的執行期，提供類似 Vue Composition API 的開發體驗。

### 生命週期流程

1. **初始化階段** (`initState`)
   - 建立 `_SetupContext`
   - 呼叫一次 `setup()`
   - 註冊生命週期掛勾、建立 reactive state
   - 取得負責繪製 UI 的 builder 函式

2. **響應式執行**
   - Builder 包裝在 `alien_signals` 的 `effect` 中執行
   - 當依賴的 `Ref` 或 `Computed` 變動時，自動重新執行 builder

3. **Props 更新**
   - 當父層傳入新 props 時，內部的 `_widgetSignal` 送出新的 widget 實例
   - 透過 `widget()` 取得的 props 保持響應式

4. **清理階段** (`dispose`)
   - 自動清理 `setup()` 註冊的 effects、控制器與掛勾
   - 避免資源洩漏

### 響應式資料流

```
父層傳入 props
    ↓
_widgetSignal 更新 (WritableSignal)
    ↓
相關的 computed 與 watcher 重新執行
    ↓
builder 在 effect 內重新執行
    ↓
產生新的 Widget tree
    ↓
Flutter Element diff（只重繪有變化的部分）
```

## 響應式系統原理

Flutter Compositions 的核心驅動力是 `alien_signals` 套件。理解其原理能幫助你完全掌握框架的運作方式。

### Signal 系統的三大支柱

1. **Signal (Ref)**：響應式數據源
   - 由 `ref()` 建立
   - 讀取 `.value` 時建立依賴追蹤
   - 寫入 `.value` 時觸發更新

2. **Computed**：衍生的數據
   - 由 `computed()` 建立
   - 自動追蹤計算過程中用到的依賴項
   - 採用惰性計算（Lazy Evaluation）

3. **Effect**：響應式系統的終端
   - 由 `watchEffect()`、`watch()` 或 builder 隱式建立
   - 自動追蹤執行過程中用到的依賴項
   - 依賴變化時自動重新執行

### 自動依賴追蹤

當你在 `computed` 或 `effect` 函式內部讀取 `ref.value` 時：

1. 執行前，設定全域的「當前監聽者」
2. 存取 `ref.value` 時，`ref` 檢查當前監聽者
3. 若存在，將監聽者加入訂閱者清單
4. 函式執行完畢後，清除當前監聽者

這就是為什麼不需要手動聲明依賴關係。

### 更新流程

當修改 `ref.value` 時：

1. `ref` 的 setter 被呼叫
2. 遍歷訂閱者清單，通知所有依賴者
3. `computed` 標記為「過期」，等待下次讀取時才重新計算
4. `effect` 加入佇列，在 microtask 中批次執行

### 與 Flutter 的整合

`CompositionWidget` 將 builder 函式包裝在 effect 中：

```dart
_renderEffect = effect(() {
  // 執行 builder 函式
  final newWidget = builder(context);

  // 產生的 Widget 不同時呼叫 setState
  if (_cachedWidget != newWidget) {
    setState(() {
      _cachedWidget = newWidget;
    });
  }
});
```

這實現了：
- 只有 builder 內部使用的響應式數據變化時才重新執行
- 重新執行時呼叫 `setState` 觸發 Flutter 更新
- Flutter 的 Element diff 確保只更新變化的部分

## 核心設計取捨

### `setup()` 只執行一次

**優點**：
- 避免重複初始化
- 清晰的生命週期
- 效能更好

**挑戰**：
- 需要 `widget()` API 來響應 props 變化
- 學習成本稍高

**解決方案**：
- `_widgetSignal` 在 `didUpdateWidget` 時更新
- `widget()` 返回對 signal 的訂閱
- 換取完全的響應式能力和清晰的數據流

### `provide/inject` vs `InheritedWidget`

| 特性 | provide/inject | InheritedWidget |
|------|---------------|-----------------|
| 查找時間 | O(n) | O(1) |
| 更新機制 | 手動（透過 Ref） | 自動觸發重建 |
| 重建範圍 | 無，僅更新依賴的 builder | 所有依賴的後代 |
| 設置成本 | initState 時一次性 | 每次 build |

**為什麼選擇 O(n) 查找？**

1. **避免不必要的重建**
   - `InheritedWidget` 變化時重建所有依賴者
   - `provide/inject` 傳遞 `Ref`，只有讀取的 builder 才更新

2. **淺層樹中效能足夠**
   - 大多數應用的組件樹深度 < 10 層
   - O(n) 查找開銷可忽略

**使用建議**：
- 響應式狀態：使用 `provide/inject`
- 全域配置（如 Theme）：仍可使用 `InheritedWidget`

### 對 `alien_signals` 的依賴

**優點**：
- Dart 生態中最快的響應式函式庫之一
- 專注於上層 API 設計
- 輕量且專注

**缺點**：
- 效能與行為受其約束

**結論**：
策略性選擇。利用專注的底層函式庫比從頭打造更明智。

## 效能考量

### provide/inject 效能特性

**時間複雜度**：
- 查找：O(n)，n 為祖先 CompositionWidget 數量
- 首次查找需走訪父層鏈
- 取得 Ref 後的讀寫為 O(1)

**空間複雜度**：
- 每個 SetupContext 保存 `_parent` 參考與 `_provided` Map
- 總耗用 O(w)，w 為註冊 provide 的 widget 數量

### 效能比較

| 指標 | provide/inject | InheritedWidget |
|------|---------------|-----------------|
| 查找時間 | O(n) | O(1) |
| 記憶體 | 父層參考 + Map | 整個 InheritedElement |
| 更新行為 | Ref 手動控制 | 變更觸發所有依賴重建 |
| 重建開銷 | 無（reactive 控制） | 所有依賴 widget 重建 |
| 設置成本 | initState 一次性 | 每次 build |

### 優化建議

1. **保持 provide/inject 鏈條淺層化**
   ```dart
   // ✅ 合理：父子相連
   Parent -> Child

   // ✅ 可接受：2~3 層
   Grandparent -> Parent -> Child
   ```

2. **以 Ref 傳遞 reactive state**
   ```dart
   // 只有使用 theme.value 的地方才更新
   final theme = ref(AppTheme('dark'));
   provide(themeKey, theme);

   final localTheme = inject(themeKey);
   return Text(localTheme.value.mode);
   ```

3. **針對專案情境進行 Benchmark**
   ```dart
   testWidgets('benchmark provide/inject', (tester) async {
     final stopwatch = Stopwatch()..start();
     await tester.pumpWidget(/* your widget tree */);
     stopwatch.stop();
     print('Time: ${stopwatch.elapsedMicroseconds}μs');
   });
   ```

### 何時使用哪一種？

**適合使用 provide/inject**：
- ✅ 需要透過 Ref 實現細粒度響應式更新
- ✅ 想避免多餘的 widget 重建
- ✅ 組件樹深度較淺（< 10 層）
- ✅ 需要型別安全的依賴注入

**適合使用 InheritedWidget**：
- ✅ 查找成本必須為 O(1)，樹深度很深
- ✅ 希望值改變時自動重建整個子樹
- ✅ 使用 Flutter 內建的 Theme、MediaQuery 等全域資源

## 錯誤防護機制

1. **Assertion 檢查**
   - 確保生命週期相關工具只能在 `setup()` 內呼叫

2. **inject 錯誤處理**
   - 找不到依賴時立即拋出錯誤（非可空型別）
   - 避免靜默失敗

3. **自動清理**
   - 所有透過 `watch`、`use*` 註冊的 effect 綁定 `_SetupContext`
   - 在 `dispose` 時自動清理

## 總結

Flutter Compositions 透過以下設計實現高效能的響應式 UI：

1. **細粒度響應式**：只更新真正變化的部分
2. **清晰的生命週期**：`setup()` 只執行一次
3. **自動依賴追蹤**：無需手動聲明依賴
4. **型別安全的 DI**：InjectionKey 防止注入錯誤
5. **自動資源管理**：防止記憶體洩漏

理解這些原理能幫助你更好地使用框架，並在適當時機做出正確的架構決策。
