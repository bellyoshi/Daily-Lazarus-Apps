unit ProjectCreator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil;

type
  TProjectType = (ptConsole, ptProgram, ptApplication);
  
  TErrorCallback = procedure(const Title, ErrorMessage: string) of object;

function CreateLazarusProject(const ProjectName, ProjectRoot: string; 
  ProjectType: TProjectType; OnError: TErrorCallback): Boolean;

implementation

function CreateLazarusProject(const ProjectName, ProjectRoot: string; 
  ProjectType: TProjectType; OnError: TErrorCallback): Boolean;
var
  ProjectPath, LprPath, LpiPath: string;
  LprFile, LpiFile: TextFile;
  ErrorMsg: string;
  DefaultUnitName: string;
begin
  Result := False;
  
  // プロジェクトフォルダの作成
  ProjectPath := IncludeTrailingPathDelimiter(ProjectRoot) + ProjectName;
  if not ForceDirectories(ProjectPath) then
  begin
    ErrorMsg := Format('プロジェクトフォルダの作成に失敗しました。'#13#10 +
                       'パス: %s'#13#10 +
                       'エラー: フォルダを作成できませんでした。', [ProjectPath]);
    if Assigned(OnError) then
      OnError('エラー', ErrorMsg);
    Exit;
  end;
  
  // ファイルパス
  LprPath := IncludeTrailingPathDelimiter(ProjectPath) + ProjectName + '.lpr';
  LpiPath := IncludeTrailingPathDelimiter(ProjectPath) + ProjectName + '.lpi';
  DefaultUnitName := 'Unit1'; // デフォルトのユニット名
  
  try
    // .lprファイルの作成
    AssignFile(LprFile, LprPath);
    Rewrite(LprFile);
    try
      case ProjectType of
        ptConsole: // コンソール
        begin
          WriteLn(LprFile, 'program ', ProjectName, ';');
          WriteLn(LprFile, '');
          WriteLn(LprFile, '{$mode objfpc}{$H+}');
          WriteLn(LprFile, '');
          WriteLn(LprFile, 'uses');
          WriteLn(LprFile, '  Classes, SysUtils;');
          WriteLn(LprFile, '');
          WriteLn(LprFile, 'begin');
          WriteLn(LprFile, '  WriteLn(''Hello, World!'');');
          WriteLn(LprFile, 'end.');
        end;
        ptProgram: // 単純なプログラム(lpr)
        begin
          WriteLn(LprFile, 'program ', ProjectName, ';');
          WriteLn(LprFile, '');
          WriteLn(LprFile, '{$mode objfpc}{$H+}');
          WriteLn(LprFile, '');
          WriteLn(LprFile, 'uses');
          WriteLn(LprFile, '  Classes, SysUtils;');
          WriteLn(LprFile, '');
          WriteLn(LprFile, 'begin');
          WriteLn(LprFile, '  // Your code here');
          WriteLn(LprFile, 'end.');
        end;
        ptApplication: // アプリケーション(GUI)
        begin
          WriteLn(LprFile, 'program ', ProjectName, ';');
          WriteLn(LprFile, '');
          WriteLn(LprFile, '{$mode objfpc}{$H+}');
          WriteLn(LprFile, '');
          WriteLn(LprFile, 'uses');
          WriteLn(LprFile, '  {$IFDEF UNIX}');
          WriteLn(LprFile, '  cthreads,');
          WriteLn(LprFile, '  {$ENDIF}');
          WriteLn(LprFile, '  {$IFDEF HASAMIGA}');
          WriteLn(LprFile, '  athreads,');
          WriteLn(LprFile, '  {$ENDIF}');
          WriteLn(LprFile, '  Interfaces, // this includes the LCL widgetset');
          WriteLn(LprFile, '  Forms, ', DefaultUnitName);
          WriteLn(LprFile, '  { you can add units after this };');
          WriteLn(LprFile, '');
          WriteLn(LprFile, '{$R *.res}');
          WriteLn(LprFile, '');
          WriteLn(LprFile, 'begin');
          WriteLn(LprFile, '  RequireDerivedFormResource:=True;');
          WriteLn(LprFile, '  Application.Scaled:=True;');
          WriteLn(LprFile, '  {$PUSH}{$WARN 5044 OFF}');
          WriteLn(LprFile, '  Application.MainFormOnTaskbar:=True;');
          WriteLn(LprFile, '  {$POP}');
          WriteLn(LprFile, '  Application.Initialize;');
          WriteLn(LprFile, '  Application.CreateForm(TForm1, Form1);');
          WriteLn(LprFile, '  Application.Run;');
          WriteLn(LprFile, 'end.');
        end;
      end;
    finally
      CloseFile(LprFile);
    end;
    
    // .lpiファイルの作成
    AssignFile(LpiFile, LpiPath);
    Rewrite(LpiFile);
    try
      WriteLn(LpiFile, '<?xml version="1.0" encoding="UTF-8"?>');
      WriteLn(LpiFile, '<CONFIG>');
      WriteLn(LpiFile, '  <ProjectOptions>');
      WriteLn(LpiFile, '    <Version Value="12"/>');
      WriteLn(LpiFile, '    <PathDelim Value="\"/>');
      WriteLn(LpiFile, '    <General>');
      WriteLn(LpiFile, '      <SessionStorage Value="InProjectDir"/>');
      WriteLn(LpiFile, '      <Title Value="', ProjectName, '"/>');
      WriteLn(LpiFile, '      <Scaled Value="True"/>');
      WriteLn(LpiFile, '      <ResourceType Value="res"/>');
      WriteLn(LpiFile, '      <UseXPManifest Value="True"/>');
      WriteLn(LpiFile, '      <XPManifest>');
      WriteLn(LpiFile, '        <DpiAware Value="True"/>');
      WriteLn(LpiFile, '      </XPManifest>');
      WriteLn(LpiFile, '      <Icon Value="0"/>');
      WriteLn(LpiFile, '    </General>');
      WriteLn(LpiFile, '    <BuildModes>');
      WriteLn(LpiFile, '      <Item Name="Default" Default="True"/>');
      WriteLn(LpiFile, '    </BuildModes>');
      WriteLn(LpiFile, '    <PublishOptions>');
      WriteLn(LpiFile, '      <Version Value="2"/>');
      WriteLn(LpiFile, '      <UseFileFilters Value="True"/>');
      WriteLn(LpiFile, '    </PublishOptions>');
      WriteLn(LpiFile, '    <RunParams>');
      WriteLn(LpiFile, '      <FormatVersion Value="2"/>');
      WriteLn(LpiFile, '    </RunParams>');
      if ProjectType = ptApplication then // GUIアプリケーションの場合のみLCLが必要
      begin
        WriteLn(LpiFile, '    <RequiredPackages>');
        WriteLn(LpiFile, '      <Item>');
        WriteLn(LpiFile, '        <PackageName Value="LCL"/>');
        WriteLn(LpiFile, '      </Item>');
        WriteLn(LpiFile, '    </RequiredPackages>');
      end;
      WriteLn(LpiFile, '    <Units>');
      WriteLn(LpiFile, '      <Unit>');
      WriteLn(LpiFile, '        <Filename Value="', ProjectName, '.lpr"/>');
      WriteLn(LpiFile, '        <IsPartOfProject Value="True"/>');
      WriteLn(LpiFile, '      </Unit>');
      if ProjectType = ptApplication then // GUIアプリケーションの場合のみユニットを追加
      begin
        WriteLn(LpiFile, '      <Unit>');
        WriteLn(LpiFile, '        <Filename Value="', DefaultUnitName, '.pas"/>');
        WriteLn(LpiFile, '        <IsPartOfProject Value="True"/>');
        WriteLn(LpiFile, '        <ComponentName Value="Form1"/>');
        WriteLn(LpiFile, '        <HasResources Value="True"/>');
        WriteLn(LpiFile, '        <ResourceBaseClass Value="Form"/>');
        WriteLn(LpiFile, '      </Unit>');
      end;
      WriteLn(LpiFile, '    </Units>');
      WriteLn(LpiFile, '  </ProjectOptions>');
      WriteLn(LpiFile, '  <CompilerOptions>');
      WriteLn(LpiFile, '    <Version Value="11"/>');
      WriteLn(LpiFile, '    <PathDelim Value="\"/>');
      WriteLn(LpiFile, '    <Target>');
      WriteLn(LpiFile, '      <Filename Value="', ProjectName, '"/>');
      WriteLn(LpiFile, '    </Target>');
      WriteLn(LpiFile, '    <SearchPaths>');
      WriteLn(LpiFile, '      <IncludeFiles Value="$(ProjOutDir)"/>');
      WriteLn(LpiFile, '      <UnitOutputDirectory Value="lib\$(TargetCPU)-$(TargetOS)"/>');
      WriteLn(LpiFile, '    </SearchPaths>');
      if ProjectType = ptApplication then // GUIアプリケーションの場合
      begin
        WriteLn(LpiFile, '    <Linking>');
        WriteLn(LpiFile, '      <Options>');
        WriteLn(LpiFile, '        <Win32>');
        WriteLn(LpiFile, '          <GraphicApplication Value="True"/>');
        WriteLn(LpiFile, '        </Win32>');
        WriteLn(LpiFile, '      </Options>');
        WriteLn(LpiFile, '    </Linking>');
      end;
      WriteLn(LpiFile, '  </CompilerOptions>');
      WriteLn(LpiFile, '  <Debugging>');
      WriteLn(LpiFile, '    <Exceptions>');
      WriteLn(LpiFile, '      <Item>');
      WriteLn(LpiFile, '        <Name Value="EAbort"/>');
      WriteLn(LpiFile, '      </Item>');
      WriteLn(LpiFile, '      <Item>');
      WriteLn(LpiFile, '        <Name Value="ECodetoolError"/>');
      WriteLn(LpiFile, '      </Item>');
      WriteLn(LpiFile, '      <Item>');
      WriteLn(LpiFile, '        <Name Value="EFOpenError"/>');
      WriteLn(LpiFile, '      </Item>');
      WriteLn(LpiFile, '    </Exceptions>');
      WriteLn(LpiFile, '  </Debugging>');
      WriteLn(LpiFile, '</CONFIG>');
    finally
      CloseFile(LpiFile);
    end;
    
    // GUIアプリケーションの場合はユニットファイルも作成
    if ProjectType = ptApplication then
    begin
      AssignFile(LprFile, IncludeTrailingPathDelimiter(ProjectPath) + DefaultUnitName + '.pas');
      Rewrite(LprFile);
      try
        WriteLn(LprFile, 'unit ', DefaultUnitName, ';');
        WriteLn(LprFile, '');
        WriteLn(LprFile, '{$mode objfpc}{$H+}');
        WriteLn(LprFile, '');
        WriteLn(LprFile, 'interface');
        WriteLn(LprFile, '');
        WriteLn(LprFile, 'uses');
        WriteLn(LprFile, '  Classes, SysUtils, Forms, Controls, Graphics, Dialogs;');
        WriteLn(LprFile, '');
        WriteLn(LprFile, 'type');
        WriteLn(LprFile, '');
        WriteLn(LprFile, '  { TForm1 }');
        WriteLn(LprFile, '');
        WriteLn(LprFile, '  TForm1 = class(TForm)');
        WriteLn(LprFile, '  private');
        WriteLn(LprFile, '');
        WriteLn(LprFile, '  public');
        WriteLn(LprFile, '');
        WriteLn(LprFile, '  end;');
        WriteLn(LprFile, '');
        WriteLn(LprFile, 'var');
        WriteLn(LprFile, '  Form1: TForm1;');
        WriteLn(LprFile, '');
        WriteLn(LprFile, 'implementation');
        WriteLn(LprFile, '');
        WriteLn(LprFile, '{$R *.lfm}');
        WriteLn(LprFile, '');
        WriteLn(LprFile, 'end.');
      finally
        CloseFile(LprFile);
      end;
      
      // .lfmファイルも作成
      AssignFile(LprFile, IncludeTrailingPathDelimiter(ProjectPath) + DefaultUnitName + '.lfm');
      Rewrite(LprFile);
      try
        WriteLn(LprFile, 'object Form1: TForm1');
        WriteLn(LprFile, '  Left = 316');
        WriteLn(LprFile, '  Height = 240');
        WriteLn(LprFile, '  Top = 162');
        WriteLn(LprFile, '  Width = 320');
        WriteLn(LprFile, '  Caption = ''Form1''');
        WriteLn(LprFile, '  DesignTimePPI = 120');
        WriteLn(LprFile, '  LCLVersion = ''4.4.0.0''');
        WriteLn(LprFile, 'end');
      finally
        CloseFile(LprFile);
      end;
    end;
    
    Result := True;
  except
    on E: Exception do
    begin
      ErrorMsg := Format('プロジェクト作成中に例外が発生しました。'#13#10#13#10 +
                         'エラータイプ: %s'#13#10 +
                         'エラーメッセージ: %s'#13#10 +
                         'プロジェクトパス: %s',
                         [E.ClassName,
                          E.Message,
                          ProjectPath]);
      if Assigned(OnError) then
        OnError('例外エラー', ErrorMsg);
      Result := False;
    end;
  end;
end;

end.

