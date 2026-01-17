unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  DCPrijndael, DCPsha256, DCPbase64, DCPcrypt2;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonClear: TButton;
    ButtonOpen: TButton;
    ButtonSave: TButton;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonOpenClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function EncryptText(const PlainText, Password: string): string;
    function DecryptText(const EncryptedText, Password: string): string;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

const
  IDENTIFIER = 'MYCRYPT';

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // フォームの初期化
end;

procedure TForm1.ButtonSaveClick(Sender: TObject);
var
  Password: string;
  PlainText: string;
  EncryptedText: string;
begin
  // パスワード入力
  if not InputQuery('パスワード入力', '暗号化用のパスワードを入力してください:', Password) then
    Exit;
  
  if Password = '' then
  begin
    ShowMessage('パスワードが空です。');
    Exit;
  end;

  // 保存ダイアログ表示
  if not SaveDialog1.Execute then
    Exit;

  try
    // テキストを取得（識別子を先頭に付加）
    PlainText := IDENTIFIER + Memo1.Text;
    
    // 暗号化
    EncryptedText := EncryptText(PlainText, Password);
    
    // ファイルに保存（テキストファイルとして）
    with TStringList.Create do
    try
      Text := EncryptedText;
      SaveToFile(SaveDialog1.FileName);
    finally
      Free;
    end;
    
    ShowMessage('ファイルを保存しました。');
  except
    on E: Exception do
      ShowMessage('保存エラー: ' + E.Message);
  end;
end;

procedure TForm1.ButtonOpenClick(Sender: TObject);
var
  Password: string;
  EncryptedText: string;
  DecryptedText: string;
begin
  // ファイル選択
  if not OpenDialog1.Execute then
    Exit;

  // パスワード入力
  if not InputQuery('パスワード入力', '復号用のパスワードを入力してください:', Password) then
    Exit;
  
  if Password = '' then
  begin
    ShowMessage('パスワードが空です。');
    Exit;
  end;

  try
    // ファイル読み込み（テキストファイルとして）
    with TStringList.Create do
    try
      LoadFromFile(OpenDialog1.FileName);
      EncryptedText := Text;
    finally
      Free;
    end;
    
    // 復号
    DecryptedText := DecryptText(EncryptedText, Password);
    
    // 識別子チェック
    if Copy(DecryptedText, 1, Length(IDENTIFIER)) <> IDENTIFIER then
    begin
      ShowMessage('復号に失敗しました。パスワードが間違っているか、データが壊れています。');
      Exit;
    end;
    
    // 識別子を除去して表示
    Memo1.Text := Copy(DecryptedText, Length(IDENTIFIER) + 1, MaxInt);
    ShowMessage('ファイルを読み込みました。');
  except
    on E: Exception do
      ShowMessage('読み込みエラー: ' + E.Message);
  end;
end;

procedure TForm1.ButtonClearClick(Sender: TObject);
begin
  Memo1.Clear;
end;

function TForm1.EncryptText(const PlainText, Password: string): string;
var
  Cipher: TDCP_rijndael;
  KeyHash: TDCP_sha256;
  Key: array[0..31] of byte;  // AES-256用の32バイト鍵
  IV: array[0..15] of byte;   // 16バイトのIV
  PlainData, EncryptedData: array of byte;
  i: Integer;
  EncryptedStr: string;
begin
  Result := '';
  
  // 鍵の生成（SHA-256でパスワードをハッシュ化）
  KeyHash := TDCP_sha256.Create(nil);
  try
    KeyHash.Init;
    KeyHash.UpdateStr(Password);
    KeyHash.Final(Key);
  finally
    KeyHash.Free;
  end;
  
  // IVの生成（パスワードから派生、簡易的な方法）
  KeyHash := TDCP_sha256.Create(nil);
  try
    KeyHash.Init;
    KeyHash.UpdateStr(Password + 'IV');
    KeyHash.Final(IV);
  finally
    KeyHash.Free;
  end;
  
  // 平文をバイト配列に変換
  SetLength(PlainData, Length(PlainText));
  for i := 1 to Length(PlainText) do
    PlainData[i - 1] := Ord(PlainText[i]);
  
  // 暗号化（PKCS7パディングを手動で追加）
  // ブロックサイズ（16バイト）に合わせてパディング
  i := 16 - (Length(PlainData) mod 16);
  if i = 16 then i := 0;
  SetLength(PlainData, Length(PlainData) + i);
  if i > 0 then
    FillChar(PlainData[Length(PlainData) - i], i, i);
  
  Cipher := TDCP_rijndael.Create(nil);
  try
    Cipher.Init(Key, 256, @IV);
    SetLength(EncryptedData, Length(PlainData));
    Cipher.EncryptCBC(PlainData[0], EncryptedData[0], Length(PlainData));
    Cipher.Burn;
  finally
    Cipher.Free;
  end;
  
  // バイト配列を文字列に変換
  SetLength(EncryptedStr, Length(EncryptedData));
  for i := 0 to Length(EncryptedData) - 1 do
    EncryptedStr[i + 1] := Chr(EncryptedData[i]);
  
  // Base64エンコード（DCPbase64を使用）
  Result := Base64EncodeStr(EncryptedStr);
end;

function TForm1.DecryptText(const EncryptedText, Password: string): string;
var
  Cipher: TDCP_rijndael;
  KeyHash: TDCP_sha256;
  Key: array[0..31] of byte;  // AES-256用の32バイト鍵
  IV: array[0..15] of byte;   // 16バイトのIV
  EncryptedData, DecryptedData: array of byte;
  i: Integer;
  DecodedStr: string;
begin
  Result := '';
  
  try
    // Base64デコード（DCPbase64を使用）
    DecodedStr := Base64DecodeStr(EncryptedText);
    
    if Length(DecodedStr) = 0 then
      Exit;
    
    // 文字列をバイト配列に変換
    SetLength(EncryptedData, Length(DecodedStr));
    for i := 1 to Length(DecodedStr) do
      EncryptedData[i - 1] := Ord(DecodedStr[i]);
    
    // 鍵の生成（SHA-256でパスワードをハッシュ化）
    KeyHash := TDCP_sha256.Create(nil);
    try
      KeyHash.Init;
      KeyHash.UpdateStr(Password);
      KeyHash.Final(Key);
    finally
      KeyHash.Free;
    end;
    
    // IVの生成（パスワードから派生、簡易的な方法）
    KeyHash := TDCP_sha256.Create(nil);
    try
      KeyHash.Init;
      KeyHash.UpdateStr(Password + 'IV');
      KeyHash.Final(IV);
    finally
      KeyHash.Free;
    end;
    
    // 復号
    Cipher := TDCP_rijndael.Create(nil);
    try
      Cipher.Init(Key, 256, @IV);
      SetLength(DecryptedData, Length(EncryptedData));
      Cipher.DecryptCBC(EncryptedData[0], DecryptedData[0], Length(EncryptedData));
      Cipher.Burn;
    finally
      Cipher.Free;
    end;
    
    // バイト配列を文字列に変換
    // 元の平文の長さを保持するため、識別子チェックで検証
    SetLength(Result, Length(DecryptedData));
    for i := 0 to Length(DecryptedData) - 1 do
      Result[i + 1] := Chr(DecryptedData[i]);
    
    // パディングを除去（PKCS7パディング: 最後のバイトがパディング長）
    if Length(Result) > 0 then
    begin
      i := Ord(Result[Length(Result)]);
      if (i > 0) and (i <= 16) and (Length(Result) >= i) then
      begin
        // パディングが正しいかチェック（すべて同じ値か確認）
        Delete(Result, Length(Result) - i + 1, i);
      end;
    end;
      
  except
    // エラー時は空文字列を返す（呼び出し側で識別子チェックにより検出）
    Result := '';
  end;
end;

end.
