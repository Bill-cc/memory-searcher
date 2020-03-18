unit RomMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, WinSvc,TlHelp32, PsApi, ExtCtrls;

type
  TRomFind = class(TForm)
    GroupBox1: TGroupBox;
    ComboBox1: TComboBox;
    Button1: TButton;
    GroupBox2: TGroupBox;
    StaticText1: TStaticText;
    Edit1: TEdit;
    ListBox1: TListBox;
    Button2: TButton;
    Button3: TButton;
    StaticText2: TStaticText;
    Edit2: TEdit;
    StaticText3: TStaticText;
    Edit3: TEdit;
    Button4: TButton;
    StatusBar1: TStatusBar;
    StaticText4: TStaticText;
    StaticText5: TStaticText;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure SetStatusBar(index: Integer;showText: string);
    procedure Button1Click(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    procedure InitData;
  public
    procedure EnumProcess();      //�г�ϵͳ����
    procedure FindProcessMem();   //���ҽ����ڴ�
    procedure SelectProcess();    //ѡ�����
    procedure FirstFind(dwValue: LongInt);        //��һ�β���
    procedure NextFind(dwValue: LongInt);         //��һ�β���
    procedure AmendMem();  //�޸��ڴ�
    procedure ReStart();  //����
    procedure CompareAPage(dwBase: Pointer;regionSize: Cardinal;
      dwValue: LongInt);                          //�Ƚ��ڴ�ҳ
  end;

var
  RomFind : TRomFind;
  FirstFindFlag : Boolean;            //�Ƿ�Ϊ��һ�β���
  ListCnt : Integer;                  //��Ч��ַ����
  arList : array of string;           //��ַ�б�
  //CurrentProcess : TProcessEntry32;   //��ǰ��ѡ����
  processHandle : THandle;           //��ǰ���̾��
  FProcessEntry32 : array[0..100] of TProcessEntry32;  //���н��̽ṹ����

implementation

{$R *.dfm}

{ TRomFind }

procedure TRomFind.FormCreate(Sender: TObject);
begin
  InitData;
end;

procedure TRomFind.InitData;
begin
  EnumProcess;
  ListCnt := 0;
  FirstFindFlag := True;
  processHandle := 0;
end;

procedure TRomFind.SetStatusBar(index: Integer;showText: string);
begin
  StatusBar1.Panels.Items[index].Text := showText;
end;

procedure TRomFind.Button1Click(Sender: TObject);
begin
  EnumProcess;
end;

procedure TRomFind.ComboBox1Select(Sender: TObject);
begin
  SelectProcess;
end;

procedure TRomFind.EnumProcess;
var
  i : Integer;
  ContinueLoop  : BOOL;
  FSnapshotHandle : THandle;
begin
  //��ʼ��FProcessEntry32�ṹ��С
  for i := 0 to 100 do
  begin
    FProcessEntry32[i].dwSize := Sizeof(FProcessEntry32[i]);
  end;

  //��ȡ���̿���
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  
  try
    i := 0;
    ComboBox1.Clear;

    //�õ���һ������
    ContinueLoop := Process32First(FSnapshotHandle,FProcessEntry32[i]);

    while integer(ContinueLoop) <> 0 do
    begin
        //��ӽ��̵��б�
        ComboBox1.Items.Add(FProcessEntry32[i].szExeFile);
        i := i + 1;
        ContinueLoop := Process32Next(FSnapshotHandle,FProcessEntry32[i]);
    end;

    SetStatusBar(0,'������:'+IntToStr(ComboBox1.Items.Count));
  finally
    CloseHandle(FSnapshotHandle);
  end;
end;

//ѡ����̲��һ�ȡ���̾��
procedure TRomFind.SelectProcess;
begin
  if ComboBox1.Text = FProcessEntry32[ComboBox1.ItemIndex].szExeFile then
  begin
    if processHandle <> 0 then
    begin
      CloseHandle(processHandle);
      processHandle := 0;
    end;
    processHandle := OpenProcess(PROCESS_ALL_ACCESS,
                                 False,
                                 FProcessEntry32[ComboBox1.ItemIndex].th32ProcessID);
    if processHandle = 0 then ShowMessage('��ý��̾��ʧ�ܣ�');
    ReStart;
  end;
end;

procedure TRomFind.Button2Click(Sender: TObject);
begin
  FindProcessMem;
end;

procedure TRomFind.FindProcessMem;
var
  dwValue : LongInt;
begin
  if processHandle <> 0 then
  begin
    if Edit1.Text <> '' then
    begin
      dwValue := StrToInt(Edit1.Text);
      if FirstFindFlag then
      begin
        FirstFind(dwValue);
        FirstFindFlag := False;
      end else
      begin
        NextFind(dwValue);
      end;
    end else
    begin
      ShowMessage('������Ҫ��������ֵ��');
    end;
  end else
  begin
    ShowMessage('��ѡ��Ҫ���ҵĽ��̣�');
  end;
end;

procedure TRomFind.FirstFind(dwValue: LongInt);
var
  i : Integer;
  bAddr : Pointer;
  //processHandle : THandle;
  MemInfo : TMemoryBasicInformation;
  systemMemInfo : _SYSTEM_INFO; //ϵͳ�ڴ���Ϣ
  time1,time2 : TTime;
begin
  //�õ����̿��õ��ڴ��ַ��Χ
  GetSystemInfo(systemMemInfo);
  bAddr := systemMemInfo.lpMinimumApplicationAddress;

  //�õ���������ͬ���Ե��ڴ��
  time1 := Now;
  while VirtualQueryEx(processHandle,bAddr,MemInfo,SizeOf(MemInfo)) <> 0 do
  begin
     //������ύ״̬�ͽ��бȽ�
    if MemInfo.State = MEM_COMMIT then
    begin
      CompareAPage(MemInfo.BaseAddress,MemInfo.RegionSize,dwValue);
    end;
    //������һ��������׵�ַ
    bAddr := Pointer(Cardinal(MemInfo.BaseAddress) + MemInfo.RegionSize);
  end;
  time2 := Now;
  SetStatusBar(1,'��¼����:' + IntToStr(ListCnt));
  SetStatusBar(2,'��ʱ:'+Format('%0.4f',[(time2-time1)*24*60*60]));
  //����ַ�����ַ�б�
  SetLength(arList,ListCnt);
  for i := 0 to ListCnt - 1 do
  begin
    arList[i] := ListBox1.Items.Strings[i];
  end;
end;

procedure TRomFind.CompareAPage(dwBase: Pointer;regionSize: Cardinal;
  dwValue: LongInt);
var
  i : Integer;
  pdw : PLongint;
  regionSizeArr : array of Byte;
  lpNumberOfBytesRead : Cardinal;
begin
  SetLength(regionSizeArr,regionSize);
  lpNumberOfBytesRead := 0;
  if ReadProcessMemory(processHandle,dwBase,Pointer(regionSizeArr),
                       regionSize,lpNumberOfBytesRead) then
  begin
    for i := 0 to regionSize - 3 do
    begin
      pdw := PLongint(@regionSizeArr[i]);
      if pdw^ = dwValue then
      begin
        ListBox1.Items.Add('$'+IntToHex((Cardinal(dwBase)+Cardinal(i)),8));
        ListCnt := ListCnt + 1;
      end;
    end;
  end;
end;

procedure TRomFind.NextFind(dwValue: LongInt);
var
  i,Cnt : Integer;
  pdw : Pointer;
  dw : LongInt;
  time1,time2 : TTime;
  lpNumberOfBytesRead : Cardinal;
begin
  ListBox1.Clear;
  Cnt := ListCnt;
  ListCnt := 0;
  lpNumberOfBytesRead := 0;

  time1 := Now;
  for i := 0 to Cnt - 1 do
  begin
    pdw := Pointer(Cardinal(StrToInt(arList[i])));
    
    if ReadProcessMemory(processHandle,pdw,Pointer(@dw),
                         SizeOf(dw),lpNumberOfBytesRead) and
       (dw = dwValue)                                    then
    begin
      ListBox1.Items.Add(arList[i]);
      ListCnt := ListCnt + 1;
    end;
  end;
  time2 := Now;
  SetStatusBar(1,'��¼����:' + IntToStr(ListCnt));
  SetStatusBar(2,'��ʱ:'+Format('%0.4f',[(time2-time1)*24*60*60]));

  SetLength(arList,ListCnt);
  for i := 0 to ListCnt - 1 do
  begin
    arList[i] := ListBox1.Items.Strings[i];
  end;
end;

procedure TRomFind.Button4Click(Sender: TObject);
begin
  AmendMem;
end;

procedure TRomFind.ListBox1DblClick(Sender: TObject);
begin
  Edit2.Text := arList[ListBox1.ItemIndex];
end;

procedure TRomFind.ReStart;
begin
  FirstFindFlag := True;
  SetLength(arList,0);
  ListBox1.Clear;
  ListCnt := 0;
  Edit1.Text := '';
  Edit2.Text := '';
  Edit3.Text := '';
end;

procedure TRomFind.Button3Click(Sender: TObject);
begin
  ReStart;
end;

procedure TRomFind.AmendMem;
var
  memAddr : Pointer;
  pw : LongInt;
  lpNumberOfBytesRead : Cardinal;
begin
  lpNumberOfBytesRead := 0;
  pw := StrToInt(Edit3.Text);
  if Edit2.Text <> '' then
  begin
    memAddr := Pointer(Cardinal(StrToInt(Edit2.Text)));
    if WriteProcessMemory(processHandle,memAddr,
       @pw,SizeOf(LongInt),lpNumberOfBytesRead) then
    begin
      ShowMessage('�޸ĳɹ���');
    end else
      ShowMessage('д���ڴ�ʧ�ܣ�');
  end else
    ShowMessage('�������޸ĺ����ֵ��');
end;

end.
