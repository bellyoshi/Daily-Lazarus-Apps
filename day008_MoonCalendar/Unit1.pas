unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  ExtCtrls, DateUtils, IniFiles, Math;

type
  TMoonPhase = (mpNewMoon, mpWaxingCrescent, mpFirstQuarter, mpWaxingGibbous,
                mpFullMoon, mpWaningGibbous, mpLastQuarter, mpWaningCrescent);

  { TForm1 }

  TForm1 = class(TForm)
    CalendarGrid: TStringGrid;
    MonthLabel: TLabel;
    PrevMonthBtn: TButton;
    NextMonthBtn: TButton;
    MemoLabel: TLabel;
    MemoEdit: TMemo;
    MoonInfoLabel: TLabel;
    SaveTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure CalendarGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure CalendarGridSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure PrevMonthBtnClick(Sender: TObject);
    procedure NextMonthBtnClick(Sender: TObject);
    procedure MemoEditChange(Sender: TObject);
    procedure SaveTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    FCurrentDate: TDateTime;
    FSelectedDate: TDateTime;
    FDataFile: string;
    procedure UpdateCalendar;
    function GetMoonAge(ADate: TDateTime): Double;
    function GetMoonPhase(AMoonAge: Double): TMoonPhase;
    function GetMoonPhaseIcon(APhase: TMoonPhase): string;
    function GetMoonPhaseName(APhase: TMoonPhase): string;
    function GetMoonPhaseDescription(APhase: TMoonPhase; AMoonAge: Double): string;
    procedure LoadMemoForDate(ADate: TDateTime);
    procedure SaveMemoForDate(ADate: TDateTime; const AMemo: string);
    procedure AutoSave;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FCurrentDate := Now;
  FSelectedDate := Now;
  FDataFile := ExtractFilePath(Application.ExeName) + 'mooncalendar_data.ini';
  
  CalendarGrid.ColCount := 7;
  CalendarGrid.RowCount := 7;
  CalendarGrid.FixedCols := 0;
  CalendarGrid.FixedRows := 1;
  CalendarGrid.DefaultColWidth := 80;
  CalendarGrid.DefaultRowHeight := 60;
  CalendarGrid.Options := CalendarGrid.Options + [goDrawFocusSelected];
  
  // 曜日ヘッダー
  CalendarGrid.Cells[0, 0] := '日';
  CalendarGrid.Cells[1, 0] := '月';
  CalendarGrid.Cells[2, 0] := '火';
  CalendarGrid.Cells[3, 0] := '水';
  CalendarGrid.Cells[4, 0] := '木';
  CalendarGrid.Cells[5, 0] := '金';
  CalendarGrid.Cells[6, 0] := '土';
  
  UpdateCalendar;
  LoadMemoForDate(FSelectedDate);
  
  SaveTimer.Interval := 2000; // 2秒後に自動保存
  SaveTimer.Enabled := True;
end;

procedure TForm1.UpdateCalendar;
var
  Year, Month, Day: Word;
  FirstDay, LastDay: TDateTime;
  StartDate: TDateTime;
  i, j, DayNum: Integer;
  CellDate: TDateTime;
begin
  DecodeDate(FCurrentDate, Year, Month, Day);
  MonthLabel.Caption := Format('%d年%d月', [Year, Month]);
  
  FirstDay := EncodeDate(Year, Month, 1);
  LastDay := EndOfAMonth(Year, Month);
  
  // 月の最初の日が何曜日か（0=日曜日）
  StartDate := FirstDay - DayOfWeek(FirstDay) + 1;
  
  DayNum := 1;
  for i := 1 to 6 do
  begin
    for j := 0 to 6 do
    begin
      CellDate := StartDate + (i - 1) * 7 + j;
      if (CellDate >= FirstDay) and (CellDate <= LastDay) then
      begin
        CalendarGrid.Cells[j, i] := IntToStr(DayNum);
        Inc(DayNum);
      end
      else
        CalendarGrid.Cells[j, i] := '';
    end;
  end;
  
  CalendarGrid.Invalidate;
end;

function TForm1.GetMoonAge(ADate: TDateTime): Double;
var
  Year, Month, Day: Word;
  C: Integer;
begin
  // グレゴリオ暦での月齢計算式（2000年以降）
  // C=((Y-2009)%19)×11+M+D
  // 1月,2月の場合にはさらに2を加える
  // Cを30で割った余りが月齢A
  DecodeDate(ADate, Year, Month, Day);
  
  // C=((Y-2009)%19)×11+M+D
  C := ((Year - 2009) mod 19) * 11 + Month + Day;
  
  // 1月,2月の場合にはさらに2を加える
  if (Month = 1) or (Month = 2) then
    C := C + 2;
  
  // Cを30で割った余りが月齢
  Result := C mod 30;
  
  // 負の値になる場合は30を加える
  if Result < 0 then
    Result := Result + 30;
end;

function TForm1.GetMoonPhase(AMoonAge: Double): TMoonPhase;
const
  Phase1 = 1.84;   // 新月から三日月まで
  Phase2 = 5.53;   // 三日月から上弦まで
  Phase3 = 9.22;   // 上弦から十三夜まで
  Phase4 = 12.91;  // 十三夜から満月まで
  Phase5 = 16.61;  // 満月から十六夜まで
  Phase6 = 20.30;  // 十六夜から下弦まで
  Phase7 = 23.99;  // 下弦から有明まで
begin
  if (AMoonAge < Phase1) or (AMoonAge >= 29.53 - Phase1) then
    Result := mpNewMoon
  else if AMoonAge < Phase2 then
    Result := mpWaxingCrescent
  else if AMoonAge < Phase3 then
    Result := mpFirstQuarter
  else if AMoonAge < Phase4 then
    Result := mpWaxingGibbous
  else if AMoonAge < Phase5 then
    Result := mpFullMoon
  else if AMoonAge < Phase6 then
    Result := mpWaningGibbous
  else if AMoonAge < Phase7 then
    Result := mpLastQuarter
  else
    Result := mpWaningCrescent;
end;

function TForm1.GetMoonPhaseIcon(APhase: TMoonPhase): string;
begin
  case APhase of
    mpNewMoon: Result := '🌑';
    mpWaxingCrescent: Result := '🌒';
    mpFirstQuarter: Result := '🌓';
    mpWaxingGibbous: Result := '🌔';
    mpFullMoon: Result := '🌕';
    mpWaningGibbous: Result := '🌖';
    mpLastQuarter: Result := '🌗';
    mpWaningCrescent: Result := '🌘';
  end;
end;

function TForm1.GetMoonPhaseName(APhase: TMoonPhase): string;
begin
  case APhase of
    mpNewMoon: Result := '新月';
    mpWaxingCrescent: Result := '三日月';
    mpFirstQuarter: Result := '上弦の月';
    mpWaxingGibbous: Result := '十三夜';
    mpFullMoon: Result := '満月';
    mpWaningGibbous: Result := '十六夜';
    mpLastQuarter: Result := '下弦の月';
    mpWaningCrescent: Result := '有明の月';
  end;
end;

function TForm1.GetMoonPhaseDescription(APhase: TMoonPhase; AMoonAge: Double): string;
begin
  Result := Format('%s (月齢: %.1f日)', [GetMoonPhaseName(APhase), AMoonAge]);
  case APhase of
    mpNewMoon: Result := Result + #13#10 + '新しい始まりの時期。願い事を書き出すのに最適です。';
    mpFullMoon: Result := Result + #13#10 + '満月の日。感情が高まり、達成感を感じやすい時期です。';
    mpWaxingCrescent: Result := Result + #13#10 + '月が成長していく時期。新しいことに挑戦するのに適しています。';
    mpWaningCrescent: Result := Result + #13#10 + '月が欠けていく時期。整理整頓や見直しに適しています。';
    else Result := Result + #13#10 + '月のサイクルに合わせて過ごしてみましょう。';
  end;
end;

procedure TForm1.CalendarGridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Year, Month, Day: Word;
  FirstDay, LastDay: TDateTime;
  StartDate, CellDate: TDateTime;
  DayNum: Integer;
  MoonAge: Double;
  Phase: TMoonPhase;
  MoonIcon: string;
  IsToday, IsFullOrNew: Boolean;
  TextRect: TRect;
  OldFontSize: Integer;
begin
  if aRow = 0 then
  begin
    // ヘッダー行
    CalendarGrid.Canvas.Brush.Color := clBtnFace;
    CalendarGrid.Canvas.FillRect(aRect);
    CalendarGrid.Canvas.Font.Style := [fsBold];
    CalendarGrid.Canvas.TextOut(aRect.Left + (aRect.Right - aRect.Left - CalendarGrid.Canvas.TextWidth(CalendarGrid.Cells[aCol, aRow])) div 2,
                                 aRect.Top + 5, CalendarGrid.Cells[aCol, aRow]);
    CalendarGrid.Canvas.Font.Style := [];
    Exit;
  end;
  
  DecodeDate(FCurrentDate, Year, Month, Day);
  FirstDay := EncodeDate(Year, Month, 1);
  LastDay := EndOfAMonth(Year, Month);
  
  StartDate := FirstDay - DayOfWeek(FirstDay) + 1;
  CellDate := StartDate + (aRow - 1) * 7 + aCol;
  
  if (CellDate >= FirstDay) and (CellDate <= LastDay) then
  begin
    DayNum := DayOf(CellDate);
    MoonAge := GetMoonAge(CellDate);
    Phase := GetMoonPhase(MoonAge);
    MoonIcon := GetMoonPhaseIcon(Phase);
    IsToday := SameDate(CellDate, Now);
    IsFullOrNew := (Phase = mpFullMoon) or (Phase = mpNewMoon);
    
    // 背景色
    if IsToday then
      CalendarGrid.Canvas.Brush.Color := $CCFFFF  // 薄い黄色
    else if IsFullOrNew then
      CalendarGrid.Canvas.Brush.Color := $FFE0E0  // 薄いピンク
    else
      CalendarGrid.Canvas.Brush.Color := clWhite;
    
    CalendarGrid.Canvas.FillRect(aRect);
    
    // 枠線
    if IsToday then
      CalendarGrid.Canvas.Pen.Color := clBlue
    else
      CalendarGrid.Canvas.Pen.Color := clGray;
    CalendarGrid.Canvas.Pen.Width := IfThen(IsToday, 2, 1);
    CalendarGrid.Canvas.Rectangle(aRect);
    
    // 日付
    OldFontSize := CalendarGrid.Canvas.Font.Size;
    CalendarGrid.Canvas.Font.Size := 10;
    CalendarGrid.Canvas.Font.Style := [fsBold];
    TextRect := Rect(aRect.Left + 3, aRect.Top + 3, aRect.Right - 3, aRect.Top + 20);
    CalendarGrid.Canvas.TextRect(TextRect, TextRect.Left, TextRect.Top, IntToStr(DayNum));
    
    // 月相アイコン
    CalendarGrid.Canvas.Font.Size := 20;
    TextRect := Rect(aRect.Left, aRect.Top + 20, aRect.Right, aRect.Top + 45);
    CalendarGrid.Canvas.TextRect(TextRect, 
      TextRect.Left + (TextRect.Right - TextRect.Left - CalendarGrid.Canvas.TextWidth(MoonIcon)) div 2,
      TextRect.Top, MoonIcon);
    
    // 月齢
    CalendarGrid.Canvas.Font.Size := 8;
    CalendarGrid.Canvas.Font.Style := [];
    TextRect := Rect(aRect.Left + 3, aRect.Top + 45, aRect.Right - 3, aRect.Bottom - 3);
    CalendarGrid.Canvas.TextRect(TextRect, TextRect.Left, TextRect.Top, Format('%.1f日', [MoonAge]));
    
    CalendarGrid.Canvas.Font.Size := OldFontSize;
  end
  else
  begin
    // 月外のセル
    CalendarGrid.Canvas.Brush.Color := clBtnFace;
    CalendarGrid.Canvas.FillRect(aRect);
  end;
end;

procedure TForm1.CalendarGridSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
var
  Year, Month, Day: Word;
  FirstDay, LastDay: TDateTime;
  StartDate, CellDate: TDateTime;
  MoonAge: Double;
  Phase: TMoonPhase;
begin
  if aRow = 0 then
  begin
    CanSelect := False;
    Exit;
  end;
  
  DecodeDate(FCurrentDate, Year, Month, Day);
  FirstDay := EncodeDate(Year, Month, 1);
  LastDay := EndOfAMonth(Year, Month);
  
  StartDate := FirstDay - DayOfWeek(FirstDay) + 1;
  CellDate := StartDate + (aRow - 1) * 7 + aCol;
  
  if (CellDate >= FirstDay) and (CellDate <= LastDay) then
  begin
    FSelectedDate := CellDate;
    MoonAge := GetMoonAge(CellDate);
    Phase := GetMoonPhase(MoonAge);
    MoonInfoLabel.Caption := GetMoonPhaseDescription(Phase, MoonAge);
    LoadMemoForDate(CellDate);
  end
  else
    CanSelect := False;
end;

procedure TForm1.PrevMonthBtnClick(Sender: TObject);
begin
  FCurrentDate := IncMonth(FCurrentDate, -1);
  UpdateCalendar;
end;

procedure TForm1.NextMonthBtnClick(Sender: TObject);
begin
  FCurrentDate := IncMonth(FCurrentDate, 1);
  UpdateCalendar;
end;

procedure TForm1.MemoEditChange(Sender: TObject);
begin
  // タイマーをリセットして自動保存を遅延
  SaveTimer.Enabled := False;
  SaveTimer.Enabled := True;
end;

procedure TForm1.SaveTimerTimer(Sender: TObject);
begin
  AutoSave;
  SaveTimer.Enabled := False;
end;

procedure TForm1.AutoSave;
begin
  SaveMemoForDate(FSelectedDate, MemoEdit.Text);
end;

procedure TForm1.LoadMemoForDate(ADate: TDateTime);
var
  IniFile: TIniFile;
  DateStr: string;
begin
  DateStr := FormatDateTime('yyyy-mm-dd', ADate);
  IniFile := TIniFile.Create(FDataFile);
  try
    MemoEdit.Text := IniFile.ReadString('Memos', DateStr, '');
  finally
    IniFile.Free;
  end;
end;

procedure TForm1.SaveMemoForDate(ADate: TDateTime; const AMemo: string);
var
  IniFile: TIniFile;
  DateStr: string;
begin
  DateStr := FormatDateTime('yyyy-mm-dd', ADate);
  IniFile := TIniFile.Create(FDataFile);
  try
    if AMemo <> '' then
      IniFile.WriteString('Memos', DateStr, AMemo)
    else
      IniFile.DeleteKey('Memos', DateStr);
  finally
    IniFile.Free;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  AutoSave; // 終了時に保存
end;

end.
