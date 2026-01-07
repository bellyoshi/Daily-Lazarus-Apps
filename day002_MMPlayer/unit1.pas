unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Menus, ExtCtrls, MMSystem;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuOpen: TMenuItem;
    MenuSeparator1: TMenuItem;
    MenuExit: TMenuItem;
    MenuControl: TMenuItem;
    MenuPlay: TMenuItem;
    MenuPause: TMenuItem;
    MenuStop: TMenuItem;
    TrackBar1: TTrackBar;
    BtnPlay: TButton;
    BtnPause: TButton;
    BtnStop: TButton;
    OpenDialog1: TOpenDialog;
    Timer1: TTimer;
    Label1: TLabel;
    LabelPosition: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure BtnPlayClick(Sender: TObject);
    procedure BtnPauseClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FMidiFileName: string;
    FMidiDevice: MCIDEVICEID;
    FIsPlaying: Boolean;
    FIsPaused: Boolean;
    FTotalLength: LongInt;
    FUpdatingTrackBar: Boolean; // ループ防止用フラグ
    procedure OpenMidiFile(const FileName: string);
    procedure CloseMidiFile;
    procedure UpdatePosition;
    function GetMidiLength: LongInt;
    function GetMidiPosition: LongInt;
    procedure SetMidiPosition(Pos: LongInt);
    function FormatTime(ms: LongInt): string;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  FMidiFileName := '';
  FMidiDevice := 0;
  FIsPlaying := False;
  FIsPaused := False;
  FTotalLength := 0;
  FUpdatingTrackBar := False;
  TrackBar1.Max := 1000;
  TrackBar1.Position := 0;
  Timer1.Interval := 100;
  Timer1.Enabled := False;
  Label1.Caption := 'ファイルを選択してください';
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseMidiFile;
end;

procedure TForm1.MenuOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    OpenMidiFile(OpenDialog1.FileName);
  end;
end;

procedure TForm1.MenuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.BtnPlayClick(Sender: TObject);
var
  mciPlay: MCI_PLAY_PARMS;
  Result: MCIERROR;
begin
  if FMidiDevice = 0 then
  begin
    if FMidiFileName <> '' then OpenMidiFile(FMidiFileName)
    else begin MenuOpenClick(nil); Exit; end;
  end;

  // 再開・新規再生共通
  FillChar(mciPlay, SizeOf(mciPlay), 0);
  Result := mciSendCommand(FMidiDevice, MCI_PLAY, 0, LongWord(@mciPlay));

  if Result = 0 then
  begin
    FIsPlaying := True;
    FIsPaused := False;
    Timer1.Enabled := True;
  end;
end;

procedure TForm1.BtnPauseClick(Sender: TObject);
begin
  if (FMidiDevice <> 0) and FIsPlaying then
  begin
    if mciSendCommand(FMidiDevice, MCI_PAUSE, 0, 0) = 0 then
    begin
      FIsPlaying := False;
      FIsPaused := True;
      Timer1.Enabled := False;
    end;
  end;
end;

procedure TForm1.BtnStopClick(Sender: TObject);
var
  mciSeek: MCI_SEEK_PARMS;
begin
  if FMidiDevice <> 0 then
  begin
    mciSendCommand(FMidiDevice, MCI_STOP, 0, 0);
    FillChar(mciSeek, SizeOf(mciSeek), 0);
    mciSeek.dwTo := 0;
    mciSendCommand(FMidiDevice, MCI_SEEK, MCI_TO, LongWord(@mciSeek));

    FIsPlaying := False;
    FIsPaused := False;
    Timer1.Enabled := False;

    FUpdatingTrackBar := True;
    TrackBar1.Position := 0;
    FUpdatingTrackBar := False;
    UpdatePosition;
  end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
var
  NewPos: LongInt;
begin
  // タイマー更新中、またはデバイス未設定なら何もしない
  if FUpdatingTrackBar or (FMidiDevice = 0) then Exit;

  // ユーザー操作によるシーク
  NewPos := Round((TrackBar1.Position / 1000.0) * FTotalLength);
  SetMidiPosition(NewPos);

  // シーク後は再生が止まる場合があるため、再生中ならPLAYコマンドを再送
  if FIsPlaying then
    BtnPlayClick(nil);

  UpdatePosition;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  UpdatePosition;
end;

procedure TForm1.OpenMidiFile(const FileName: string);
var
  mciOpen: MCI_OPEN_PARMS;
  mciSet: MCI_SET_PARMS;
  Result: MCIERROR;
begin
  CloseMidiFile;

  FillChar(mciOpen, SizeOf(mciOpen), 0);
  mciOpen.lpstrDeviceType := 'sequencer';
  mciOpen.lpstrElementName := PChar(FileName);
  Result := mciSendCommand(0, MCI_OPEN, MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, LongWord(@mciOpen));

  if Result = 0 then
  begin
    FMidiDevice := mciOpen.wDeviceID;
    FMidiFileName := FileName;

    // 時間単位をミリ秒に設定（重要）
    FillChar(mciSet, SizeOf(mciSet), 0);
    mciSet.dwTimeFormat := MCI_FORMAT_MILLISECONDS;
    mciSendCommand(FMidiDevice, MCI_SET, MCI_SET_TIME_FORMAT, LongWord(@mciSet));

    FTotalLength := GetMidiLength;
    Label1.Caption := ExtractFileName(FileName);
    UpdatePosition;
  end;
end;

procedure TForm1.CloseMidiFile;
begin
  if FMidiDevice <> 0 then
  begin
    mciSendCommand(FMidiDevice, MCI_CLOSE, 0, 0);
    FMidiDevice := 0;
  end;
  Timer1.Enabled := False;
  FIsPlaying := False;
end;

procedure TForm1.UpdatePosition;
var
  CurrentPos: LongInt;
  mciStatus: MCI_STATUS_PARMS;
begin
  if FMidiDevice = 0 then Exit;

  CurrentPos := GetMidiPosition;

  // TrackBarChangeイベントが発火しないようフラグを立てる
  FUpdatingTrackBar := True;
  try
    if FTotalLength > 0 then
      TrackBar1.Position := Round((CurrentPos / FTotalLength) * 1000);
    LabelPosition.Caption := FormatTime(CurrentPos) + ' / ' + FormatTime(FTotalLength);
  finally
    FUpdatingTrackBar := False;
  end;

  // 再生終了チェック
  FillChar(mciStatus, SizeOf(mciStatus), 0);
  mciStatus.dwItem := MCI_STATUS_MODE;
  if mciSendCommand(FMidiDevice, MCI_STATUS, MCI_STATUS_ITEM, LongWord(@mciStatus)) = 0 then
  begin
    if (mciStatus.dwReturn = MCI_MODE_STOP) and FIsPlaying then
    begin
      FIsPlaying := False;
      Timer1.Enabled := False;
    end;
  end;
end;

function TForm1.GetMidiLength: LongInt;
var
  mciStatus: MCI_STATUS_PARMS;
begin
  FillChar(mciStatus, SizeOf(mciStatus), 0);
  mciStatus.dwItem := MCI_STATUS_LENGTH;
  mciSendCommand(FMidiDevice, MCI_STATUS, MCI_STATUS_ITEM, LongWord(@mciStatus));
  Result := mciStatus.dwReturn;
end;

function TForm1.GetMidiPosition: LongInt;
var
  mciStatus: MCI_STATUS_PARMS;
begin
  FillChar(mciStatus, SizeOf(mciStatus), 0);
  mciStatus.dwItem := MCI_STATUS_POSITION;
  mciSendCommand(FMidiDevice, MCI_STATUS, MCI_STATUS_ITEM, LongWord(@mciStatus));
  Result := mciStatus.dwReturn;
end;

procedure TForm1.SetMidiPosition(Pos: LongInt);
var
  mciSeek: MCI_SEEK_PARMS;
begin
  if FMidiDevice = 0 then Exit;
  FillChar(mciSeek, SizeOf(mciSeek), 0);
  mciSeek.dwTo := Pos;
  mciSendCommand(FMidiDevice, MCI_SEEK, MCI_TO, LongWord(@mciSeek));
end;

function TForm1.FormatTime(ms: LongInt): string;
var
  S: Integer;
begin
  S := ms div 1000;
  Result := Format('%.2d:%.2d', [S div 60, S mod 60]);
end;

end.
