unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    SaveDialog1: TSaveDialog;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

procedure CreateKaeruNoGassho(const FileName: string);

implementation

{$R *.lfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  SaveDialog1.Filter := 'MIDI files (*.mid)|*.mid|All files (*.*)|*.*';
  SaveDialog1.DefaultExt := 'mid';
  SaveDialog1.FileName := 'kaeru_no_gassho.mid';
  if SaveDialog1.Execute then
  begin
    CreateKaeruNoGassho(SaveDialog1.FileName);
    ShowMessage('MIDIファイルを保存しました: ' + SaveDialog1.FileName);
  end;
end;

procedure CreateKaeruNoGassho(const FileName: string);
var
  Midi: TStringStream; // 簡易的にバイナリを貯めるストリーム
  
  // ヘルパー：ビッグエンディアンで数値を書き込む
  procedure WriteIntBE(Value: Cardinal; Size: Integer);
  var
    i: Integer;
  begin
    for i := Size - 1 downto 0 do
      Midi.WriteByte((Value shr (i * 8)) and $FF);
  end;

  // ヘルパー：可変長数値（デルタタイム用）
  procedure WriteVarLen(Value: Cardinal);
  var
    Buffer: Cardinal;
  begin
    Buffer := Value and $7F;
    while (Value > $7F) do begin
      Value := Value shr 7;
      Buffer := (Buffer shl 8) or $80 or (Value and $7F);
    end;
    while True do begin
      Midi.WriteByte(Buffer and $FF);
      if (Buffer and $80) <> 0 then Buffer := Buffer shr 8
      else Break;
    end;
  end;

  // ノート追加（デルタタイム, ノート番号, ベロシティ）
  procedure AddNote(Delta: Cardinal; Note: Byte; Velocity: Byte; IsOn: Boolean);
  begin
    WriteVarLen(Delta);
    if IsOn then Midi.WriteByte($90) else Midi.WriteByte($80);
    Midi.WriteByte(Note);
    Midi.WriteByte(Velocity);
  end;

var
  TrackStartPos: Integer;
  TrackLen: Cardinal;
begin
  Midi := TStringStream.Create('');
  try
    // --- ヘッダチャンク ---
    Midi.WriteString('MThd');
    WriteIntBE(6, 4);       // 長さ
    WriteIntBE(0, 2);       // フォーマット0
    WriteIntBE(1, 2);       // トラック数1
    WriteIntBE(480, 2);     // 分解能 (四分音符=480)

    // --- トラックチャンク ---
    Midi.WriteString('MTrk');
    TrackStartPos := Midi.Position;
    WriteIntBE(0, 4);       // ダミーの長さ

    // カエルの歌の完全なメロディー
    // MIDIノート番号: ド(60), レ(62), ミ(64), ファ(65), ファ#(66), ソ(67), ラ(69)
    // 四分音符=480ティック、二分音符=960ティック
    
    // 1. どれみふぁみれどー
    AddNote(0, 60, 100, True);  AddNote(480, 60, 0, False);  // ド
    AddNote(0, 62, 100, True);  AddNote(480, 62, 0, False);  // レ
    AddNote(0, 64, 100, True);  AddNote(480, 64, 0, False);  // ミ
    AddNote(0, 65, 100, True);  AddNote(480, 65, 0, False);  // ファ
    AddNote(0, 64, 100, True);  AddNote(480, 64, 0, False);  // ミ
    AddNote(0, 62, 100, True);  AddNote(480, 62, 0, False);  // レ
    AddNote(0, 60, 100, True);  AddNote(960, 60, 0, False);  // どー（長い音符）
    
    // 2. みふぁそらそふぁみー
    AddNote(0, 64, 100, True);  AddNote(480, 64, 0, False);  // ミ
    AddNote(0, 65, 100, True);  AddNote(480, 65, 0, False);  // ファ
    AddNote(0, 67, 100, True);  AddNote(480, 67, 0, False);  // ソ
    AddNote(0, 69, 100, True);  AddNote(480, 69, 0, False);  // ラ
    AddNote(0, 67, 100, True);  AddNote(480, 67, 0, False);  // ソ
    AddNote(0, 65, 100, True);  AddNote(480, 65, 0, False);  // ファ
    AddNote(0, 64, 100, True);  AddNote(960, 64, 0, False);  // みー（長い音符）
    
    // 3. どー、どー、どー、どー
    AddNote(0, 60, 100, True);  AddNote(960, 60, 0, False);  // どー
    AddNote(0, 60, 100, True);  AddNote(960, 60, 0, False);  // どー
    AddNote(0, 60, 100, True);  AddNote(960, 60, 0, False);  // どー
    AddNote(0, 60, 100, True);  AddNote(960, 60, 0, False);  // どー
    
    // 4. ドドレレミミファファ（すべて八分音符）
    AddNote(0, 60, 100, True);  AddNote(240, 60, 0, False);  // ド（八分音符）
    AddNote(0, 60, 100, True);  AddNote(240, 60, 0, False);  // ド（八分音符）
    AddNote(0, 62, 100, True);  AddNote(240, 62, 0, False);  // レ（八分音符）
    AddNote(0, 62, 100, True);  AddNote(240, 62, 0, False);  // レ（八分音符）
    AddNote(0, 64, 100, True);  AddNote(240, 64, 0, False);  // ミ（八分音符）
    AddNote(0, 64, 100, True);  AddNote(240, 64, 0, False);  // ミ（八分音符）
    AddNote(0, 65, 100, True);  AddNote(240, 65, 0, False);  // ファ（八分音符）
    AddNote(0, 65, 100, True);  AddNote(240, 65, 0, False);  // ファ（八分音符）
    
    // 5. ミレドー
    AddNote(0, 64, 100, True);  AddNote(480, 64, 0, False);  // ミ
    AddNote(0, 62, 100, True);  AddNote(480, 62, 0, False);  // レ
    AddNote(0, 60, 100, True);  AddNote(960, 60, 0, False);  // どー（長い音符）

    // 終端
    WriteVarLen(0);
    Midi.WriteByte($FF); Midi.WriteByte($2F); Midi.WriteByte($00);

    // トラックの長さを計算して書き戻し
    TrackLen := Midi.Position - TrackStartPos - 4;
    Midi.Position := TrackStartPos;
    WriteIntBE(TrackLen, 4);

    Midi.SaveToFile(FileName);
  finally
    Midi.Free;
  end;
end;

end.

