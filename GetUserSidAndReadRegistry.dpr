program GetUserSidAndReadRegistry;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  Winapi.Windows,
  tlhelp32;

type
  _TOKEN_USER = record
    User: SID_AND_ATTRIBUTES;
  end;

function GetExplorerProcessHandle: THandle;
var
  h: THandle;
  pe: TProcessEntry32;
begin
  result := INVALID_HANDLE_VALUE;
  try
    h := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    try
      if h <> 0 then
      begin
        pe.dwSize := SizeOf(TProcessEntry32);
        if Process32First(h, pe) then
        begin
          repeat
            if StrIComp(pe.szExeFile, 'explorer.exe') = 0 then
            begin
              result := OpenProcess(PROCESS_ALL_ACCESS, false, pe.th32ProcessID);
              break;
            end;
          until not Process32Next(h, pe);
        end;
      end;
    finally
      CloseHandle(h);
    end;
  except
  end;
end;

function GetUserSid(var AUserId: string): boolean;
var
  hToken: THandle;
  users: array[0..15] of _TOKEN_USER;
  u32Needed: DWORD;
  I: Integer;
  tmp: PWideChar;
begin
  result := false;
  ZeroMemory(@users, sizeof(users));

  //
  // Teste por esse outro if também, se funcionar, toda a rotina GetExplorerProcessHandle pode ser removida
  // if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, hToken) then
  //

  if OpenProcessToken(GetExplorerProcessHandle(), TOKEN_QUERY, hToken) then
  begin
    if GetTokenInformation(hToken, TokenUser, @users[0], sizeof(users), u32Needed) then
    begin
      for I := Low(users) to High(users) do
      begin
        try
          if ConvertSidToStringSid(users[I].User.Sid, tmp) then
          begin
            AUserId := tmp;
            result := true;
            break;
          end;
        except
        end;
      end;
    end;
  end;
end;

var
  userSid: string;

begin
  try
    try
      if GetUserSid(userSid) then
      begin
        Writeln('O Sid é: ' + userSid);
      end;
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    Writeln('');
    Write('Processo finalizado! Pressione ENTER para fechar ... ');
    Readln;
  end;
end.

