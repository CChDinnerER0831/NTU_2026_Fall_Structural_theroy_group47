# FRAME26 

**Advanced Structural Theory (Fall 2026)**  
National Taiwan University, Department of Civil Engineering



##  類別屬性架構 (Properties)

```matlab
classdef FRAME26 < handle
    properties
        % 檔案與專案元數據 (File & Project Meta Data)
        FILENAME    % 輸入檔案之完整路徑
        TITLE       % 結構專案標題名稱
        FUNIT       % 外力單位 (如 kN, kip)
        LUNIT       % 長度單位 (如 m, in)
        PRPGRAMMER  % 開發者資訊 (作者與指導教授)
        
        % 結構數量與類型指標 (Structural Counts & Options)
        NNOD        % 總節點數 (Number of Nodes)
        NBC         % 總桿件數 (Number of Beam-column Elements)
        NMAT        % 材料種類數 (Number of Material Types)
        NSEC        % 剖面種類數 (Number of Section Types)
        ITP         % 結構類型代碼 (1:Beam, 2:2D Truss, 3:2D Frame, 4:2D Grid, 5:3D Truss, 6:3D Frame)
        NNE         % 每桿件節點數 (Nodes per Element, 預設 2)
        IFORCE      % 內力/等效載重計算標記 (1:僅集中載重, 2:含固端力/非節點載重)
        
        NCO         % 每節點座標維度數 (Coordinates per Node)
        NDN         % 每節點自由度數 (DOFs per Node)
        NDE         % 每桿件總自由度數 (DOFs per Element = NDN * NNE)
        
        % 結構幾何與屬性陣列 (Structural Data Arrays)
        COOR        % 節點座標矩陣 [NCO x NNOD]
        NFIX        % 邊界條件限制矩陣 [NDN x NNOD] (0:自由, -1:固定)
        EXLD        % 節點外力矩陣 [NDN x NNOD]
        IDBC        % 桿件拓撲與材料/剖面索引矩陣 [5 x NBC]
        VECTY       % 空間桿件局部 y 軸方向餘弦矩陣 [3 x NBC] (僅 ITP=6)
        FEF         % 桿件等效固端力矩陣 [NDE x NBC] (僅 IFORCE=2)
        PROP        % 材料屬性矩陣 [5 x NMAT] (如 E, nu)
        SECT        % 剖面幾何屬性矩陣 [5 x NSEC] (如 A, Iz, Iy, J)
        
        % 自由度對應與全域分析屬性 (Analysis Properties)
        IDND        % 節點自由度編號矩陣 [NDN x NNOD]
        NEQ         % 全域總未知自由度數 (Total Number of Equations)
        LM          % 桿件定位矩陣 (Location Matrix) [NDE x NBC]
        NSBAND      % 全域剛度矩陣半頻寬 (Semiband Width)
        GLOAD       % 全域組合載重向量 [NEQ x 1]
        
        % 常數對照矩陣 (Constant Mapping Array)
        IPR = [1,2,2,2,3,3; 2,2,3,3,3,6]; % 各結構類型對應之 (NCO, NDN) 對照表
    end
```

---

## 方法介面與架構 (Methods)

### 公開方法 (Public Methods)

* **`FRAME26(filename)`** （建構函式）
  * 物件初始化：若未傳入檔案名稱，自動開啟 UI 檔案選擇視窗。
  * 載入檔案後自動依序觸發 `readInput()` 與 `computeProg2()`。

* **`readInput()`**
  * 解析 `.ipt` 輸入檔，讀取結構參數、幾何座標、邊界條件、外力及剖面材料資料。
  * 內建格式容錯處理，確保正確讀取 7 個核心參數。

* **`computeProg2()`**
  * 自動執行全域自由度分析流程：依序呼叫 `computeIDMAT()`、`computeMEMDOF()`、`computeSEMIBAND()` 與 `computeLOAD()`。

* **`computeIDMAT()`**
  * 掃描 `NFIX` 矩陣，為未受限自由度給予遞增編號，建立 `IDND` 矩陣並計算總方程式數 `NEQ`。

* **`computeMEMDOF()`**
  * 結合 `IDBC` 與 `IDND`，組裝各桿件之全域自由度映射向量，生成 `LM` 定位矩陣。

* **`computeSEMIBAND()`**
  * 計算全域剛度矩陣對稱帶狀區域之最大半頻寬 `NSBAND`。

* **`computeLOAD()`**
  * 將節點外力矩陣 `EXLD` 映射並累加至全域自由度，建構 `GLOAD` 載重向量。

* **`drawStructure(FORMAT)`**
  * 視覺化繪製結構幾何形貌、節點編號、桿件編號及支承邊界條件（支援 2D 與 3D 視角）。

### 私有輔助方法 (Private Methods)

* **`headLine(ID, IREAD)`**
  * 檔案讀取輔助函式，跳過標頭與註解行（以 `*` 開頭者）。

* **`readMatrix(IREAD, row, col)`**
  * 矩陣資料解析函式，將檔案區塊轉為指定維度之 MATLAB 矩陣。

---

## 使用範例 (Usage Example)

```matlab
% 1. 初始化模型並載入輸入檔 (自動計算 DOF、LM、NSBAND 與 GLOAD)
model = FRAME26('prog-2-2D_Frame.ipt');

% 2. 繪製結構幾何圖形
model.drawStructure('b-');

% 3. 存取全域分析資訊
total_dof  = model.NEQ;       % 總未知自由度數
band_width = model.NSBAND;    % 半頻寬
global_F   = model.GLOAD;      % 全域載重向量
```

---

All Rights Reserved © 2026  
Department of Civil Engineering, National Taiwan University.
