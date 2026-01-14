unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Game3mokuUnit, AI3mokuUnit;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    LabelStatus: TLabel;
    ButtonReset: TButton;
    ButtonStart: TButton;
    RadioGroupOrder: TRadioGroup;
    ComboBoxLevel: TComboBox;
    LabelLevel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
    procedure ButtonResetClick(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
  private
    FGame: TGame3moku;
    FLevel1AI: TLevel1AI;
    FLevel2AI: TLevel2AI;
    FLevel3AI: TLevel3AI;
    FCurrentAILevel: Integer;
    FPlayerIsFirst: Boolean;
    FGameStarted: Boolean;
    procedure UpdateBoard;
    procedure UpdateStatus;
    procedure StartGame;
    procedure EnableGameBoard(AEnabled: Boolean);
    function GetButtonIndex(Row, Col: Integer): Integer;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FGame := TGame3moku.Create;
  FLevel1AI := TLevel1AI.Create;
  FLevel2AI := TLevel2AI.Create;
  FLevel3AI := TLevel3AI.Create;
  FCurrentAILevel := 1;
  FGameStarted := False;
  FPlayerIsFirst := True;
  EnableGameBoard(False);
  LabelStatus.Caption := 'ゲームを開始してください';
  
  // ComboBoxにレベルを追加
  ComboBoxLevel.Items.Clear;
  ComboBoxLevel.Items.Add('Level 1（ランダム）');
  ComboBoxLevel.Items.Add('Level 2（妨害）');
  ComboBoxLevel.Items.Add('Level 3（勝利優先）');
  ComboBoxLevel.ItemIndex := 0;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FLevel3AI.Free;
  FLevel2AI.Free;
  FLevel1AI.Free;
  FGame.Free;
end;

procedure TForm1.ButtonClick(Sender: TObject);
var
  Button: TButton;
  Index, Row, Col: Integer;
  AICol, AIRow: Integer;
  CurrentPlayer: TPlayer;
begin
  if not (Sender is TButton) then
    Exit;

  if not FGameStarted then
    Exit;

  Button := TButton(Sender);
  Index := Button.Tag;

  // タグから行と列を計算
  Row := Index div 3;
  Col := Index mod 3;

  // 現在のプレイヤーを確認
  CurrentPlayer := FGame.GetCurrentPlayer;
  
  // プレイヤーが先手ならX、後手ならOのみ手を打てる
  if FPlayerIsFirst and (CurrentPlayer <> pX) then
    Exit;
  if not FPlayerIsFirst and (CurrentPlayer <> pO) then
    Exit;

  // 手を打つ
  if FGame.MakeMove(Row, Col) then
  begin
    UpdateBoard;
    UpdateStatus;

    // ゲームが続いている場合、AIの手を打つ
    if FGame.GetGameState = gsPlaying then
    begin
      if FCurrentAILevel = 1 then
      begin
        if FLevel1AI.GetMove(FGame, AIRow, AICol) then
        begin
          FGame.MakeMove(AIRow, AICol);
          UpdateBoard;
          UpdateStatus;
        end;
      end
      else if FCurrentAILevel = 2 then
      begin
        if FLevel2AI.GetMove(FGame, AIRow, AICol) then
        begin
          FGame.MakeMove(AIRow, AICol);
          UpdateBoard;
          UpdateStatus;
        end;
      end
      else
      begin
        if FLevel3AI.GetMove(FGame, AIRow, AICol) then
        begin
          FGame.MakeMove(AIRow, AICol);
          UpdateBoard;
          UpdateStatus;
        end;
      end;
    end;
  end;
end;

procedure TForm1.ButtonResetClick(Sender: TObject);
begin
  FGame.Reset;
  FGameStarted := False;
  EnableGameBoard(False);
  LabelStatus.Caption := 'ゲームを開始してください';
  RadioGroupOrder.Visible := True;
  ComboBoxLevel.Visible := True;
  LabelLevel.Visible := True;
  ButtonStart.Visible := True;
end;

procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  StartGame;
end;

procedure TForm1.StartGame;
var
  AIRow, AICol: Integer;
begin
  // 先手/後手を決定
  FPlayerIsFirst := (RadioGroupOrder.ItemIndex = 0);
  
  // AIレベルを決定
  FCurrentAILevel := ComboBoxLevel.ItemIndex + 1;
  
  // ゲームをリセット
  FGame.Reset;
  
  // プレイヤーが後手の場合、ゲームの最初のプレイヤーをOに変更する必要がある
  // ただし、TGame3mokuは常にXから始まるので、後手の場合はAIが最初に手を打つ
  if not FPlayerIsFirst then
  begin
    // AIが最初に手を打つ
    if FCurrentAILevel = 1 then
    begin
      if FLevel1AI.GetMove(FGame, AIRow, AICol) then
        FGame.MakeMove(AIRow, AICol);
    end
    else if FCurrentAILevel = 2 then
    begin
      if FLevel2AI.GetMove(FGame, AIRow, AICol) then
        FGame.MakeMove(AIRow, AICol);
    end
    else
    begin
      if FLevel3AI.GetMove(FGame, AIRow, AICol) then
        FGame.MakeMove(AIRow, AICol);
    end;
  end;
  
  FGameStarted := True;
  EnableGameBoard(True);
  RadioGroupOrder.Visible := False;
  ComboBoxLevel.Visible := False;
  LabelLevel.Visible := False;
  ButtonStart.Visible := False;
  UpdateBoard;
  UpdateStatus;
end;

procedure TForm1.EnableGameBoard(AEnabled: Boolean);
var
  i: Integer;
  Button: TButton;
begin
  for i := 1 to 9 do
  begin
    Button := TButton(FindComponent('Button' + IntToStr(i)));
    if Assigned(Button) then
      Button.Enabled := AEnabled;
  end;
end;

procedure TForm1.UpdateBoard;
var
  i, j: Integer;
  Button: TButton;
  Player: TPlayer;
begin
  for i := 0 to 2 do
    for j := 0 to 2 do
    begin
      Button := TButton(FindComponent('Button' + IntToStr(i * 3 + j + 1)));
      if Assigned(Button) then
      begin
        Player := FGame.GetCell(i, j);
        case Player of
          pNone: Button.Caption := '';
          pX: Button.Caption := 'X';
          pO: Button.Caption := 'O';
        end;
        Button.Enabled := (Player = pNone) and (FGame.GetGameState = gsPlaying);
      end;
    end;
end;

procedure TForm1.UpdateStatus;
var
  State: TGameState;
  CurrentPlayer: TPlayer;
begin
  if not FGameStarted then
    Exit;

  State := FGame.GetGameState;
  CurrentPlayer := FGame.GetCurrentPlayer;

  case State of
    gsPlaying:
      begin
        if (FPlayerIsFirst and (CurrentPlayer = pX)) or 
           (not FPlayerIsFirst and (CurrentPlayer = pO)) then
          LabelStatus.Caption := 'あなたの番'
        else
          LabelStatus.Caption := 'AIの番';
      end;
    gsXWon: 
      begin
        if FPlayerIsFirst then
          LabelStatus.Caption := 'あなたの勝利！'
        else
          LabelStatus.Caption := 'AIの勝利！';
      end;
    gsOWon: 
      begin
        if not FPlayerIsFirst then
          LabelStatus.Caption := 'あなたの勝利！'
        else
          LabelStatus.Caption := 'AIの勝利！';
      end;
    gsDraw: LabelStatus.Caption := '引き分け';
  end;
end;

function TForm1.GetButtonIndex(Row, Col: Integer): Integer;
begin
  Result := Row * 3 + Col;
end;

end.
