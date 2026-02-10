# Pascal compilation for browser target
_Exported on 2/10/2026 at 19:44:09 GMT+9 from Cursor (2.4.31)_

---

**User**

pas2js .\quantum_shogi.pas -Tbrowser "-Jirtl.js"
コマンドを実行しコンパイルを完了させる

---

**Cursor**

pas2jsでコンパイルを実行しています。


コンパイルエラーが発生しています。145行目付近を確認して修正します。


onclick は `TJSMouseEvent` を期待しているため、引数を `TJSEvent` から `TJSMouseEvent` に変更します。


同様の `onclick` が他にないか確認してから、再コンパイルします。


型がまだ合いません。`reference to function ... safecall` が期待されているため、`OnCellClick` の定義と代入方法を確認します。


無名関数は「of Object」になるため、ボードと同様にグローバル関数で駒台用のハンドラを用意します。


再コンパイルを実行しています。


前方宣言を追加しています。


onclick が `TJSMouseEvent` を渡すため、`OnStandClick` の引数を `TJSMouseEvent` に変更します。


盤面の `OnCellClick` を `TJSMouseEvent` に合わせます。


`CheckVictory` の前方宣言と実装を確認しています。


`CheckVictory` の実装を追加しています。


コンパイルは正常に完了しました。生成された JS ファイルを確認します。


コンパイルは問題なく完了しました。

実施した修正は次のとおりです。

1. **駒台の onclick の型**
   - 無名関数をやめ、グローバル関数 `OnStandClick` を追加し、`Container.onclick := @OnStandClick` で代入するように変更。
   - 引数型を `TJSMouseEvent` に統一（pas2js の `onclick` は `reference to function(TJSMouseEvent): Boolean` を要求するため）。

2. **盤面の OnCellClick**
   - 引数型を `TJSEvent` から `TJSMouseEvent` に変更し、上記と揃えました。

3. **CheckVictory**
   - クラスで宣言されていた `CheckVictory` の実装がなかったため、空の `procedure TGame.CheckVictory` を追加しました。

4. **前方宣言**
   - `OnStandClick` を `UpdateUI` より前で参照しているため、`function OnStandClick(e: TJSMouseEvent): boolean; forward;` を追加しました。

生成された JavaScript は `quantum_shogi.js` です。オプション `-Jirtl.js` で出力先を `irtl.js` にしたい場合は、次のように実行してください。

```text
pas2js .\quantum_shogi.pas -Tbrowser -Jirtl.js
```

（`-J` とファイル名の間にスペースを入れると、出力ファイル名として解釈される場合があります。）

---

**User**

文字を大きくする。文字の色を黒にする。

---

**Cursor**

スタイルを確認し、文字サイズを大きく、色を黒にします。


文字を大きくし、色を黒にします。


画面下部の「手番」は背景が暗いため、黒文字が読めるようにします。


以下のように変更しました。

**style.css の変更内容:**

1. **文字を大きく**
   - `body`: `font-size: 1.25rem` を追加（全体のベースを拡大）
   - 駒の文字（`.quantum-char`）: `18px` → `26px`
   - 手番表示（`#status`）: `24px` → `28px`

2. **文字の色を黒に**
   - `body`: `color: white` → `color: black`
   - `.quantum-char`: `color: black` を指定（盤面・駒台の駒文字）
   - `#status`: `color: black` を指定

3. **手番表示の見やすさ**
   - 背景が暗いため、`#status` に薄い背景（`#eee`）とパディングを追加し、黒文字が読みやすいようにしました。

ブラウザで再読み込みすると反映されます。

---

**User**

桂馬はねしても桂馬確定にならない。

---

**Cursor**


桂馬の動きをしたときに駒を桂馬に確定する処理を確認しています。



CanMove を確認しました。桂馬の判定が `else Result := True` に落ちており、桂馬の動き（前へ2・左右に1のL字）で絞り込めていません。桂馬用の判定を追加します。



銀の動きを修正しています（斜め後ろの2マスを許可）。



演算子の優先順位のため、銀の条件に括弧を追加しています。



コンパイルして動作を確認しています。



対応しました。

**原因**  
`CanMove` で桂馬（ptKnight）が `else Result := True` にしか含まれておらず、「桂馬だけができる動き」で可能性を絞り込めていませんでした。

**変更内容**  
桂馬の動き（前に2・左右に1のL字）を判定する式を追加しました。

- **桂馬**: `(absX = 1) and (absY = 2) and (dy = -2)`  
  → この動きをした駒は桂馬に確定します。

あわせて、香車・銀将の動きも正しく判定するようにしました。

- **香車**: 前方一直線  
- **銀将**: 前1・斜め前2・斜め後ろ2の5方向  

これで、桂馬の動き（例: 2マス前＋1マス左右）で動かすと、その駒は「桂」に確定して表示されます。再コンパイル済みなので、ブラウザを再読み込みして動作を確認してください。

---

**User**

持ち駒台の駒が重ならないようにする。

---

**Cursor**


駒台のスタイルを確認し、駒が重ならないようにします。



駒台内の `.cell` に固定サイズを指定し、折り返して重ならないようにします。



駒台の `.cell` 内で駒が中央に表示されるようにします。



対応しました。

**変更内容（style.css）:**

1. **駒台全体**
   - `align-content: flex-start` で上から詰めて並べる
   - `gap: 4px` で駒同士に少し余白
   - `overflow-y: auto` で駒が多くても縦にスクロールできるように

2. **駒台の各マス（`.piece-stand .cell`）**
   - `width: 52px; height: 52px` で1駒の大きさを固定
   - `min-width / min-height` で縮まないように
   - `flex-shrink: 0` で折り返し時に潰れないように
   - `display: flex; justify-content: center; align-items: center` で駒を中央に表示

これで持ち駒は 52×52px のマスに1つずつ入り、横に2列で折り返して重ならず並びます。駒が増えた場合は駒台が縦にスクロールします。

---

**User**

文字をもう少し大きくして、升目の真ん中に表示されるようにする。

---

**Cursor**


文字を少し大きくし、升目の中央に表示されるようにします。



駒文字の配置方法を Pascal 側で確認しています。



駒文字に `left: 50%; top: 50%` を追加して中央に配置し、フォントサイズを大きくします。



Pascal 側で `transform` をインライン指定しているため、後手の `rotate(180deg)` が CSS の `transform` に上書きされます。インラインが優先されるので表示は問題ありません。駒台の文字も同じクラスで中央に収まります。



対応しました。

**変更内容（style.css）:**

1. **文字を大きく**
   - `.quantum-char` の `font-size` を `26px` → `34px` に変更しました。

2. **升目の中央に表示**
   - `.quantum-char` に `left: 50%;` と `top: 50%;` を追加し、升目の中心に基準が来るようにしました。
   - `transform: translate(-50%, -50%);` を CSS に追加しました（Pascal 側でも同様の指定があり、後手は `rotate(180deg)` 付きで上書きされます）。

盤面の升目と駒台のマスのどちらも、駒の文字が中央に表示されます。ブラウザを再読み込みして確認してください。

---

**User**

矛盾移動ですの表示をする代わりに、移動範囲を表示し、そこしかクリックできないようにする。ただし、駒の選択を変えることはかのう。

---

**Cursor**


選択駒の移動可能マスを表示し、そのマスと駒の選択変更だけをクリック可能にします。



移動可能マスを表示し、そのマスと駒の選択変更のみクリック可能にします。



実装を入れました。

**変更内容**

1. **移動範囲の計算・表示**
   - `ValidMoves[1..9, 1..9]` と `ComputeValidMoves(fx, fy)` を追加。
   - 駒を選ぶと、その駒で「矛盾なく動けるマス」だけを計算して `ValidMoves` に格納。
   - そのマスに `.move-dest` を付与し、薄い緑で表示。

2. **クリックの受け付け**
   - **駒を選択した状態で**受け付けるのは次のだけ：
     - **同じマス** → 選択解除
     - **移動可能マス（緑）** → そこへ移動
     - **味方の駒** → その駒に選択変更
   - 上記以外のマスをクリックしても何もしない（「矛盾移動です」は出さない）。

3. **駒台から打つ場合**
   - 空いているマスだけクリックで打てるようにし、駒の上は無視。

4. **UI**
   - 「矛盾移動です」のアラートは削除。
   - `.move-dest` のスタイルを追加（緑背景＋ホバーで少し濃く）。

これで、選択した駒の移動可能マスだけが緑で表示され、そのマスと「選択し直し」だけがクリックで反応します。

---

**User**

移動遷移後は移動範囲は色を元に戻す

---

**Cursor**


移動後に移動範囲の色を確実に戻すため、選択解除時に `ValidMoves` をクリアし、`move-dest` を明示的に外すようにします。



選択がないときに `ValidMoves` をクリアし、移動範囲の色を確実に戻します。



対応しました。

**変更内容**

- **駒を選んでいないとき**（移動後や選択解除後）に、`ValidMoves` をすべて `False` でクリアするようにしました。
- そのうえで、`move-dest` クラスを付与する条件を「選択ありかつ ValidMoves[x,y] が True のときだけ」にしているため、選択が外れたタイミングで全マスから `move-dest` が外れ、升目の色が元に戻ります。

これで、駒を動かした直後や同じ駒をクリックして選択解除した直後に、移動範囲の緑が消えて通常の升目表示になります。

---

**User**

桂馬が増殖してしまう。
初期条件
先手、後手それぞれ
王１枚、角１枚、飛車１枚、金２枚、銀２枚、桂馬２、香車２
歩８枚。
初期先手グループと初期後手グループを用意し、
駒の枚数に矛盾がないようにする。

---

**Cursor**


桂馬の増殖を防ぎ、先手・後手それぞれで正しい駒数を保つ初期配置にします。コードを確認します。



初期駒を「先手用・後手用」の固定セットで用意し、将棋の初期配置で置くようにします。



InitBoard を整理し、まず盤面をすべて nil にしてから駒を配置します。



対応しました。

**変更内容**

1. **`TQuantumPiece.CreateWithType(AOwner, APieceType)` を追加**
   - 駒を1種類に固定して作成するコンストラクタです。`Possibilities := [APieceType]` のみを持つため、桂馬は「桂」1種類だけになります。

2. **`InitBoard` を将棋の初期配置に変更**
   - 盤面をいったんすべて空（nil）にしたうえで、**先手・後手それぞれ 19 枚**を 1 枚ずつ作成して配置しています。
   - **先手(0)**  
     王1・角1・飛1・金2・銀2・桂2・香2・歩8  
     9段: 香桂銀金王金銀桂香、8段: 飛・角、7段: 歩×9  
   - **後手(1)**  
     同様に 王1・角1・飛1・金2・銀2・桂2・香2・歩8  
     1段: 香桂銀金王金銀桂香、2段: 角・飛、3段: 歩×9  

駒の生成は `InitBoard` のこの配置だけなので、桂馬は先手2枚・後手2枚のまま増えません。取った駒は駒台に追加され、打つときはその駒を盤に移すだけなので、枚数の矛盾も起きません。

---

**User**

これでは普通の将棋になっている。

---

**Cursor**


量子将棋を復活させます。駒は先手・後手それぞれ19枚のまま、各駒を「複数種類の重ね合わせ」で持ち、取った駒は駒台で1枚として扱い、移動で観測（収束）したときに「種類ごとの枚数上限」を超えないようにします。



初期配置は19枚のまま、各駒を重ね合わせ（Create）で作成し、移動で収束したときに種類ごとの枚数上限をチェックするようにします。



WouldExceedTypeCount の判定を修正しています。



MovePiece と ComputeValidMoves で枚数上限チェックを追加しています。



打ち駒で「行き所のない駒」により収束した場合の枚数チェックを DropPiece に追加します。



対応しました。量子将棋の挙動を復活させつつ、駒の枚数が矛盾しないようにしています。

**変更内容**

1. **初期配置を量子状態に戻す**
   - 先手・後手とも、各マスに `TQuantumPiece.Create(owner)` で「全8種類の重ね合わせ」の駒を1枚ずつ配置（合計19枚／側）。
   - 配置は従来どおり（香桂銀金王金銀桂香・飛・角・歩×9 の標準形）。

2. **種類ごとの枚数上限**
   - 各側の駒種ごとの上限を定義: 王1・角1・飛1・金2・銀2・桂2・香2・歩8。
   - `InitialCountForType(pt)` でその枚数を返すようにしました。

3. **「確定した駒」の枚数チェック**
   - `CountPiecesWithType(owner, pt)`  
     盤上＋駒台のうち、`Possibilities = [pt]` になっている駒の数だけを数えます。
   - `WouldExceedTypeCount(owner, p, newSet)`  
     駒 `p` を `newSet` に収束させたとき、その種類の「確定数」が上限を超えるか判定します。

4. **移動時**
   - 移動で `newSet` が1種類に収束する場合、`WouldExceedTypeCount` が真ならその手は不可（`MovePiece` では何もせず return、`ComputeValidMoves` ではそのマスを移動先に含めない）。

5. **打つとき**
   - 打ち場所で「行き所のない駒」を除いた結果を `newSet` として計算し、`newSet = []` なら打てない、`WouldExceedTypeCount` が真ならその打ち手は不可にしました。

この結果、
- 開始時は全駒が「複数種類の重ね合わせ」の量子状態、
- 動かす／打つたびに「その手で観測された種類」に収束し、
- 収束後の「王・角・飛・金・銀・桂・香・歩」の枚数が、それぞれ上限を超えないように制限されています。

---

**User**

先手の角が２枚出現する。
初期配置先手のグループ　角１枚
初期配置後手のグループ　角１枚

現在は両者で２枚になっている。

---

**Cursor**


角は全局で2枚（先手1・後手1）にすべきです。現在は「先手の角が2枚」になっているため、枚数制限を「各プレイヤーごと」から「全局でその種類の確定数」に変更します。



角は全局で2枚（先手1＋後手1）に制限するため、枚数制限を「全局の確定数」で行うよう変更します。



コンパイルして確認しています。



クラス宣言を更新しています。



対応しました。

**変更内容**

1. **「先手だけ／後手だけ」ではなく「全局」で枚数制限**
   - 角は全局で最大2枚（先手1＋後手1）にします。
   - 王・飛も同様に全局で2枚、金・銀・桂・香は全局で4枚、歩は16枚です。

2. **追加・変更した関数**
   - `InitialTotalCountForType(pt)`  
     駒種ごとの**全局での最大数**を返すように変更。  
     角・飛・王＝2、金・銀・桂・香＝4、歩＝16。
   - `CountPiecesWithTypeGlobal(pt)`  
     盤上＋両者の駒台を合わせた「その駒種に確定している駒の数」を返す関数を追加。

3. **`WouldExceedTypeCount` の判定**
   - これまで: その手番の側だけを数え、先手なら「先手の角は1枚まで」で判定。
   - 今回: **全局**の確定数を数え、「角は全局で2枚まで」で判定するように変更。

この結果、
- 角に確定している駒が全局で2枚を超えるような手（3枚目を角に収束させる手）は指せません。
- 先手が後手の角を取れば「先手の角2枚・後手の角0枚」は許容され、全局で角は2枚のままです。
- 先手の角が2枚・後手の角も2枚（計4枚）になることはなくなります。

---

**User**

初期戦力は先手と後手は一緒である。

初期の先手駒をグループA
初期の後手駒をグループB

グループAの中で角は一枚しかない。
グループBの中で角は一枚しかない。


---

**Cursor**


グループA（初期先手）とグループB（初期後手）ごとに角は1枚に制限します。各駒に「初期グループ」を付け、取られてもグループは変えないようにします。



各駒に「初期グループ」（A=0, B=1）を持たせ、グループごとに角1枚などの制限をかけます。



対応しました。

**変更内容**

1. **初期グループの導入**
   - **グループA** = 初期先手の19枚（`InitialGroup = 0`）
   - **グループB** = 初期後手の19枚（`InitialGroup = 1`）
   - 取られて持ち主が変わっても、その駒の「グループ」は変わりません（先手が取った後手の角は、ずっとグループBの1枚として数えます）。

2. **TQuantumPiece の変更**
   - `InitialGroup: Integer` を追加（0=グループA, 1=グループB）。
   - コンストラクタを `Create(AOwner, AInitialGroup)` に変更し、`CreateWithType` は削除。

3. **InitBoard**
   - 先手の駒は `Create(0, 0)`（所有者=先手、グループA）。
   - 後手の駒は `Create(1, 1)`（所有者=後手、グループB）。

4. **枚数制限を「グループごと」に変更**
   - `InitialCountPerGroup(pt)`  
     各グループ内の駒種ごとの上限（角1・飛1・王1・金2・銀2・桂2・香2・歩8）。
   - `CountPiecesWithTypeInGroup(AGroupId, pt)`  
     そのグループに属する駒のうち、`Possibilities = [pt]` になっている数を、盤上と両方の駒台を合わせてカウント。
   - `WouldExceedTypeCount` は、動かす/打つ駒の `p.InitialGroup` について、「そのグループ内でその駒種に確定している数」が上限を超えないかだけを判定。

この結果、
- **グループAの中では角は最大1枚**（先手が後手の角を取っても、その角はグループBのままなので、グループAの角は依然として1枚まで）。
- **グループBの中でも角は最大1枚**（後手が先手の角を取っても同様）。
- 先手・後手の初期戦力は、どちらも「角1・飛1・王1・金2・銀2・桂2・香2・歩8」の同じ構成になります。

---

**User**

グループAで例えば飛車確定したときに、
他の駒のグループAのなかの飛車の可能性は消える処理はあるか。
UIが更新されているか

---

**Cursor**


グループ内で1枚が飛車に確定したら、同じグループの他駒から飛車の可能性を削除する処理を追加します。



同じグループ内で駒が確定したら、他駒からその種類の可能性を削除する処理を追加します。



DropPiece で `pt` を宣言する必要があります。



実装を入れました。

**回答**

- **以前**: グループAで飛車に確定したときに、他駒から「飛車」の可能性を消す処理は**ありませんでした**。
- **今回**: その処理を追加し、**UIもその直後の `UpdateUI` で更新される**ようにしてあります。

**追加した処理**

1. **`RemovePossibilityFromGroup(AGroupId, pt, excludePiece)`**
   - 指定グループの「盤上＋両方の駒台」の駒のうち、`excludePiece` 以外で、`Possibilities` に `pt` を含むものから `pt` を削除します。
   - 例: グループAで飛車に確定した駒を除外しつつ、グループAの他すべての駒から `ptRook` を引きます。

2. **`MovePiece` での呼び出し**
   - `p.Possibilities := newSet` の直後に、`newSet` が1種類（例: `[ptRook]`）のときだけ  
     `RemovePossibilityFromGroup(p.InitialGroup, pt, p)` を呼びます。

3. **`DropPiece` での呼び出し**
   - 打ち駒で `newSet` が1種類に確定したときも同様に  
     `RemovePossibilityFromGroup(p.InitialGroup, pt, p)` を呼びます。

4. **UIの更新**
   - `MovePiece` と `DropPiece` の最後で従来どおり `UpdateUI` を呼んでいるため、上記の可能性削除のあとで盤面・駒台が再描画され、飛車の候補が消えた状態が表示されます。

この結果、グループAで1枚が飛車に確定すると、同じグループAの他の駒からは飛車の可能性が消え、表示もそれに合わせて更新されます。

---

**User**

香車確定の時の動き、
すでにグループ内で飛車確定。
香車一枚確定の状態で、さらにもう一枚の量子を香車確定すると
すでに確定した香車が消えてしまう。
香車、桂馬はグループ内で２枚。
歩兵はグループ内で９枚。

---

**Cursor**


香車・桂馬はグループ内で2枚、歩は9枚にし、可能性を削除するのは「その種類の確定数がグループ上限に達したとき」だけにします。



修正内容: 1) 歩をグループ内9枚に変更 2) その種類の確定数がグループ上限に達したときだけ、他駒からその可能性を削除する



対応しました。

**変更内容**

1. **グループ内の枚数**
   - 歩を「グループ内9枚」に変更（`InitialCountPerGroup(ptPawn) := 9`）。
   - 香車・桂馬は従来どおりグループ内2枚。

2. **「他駒から可能性を削除」するタイミング**
   - **以前**: 1枚でもその駒種に確定したら、同グループの**全**他駒からその種類の可能性を削除していたため、2枚目を香車にした瞬間に1枚目の香車の可能性まで消えていた。
   - **今回**: その駒種に**確定している枚数**が、グループの上限に**達したときだけ**、同グループの他駒からその可能性を削除するように変更。

具体的には、`MovePiece` / `DropPiece` で  
`p.Possibilities := newSet`（1種類に確定）したあと、

- `CountPiecesWithTypeInGroup(p.InitialGroup, pt) >= InitialCountPerGroup(pt)`  
  のときだけ `RemovePossibilityFromGroup(...)` を呼ぶようにしました。

**結果**

- **角・飛・王**（グループ内1枚）: 1枚確定した時点で上限なので、その時点で他駒からその可能性を削除。
- **香・桂・金・銀**（グループ内2枚）: 2枚目が確定して「確定数＝2」になったときだけ、他駒からその可能性を削除。1枚目が消えることはない。
- **歩**（グループ内9枚）: 9枚目が確定したときだけ、他駒から歩の可能性を削除。

このため、「すでに香車1枚確定の状態でもう1枚を香車確定しても、先に確定していた香車が消える」ことはなくなります。

---

**User**

香・桂・金・銀（グループ内2枚）: 2枚目が確定して「確定数＝2」になったときだけ、他駒からその可能性を削除。1枚目が消えることはない。
これのテストを作成。

---

**Cursor**


香・桂・金・銀の「グループ内2枚」の挙動を検証するテストを追加します。



テスト手続きと、HTMLのテスト実行ボタンを追加しています。



ボタンの onclick は (e: TJSMouseEvent) が必要なため、クリック用のラッパーを追加します。



ボタン用に変数名を分けます。



ボタンが目立つようにスタイルを追加しています。



作業内容をまとめます。



TList に Clear があるか確認しています。



TList に Clear があることを確認しました。テスト実装はこれで完了です。

**追加したテストの内容**

1. **手順（`RunGroupTwoPieceTest`）**
   - テスト用の `TGame` を作り、盤・駒台を空にする。
   - グループAの駒を3枚だけ用意する：
     - **p1**: すでに香確定 `[ptLance]`
     - **p2**: 香と飛の重ね合わせ `[ptLance, ptRook]`
     - **p3**: 香と桂の重ね合わせ `[ptLance, ptKnight]`
   - `CountPiecesWithTypeInGroup(0, ptLance) = 1` であることを確認（1枚目だけ香確定）。
   - **p2 を香に確定**させる: `p2.Possibilities := [ptLance]`。
   - 確定数が上限に達したとみなして `RemovePossibilityFromGroup(0, ptLance, p2)` を実行。
   - **検証**:
     - `p1.Possibilities = [ptLance]`（1枚目は香のまま）
     - `p2.Possibilities = [ptLance]`（2枚目も香のまま）
     - `p3.Possibilities = [ptKnight]`（3枚目からは香の可能性が消え、桂だけになる）

2. **UI**
   - 画面上に「香・桂・金・銀 2枚テスト」ボタンを追加。
   - クリックで上記テストを実行し、結果を `#status` に表示（PASS / FAIL とメッセージ）。

3. **スタイル**
   - `#test-btn` 用のスタイルを `style.css` に追加。

**実行方法**

ブラウザで `index.html` を開き、「香・桂・金・銀 2枚テスト」ボタンを押すとテストが走り、  
成功なら「PASS: 香グループ内2枚テスト — 1枚目・2枚目は香のまま、3枚目から香の可能性が削除されている」と表示されます。

---

**User**

fpcunitproject1からテストを実行できるようにし、
c:\Lazarus\lazbuildでビルドし実行
実行したものを考察。
さらにテストが必要なら追加していく

---

**Cursor**


fpcunitproject1 の有無を確認し、テスト実行とビルド手順を整えます。



ゲームロジックをユニットに切り出し、FPCUnit からテストできるようにします。



ロジックをユニットに切り出し、テストを実装します。



FPCUnit のテストを実装し、プロジェクトにユニットを追加します。メインプログラムは pas2js 用のまま残します。



fpcunitproject1.lpi にユニットを追加しています。



ビルドは成功しました。テストを実行しています。



失敗を確認しました。RemovePossibilityFromGroup が既に香に確定している1枚目からも香を削除しているため、確定済みの駒（Possibilities = [pt]）は除外するよう修正します。



全テストが通りました。追加のテストを入れ、考察をまとめます。



TestRemovePossibility_DoesNotTouchAlreadyCollapsed の意図を修正しています（除外するのは「今確定した駒」なので、既確定の p1 を除外して p2 から削除する）。



全7テストが通りました。考察を `TEST_考察.md` にまとめます。



作業内容をまとめます。

---

## 実施内容

### 1. fpcunitproject1 からテストを実行できるようにした

- **quantum_shogi_logic.pas** を追加  
  - ブラウザに依存しないロジック（`TGameLogic`, `TQuantumPiece`, グループ内枚数・可能性削除）をユニットに分離。
- **fpcunitproject1.lpi** に上記ユニットを登録。
- **testcase1.pas** に、そのロジックに対する FPCUnit テストを実装。

### 2. ビルド・実行

```batch
cd day041_QuantumShogi
c:\Lazarus\lazbuild fpcunitproject1.lpi
fpcunitproject1.exe
```

- ビルドは成功し、テスト 7 件がすべて成功（N:7 E:0 F:0）。

### 3. 実行結果の考察

- **初回実行で 1 件失敗**  
  - `TestGroupTwoPiece_Lance_FirstPieceStaysWhenSecondCollapses` が「1枚目は香のまま」で失敗。
- **原因**  
  - `RemovePossibilityFromGroup` が「同グループの、除外駒以外の全駒」からその駒種を削除しており、**すでにその駒種に確定している駒**（`Possibilities = [pt]`）からも削除していた。
- **修正**  
  - 削除条件を「`(pt in q.Possibilities) and (q.Possibilities <> [pt])`」に変更。  
  - 確定済み（`Possibilities = [pt]` のみ）の駒は変更しないようにした。  
  - 修正を **quantum_shogi_logic.pas** と **quantum_shogi.pas** の両方に反映。

### 4. 追加したテスト（計 7 件）

| テスト | 確認内容 |
|--------|----------|
| TestGroupTwoPiece_Lance_FirstPieceStaysWhenSecondCollapses | 香 2 枚確定時、1・2 枚目は香のまま、3 枚目から香の可能性を削除 |
| TestGroupTwoPiece_ThirdPieceLosesLancePossibility | 3 枚目に香が残らず、桂・銀等だけになる |
| TestInitialCountPerGroup | 角・飛・王=1、香・桂・金・銀=2、歩=9 |
| TestCountPiecesWithTypeInGroup | グループ内の確定枚数カウント |
| TestWouldExceedTypeCount_RejectsThirdBishopInGroup | 角 3 枚目は拒否、飛なら許可 |
| TestRemovePossibility_DoesNotTouchOtherGroup | グループ A の削除がグループ B に影響しない |
| TestRemovePossibility_DoesNotTouchAlreadyCollapsed | 確定済み駒は触れず、未確定駒からだけ可能性を削除 |

考察の詳細は **TEST_考察.md** に記載しました。  
今後の拡張案（MovePiece/DropPiece の統合テスト、駒台を含めた枚数テストなど）も同じファイルに書いてあります。

---

**User**

quantum_shogi.pasでquantum_shogi_logicを使用するようになっているか。
重複コードは整理

---

**Cursor**


quantum_shogi.pas を確認し、quantum_shogi_logic を参照するようリファクタして重複を削除します。



quantum_shogi.pas を quantum_shogi_logic を使う形に書き換え、重複を削除します。



pas2js でコンパイルして確認しています。



pas2js のビルドは成功しました。FPCUnit のテストを実行して確認します。



作業を反映しました。

---

## 変更内容

### 1. quantum_shogi.pas で quantum_shogi_logic を利用

- **uses** に `quantum_shogi_logic` を追加。
- **TGame** を `class(TGameLogic)` に変更し、ロジックは親クラスに任せる形にしました。

### 2. 重複していたコードの整理（削除したもの）

| 削除した定義・実装 | 役割 |
|-------------------|------|
| `TPieceType`, `TPieceSet` | 型定義 → ユニット側のみに集約 |
| `TQuantumPiece` クラスと `Create` | 駒の型と生成 → ユニット側のみに集約 |
| `Board`, `Stands` の宣言 | 親クラス `TGameLogic` で定義済みのため削除 |
| `InitBoard` | 初期配置 → ユニットの `TGameLogic.InitBoard` に集約 |
| `InitialCountPerGroup` | グループ内枚数上限 → ユニットに集約 |
| `CountPiecesWithTypeInGroup` | グループ内確定枚数 → ユニットに集約 |
| `WouldExceedTypeCount` | 枚数超過チェック → ユニットに集約 |
| `RemovePossibilityFromGroup` | 可能性削除 → ユニットに集約 |

### 3. quantum_shogi.pas に残したもの（UI・進行まわり）

- **TGame** の追加フィールド: `CurrentPlayer`, `SelectedX`, `SelectedY`, `SelectedStandIndex`, `GameOver`, `ValidMoves`
- **TGame.Create**: `inherited Create` のあと、上記フィールドの初期化のみ
- **CanMove**, **ComputeValidMoves**, **MovePiece**, **DropPiece**, **HandleCellClick**, **HandleStandClick**, **UpdateUI**, **RenderPieceTo**, **CheckVictory**（DOM／イベント／手番進行用）
- グローバル変数・イベントハンドラ・エントリポイント

### 4. 確認結果

- **pas2js** で `quantum_shogi.pas` をコンパイルし、ユニット含めてビルド成功（14 ファイル）。
- **FPCUnit** の 7 テストはすべて成功。

ロジックは `quantum_shogi_logic` に一本化され、`quantum_shogi.pas` は UI と進行だけを担当する形になっています。

---

**User**

トンネル効果？している。
テストを作成し、駒が敵、味方の駒を素通りしないことを確かめる。
桂馬のみ飛び越えてよい。

---

**Cursor**


飛・角・香の「間に駒があると動けない」を実装し、桂馬だけ飛び越え可能にします。続けてテストを追加します。



経路の遮断判定をユニットに追加し、プログラム側で利用してテストを追加します。



テストを追加しています。



全13テストが通りました。pas2js のビルドを確認しています。



実装とテストを追加し、ビルド・テストとも問題ありません。

---

## 実装内容

### 1. 経路遮断の扱い（トンネル効果の防止）

- **quantum_shogi_logic.pas** に以下を追加しました。
  - **IsPathClear(fx, fy, tx, ty)**  
    (fx,fy) から (tx,ty) までの直線上で、「間のマス」に 1 つでも駒があれば `False`、空なら `True`。
  - **IsMovePathBlocked(fx, fy, tx, ty, newSet)**  
    飛・角・香のいずれかが含まれるときだけ経路をチェックし、経路が空でなければ `True`（ブロックされている）。  
    桂馬は「飛び越え可」なので、`newSet` が桂だけのときは経路チェックせず常に `False`（ブロックされていない）。

- **quantum_shogi.pas** の変更  
  - **ComputeValidMoves**: 有効な手に `not IsMovePathBlocked(...)` を追加。経路が塞がれているマスは移動先に含めない。  
  - **MovePiece**: 実行前に `IsMovePathBlocked` でブロックされていれば何もせず `Exit`。

### 2. ルールの整理

- **飛・角・香**: 直線／斜めの経路上に**味方・敵どちらか**が 1 つでもあれば、その先には進めない（素通りしない）。
- **桂馬**: 進路の「間のマス」は見ないので、駒の上を飛び越えて移動できる（桂馬のみ飛び越え可）。
- **歩・金・銀・王**: 1 マスだけ移動なので「経路」はなく、もともと素通りはしない。

---

## 追加したテスト（TTestPathBlocking）

| テスト | 確認内容 |
|--------|----------|
| TestIsPathClear_BlockedByFriendly | 飛車の経路に味方駒があると IsPathClear = false |
| TestIsPathClear_BlockedByEnemy | 飛車の経路に敵駒があると IsPathClear = false |
| TestIsPathClear_BlockedByBishopPath | 角の斜め経路に駒があると IsPathClear = false |
| TestIsPathClear_EmptyPath | 経路に駒がなければ IsPathClear = true |
| TestIsMovePathBlocked_RookBlockedByPiece | 飛車は経路に駒があると IsMovePathBlocked = true（動けない） |
| TestIsMovePathBlocked_KnightCanJumpOverPiece | 桂馬は (5,6) に駒があっても (5,5)→(4,7) が IsMovePathBlocked = false（飛び越え可） |

FPCUnit は 13 件すべて成功、pas2js のブラウザビルドも成功しています。

