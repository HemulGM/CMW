unit Module.HDD;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CMW.OSInfo, CMW.Utils, CMW.ModuleStruct, WMI, Subs,
  Vcl.StdCtrls, Vcl.ComCtrls;

type
  TFormHDD = class(TForm)
    MemoDesc: TMemo;
    RichEditDesc: TRichEdit;
    LabelAttr: TEdit;
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
   private
    { Private declarations }
   public
    { Public declarations }
  end;

  THDDUnit = class(TSystemUnit)
    procedure OnChanged; override;
    procedure Initialize; override;
    function FGet:TGlobalState; override;
   private
    DriveNum:Word;
    FResInfo:string;
    FGetAttrNames:Boolean;
   public
    procedure ShowAttribute(Num:string);
    procedure Stop; override;
    procedure Get(DNum:Word); overload;
    property GetAttrNames:Boolean read FGetAttrNames write FGetAttrNames;
  end;


var
  FormHDD: TFormHDD;
  AttrInform:set of Byte = [2, 3, 4, 6, 8, 9, 12, 99, 100, 101, 170, 173, 180, 185, 190, 193, 194, 206, 207, 209, 222, 224, 225, 226, 229, 231, 232, 233, 234, 235, 240, 241, 242, 249];
  AttrError:set of Byte = [0, 5, 10, 13, 103, 168, 169, 171, 172, 174, 175, 176, 177, 178, 179, 181, 182, 183, 184, 186, 188, 196, 197, 198, 201, 230];
  AttrWarning:set of Byte = [1, 7, 11, 167, 187, 189, 191, 192, 195, 199, 200, 202, 203, 204, 205, 208, 210, 211, 212, 220, 221, 223, 227, 228, 250, 254];

  function GetSMARTAttrName(ID:Byte):string;



implementation
 uses System.IniFiles, CMW.Main, WbemScripting_TLB, Winapi.ActiveX, Winapi.RichEdit;
{$R *.dfm}

procedure THDDUnit.Initialize;
begin
 //
end;

procedure JUSTIFYSet(RichEdit:TRichEdit);
const EM_SETTYPOGRAPHYOPTIONS = WM_USER + 202;
      TO_ADVANCEDTYPOGRAPHY = $0001;
var paraformat: PARAFORMAT2;
begin
 SendMessage(RichEdit.Handle, EM_SETTYPOGRAPHYOPTIONS, TO_ADVANCEDTYPOGRAPHY, TO_ADVANCEDTYPOGRAPHY);
 paraformat.cbSize := sizeof(PARAFORMAT2);
 paraformat.dwMask := PFM_ALIGNMENT;
 paraformat.wAlignment := PFA_JUSTIFY;
 SendMessage(RichEdit.Handle, EM_SETPARAFORMAT, 0, Integer(@paraformat));
end;

procedure THDDUnit.ShowAttribute(Num:string);
var Ini:TIniFile;
    Desc:string;
begin
 Ini:=TIniFile.Create(CurrentDir+'Data\SMART.inf');
 Desc:=Ini.ReadString('Attribute', Num, '');
 if Desc <> '' then
  with FormHDD do
   begin
    LabelAttr.Text:=Format('(%s) %s', [Num, GetSMARTAttrName(StrToInt(Num))]);
    RichEditDesc.Lines.Text:=Desc;
    RichEditDesc.SelectAll;
    JUSTIFYSet(RichEditDesc);
    RichEditDesc.Refresh;
    RichEditDesc.SelStart:=0;
    RichEditDesc.SelLength:=0;
    ShowModal;
   end
 else ShowMessage('���������� �� �������� �����������.');
 Ini.Free;
end;

procedure THDDUnit.Get(DNum:Word);
begin
 DriveNum:=DNum;
 inherited Get;
end;

procedure THDDUnit.OnChanged;
begin
 inherited;
 OnListViewSort;
end;

procedure THDDUnit.Stop;
begin
 inherited;
end;

function THDDUnit.FGet:TGlobalState;
var DriveResult:TDriveResult ;
    SmartResult:TSmartResult ;
    i, G1, G2:integer ;
begin
 Inform(LangText(-1, '��������� ���������� � ����� \\.\PhysicalDrive'+IntToStr(DriveNum)+'.'));
 //Test;
 Result:=gsProcess;
 ListView.Items.BeginUpdate;
 ListView.Items.Clear;
 if not MagWmiSmartDiskFail(DriveNum, DriveResult, SmartResult) then
  begin
   FResInfo:=DriveResult.ErrInfo;
   Log([FResInfo]);
   Inform(FResInfo);
  end;
 Application.ProcessMessages;
 with ListView.Columns do
  begin
   Clear;
   Add.Caption:= '�������';
   Add.Caption:= '���';
   Add.Caption:= '���������';
   Add.Caption:= '������� (�.�.)';
   Add.Caption:= '������';
   Add.Caption:= '�����';
   Add.Caption:= '��������';
   Add.Caption:= '���������'; //��������� �������
   Add.Caption:= '�������';
   Add.Caption:= '������� ������';
  end;
 ListView.Groups.Clear;
 ListView.GroupView:=True;
 G1:=GetGroup(ListView, '����� ���������� �� ����������', True);
 G2:=GetGroup(ListView, 'S.M.A.R.T.', True);
 for i:= 0 to ListView.Columns.Count - 1 do ListView.Columns[i].Width:=75;
 ListView.Columns[0].Width:= 120;
 ListView.Columns[1].Width:= 400;
 ListView.Columns[2].Width:= 90;
 with ListView.Items.Add do
  begin
   Caption:='������� ��������';
   SubItems.Add(BoolToLang(DriveResult.RemoveMedia));
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='������';
   SubItems.Add(DriveResult.ModelNumber);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='�������� �����';
   SubItems.Add(DriveResult.SerialNumber);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='DeviceId';
   SubItems.Add(DriveResult.DeviceId);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='BusTypeDisp';
   SubItems.Add(DriveResult.BusTypeDisp);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='DevTypeDisp';
   SubItems.Add(DriveResult.DevTypeDisp);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='VendorId';
   SubItems.Add(DriveResult.VendorId);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='ProductId';
   SubItems.Add(DriveResult.ProductId);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='ProductRev';
   SubItems.Add(DriveResult.ProductRev);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='FirmwareRev';
   SubItems.Add(DriveResult.FirmwareRev);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='AtaVersion';
   SubItems.Add(DriveResult.AtaVersion);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='SataVersion';
   SubItems.Add(DriveResult.SataVersion);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 if SmartResult.TotalAttrs > 0 then
  begin
   with ListView.Items.Add do
    begin
     Caption:='�����������';
     SubItems.Add(IntToStr(SmartResult.Temperature)+'�C');
     GroupID:=G1;
     ImageIndex:=3;
    end;
   with ListView.Items.Add do
    begin
     Caption:='����� ������';
     SubItems.Add(IntToStr(SmartResult.HoursRunning));
     GroupID:=G1;
     ImageIndex:=3;
    end;
   with ListView.Items.Add do
    begin
     Caption:='��������������� ��������';
     SubItems.Add(IntToStr(SmartResult.ReallocSector));
     GroupID:=G1;
     ImageIndex:=2;
    end;
   with ListView.Items.Add do
    begin
     Caption:='�����';
     SubItems.Add(IntToKbyte(DriveResult.CapacityNum, True));
     GroupID:=G1;
     ImageIndex:=4;
    end;
  end;
 with ListView.Items.Add do
  begin
   Caption:='���������';
   if (SmartResult.SmartFailTot <> 0) or (not DriveResult.SmartEnabled) then
    begin
     SubItems.Add('������ ��������� ���������� SMART. �������� �������: '+IntToStr(SmartResult.SmartFailTot));
     SubItems.Add(DriveResult.ErrInfo);
    end
   else
    begin
     SubItems.Add('���������� SMART ������� ��������');
    end;
   GroupID:=G1;
   ImageIndex:=3;
  end;
 if SmartResult.TotalAttrs > 0 then
  begin
   for i:=0 to Pred(SmartResult.TotalAttrs) do
    begin
     if Stopping then Exit(gsStopped);
     with ListView.Items.Add do
      begin
       Caption:=IntToStr(SmartResult.AttrNum[i]);
       if FGetAttrNames then
        SubItems.Add(GetSMARTAttrName(SmartResult.AttrNum[i])) //AttrName
       else SubItems.Add(SmartResult.AttrName[i]);
       SubItems.Add(SmartResult.AttrState[i]);
       SubItems.Add(IntToStr(SmartResult.AttrCurValue[i]));
       SubItems.Add(IntToStr(SmartResult.AttrWorstVal[i]));
       SubItems.Add(IntToStr(SmartResult.AttrThreshold[i]));
       SubItems.Add(IntToCStr(SmartResult.AttrRawValue[i]));
       SubItems.Add(GetYesNo(SmartResult.AttrPreFail[i]));
       SubItems.Add(GetYesNo(SmartResult.AttrEvents[i]));
       SubItems.Add(GetYesNo(SmartResult.AttrErrorRate[i]));   //w e i=3
       GroupID:=G2;
       if SmartResult.AttrNum[i] in AttrInform then ImageIndex:=3 else
        if SmartResult.AttrNum[i] in AttrWarning then ImageIndex:=1 else
         if SmartResult.AttrNum[i] in AttrError then ImageIndex:=2 else
          ImageIndex:=0;
      end;
    end;
  end
 else
  begin
   ListView.Groups[G1].State:=ListView.Groups[G1].State - [lgsCollapsed];
  end;
 Inform(FResInfo);
 OnChanged;
 try
  Result:=gsFinished;
 except
  Exit;
 end;
end;

function GetSMARTAttrName(ID:Byte):string;
begin
 case ID of
  0: Result:='SMART �� ��������';
  1: Result:='������� ������������� ������';
  2: Result:='�������� ������� ������������������ �����';
  3: Result:='����� ���������� ������� ��������';
  4: Result:='���-�� ��� ��������� �����';
  5: Result:='���-�� ��������, ��������������� � ��������� �������';
  6: Result:='����� ������ ������ (�����.)';
  7: Result:='������� ������������� ������ ��� ���������������� ���';
  8: Result:='������� ������������������ �������� ���������������� �������';
  9: Result:='��������� ����� ������';
  10: Result:='���-�� �������� ������� ��������';
  11: Result:='���-�� ��������� ������� ������ ����������';
  12: Result:='���-�� ������ ������ ����������-���������� �����';
  13: Result:='������� ������������� ������ ������ (�� ���� ��)';
  99: Result:='������� FHC'; //
  100: Result:='����������� ���������� (Seagate) / ����� �������� (SSD)';
  101: Result:='�������� FHC'; //
  103: Result:='�������������� ������� �����������'; //
  //108: Result:='Unknown ';//
  167: Result:='SSD ����� ������'; //
  168: Result:='���-�� ������ SATA PHY';      //
  169: Result:='������ ���-�� ����������� ������'; //
  170: Result:='���-�� ��������� ������'; //
  171: Result:='���-�� ������ ���������'; //
  172: Result:='���-�� ������ ��������'; //
  173: Result:='���-�� ��������'; //
  174: Result:='����������� ���������� �������'; //
  175: Result:='���-�� ����������� ������ ��������'; //
  176: Result:='���-�� ��������� ��������'; //
  177: Result:='���-�� ������������ ������';//
  178: Result:='���-�� �������������� ��������� ������ (SSD)'; //
  179: Result:='���-�� �������������� ��������� ������ (SSD)'; //
  180: Result:='���-�� ��������� ��������, ��������� ��� ������';
  181: Result:='���-�� ������ ���������';//
  182: Result:='���-�� ������ ��������'; //
  183: Result:='���-�� ��������� ������� ��������� ������ SATA';
  184: Result:='���-�� ������, ��������� ��� �������� ������ ����� ���';
  185: Result:='������������ ������� (WD)';
  186: Result:='������������ �������������� �������� (Induced Op-Vibration Detection)'; //
  187: Result:='���-�� ������ ������ ��������-���������� �� ��������������';
  188: Result:='���-�� �������-��������';
  189: Result:='���-�� ������� ������ ��� ������ ������ ������� ���� ������������';
  190: Result:='����������� ���������� (Hitachi, Samsung, WD)';
  191: Result:='���-�� ����������� ���������';
  192: Result:='���������� ������� � ��������� ��������� / ���-�� �������� ���';
  193: Result:='���-�� ������ ������ ��������/����������� ���';
  194: Result:='������� ����������� �����';
  195: Result:='���-�� ������, ���������������� ����������� ���������� ECC';
  196: Result:='���-�� �������� �������������� ��������';
  197: Result:='���-�� ��������-���������� �� �������������� � ��������� �������';
  198: Result:='���-�� ��������-���������� �� �������������� (������������)';
  199: Result:='���-�� ������, ��������� ��� �������� � ������ UltraDMA';
  200: Result:='������� ������������� ������ ��� ������';
  201: Result:='������� ������������� ������ ������ (�� ���� ��)';

  202: Result:='���-�� ������ ������� ������ (DAM)';
  203: Result:='���-�� ������ ECC';
  204: Result:='���-�� ������ ECC, ����������������� ����������� ��������';
  205: Result:='���-�� ������, ��������� ����������';
  206: Result:='������ ����� �������� � ������������ �����';
  207: Result:='�������� ���� ���� ��� ��������� ��������';
  208: Result:='���-�� �������� ����������� ��������� ��������';
  209: Result:='������������������ ������ �� ����� ���������� ��������';
  210: Result:='�������� �� ����� ������. (Maxtor 6B200M0 200GB � Maxtor 2R015H1 15GB)';
  211: Result:='�������� �� ����� ������';
  212: Result:='����� �� ����� ������';
  220: Result:='����� ������� ����� ������������ ��� ��������';
  221: Result:='����� ������, ��������� ��-�� ������� �������� � ������';
  222: Result:='����� ���������� ��� � �����������';
  223: Result:='���������� ��������� ������ ��������/����������� ���';
  224: Result:='�������� ���� ������ ��� ��� ��� �������� �� ����������� �������';
  225: Result:='���������� ������ �������� ���';
  226: Result:='����� �������� ��� �� �����';
  227: Result:='���-�� ������� ��������������� ��������� ������';
  228: Result:='���-�� �������� �������������� �������� ���, ����� ����������';
  229: Result:='������������ �������������'; //
  230: Result:='��������� ����������';
  231: Result:='����������� ����� / ������� ����� (SSD)';
  232: Result:='���-�� ����������� ������ �������� �� ����������� ���������� (%)';
  233: Result:='���-�� ����� �� ���. ��������� / Media Wearout Indicator (SSD)';
  234: Result:='Average erase count AND Maximum Erase Count'; //
  235: Result:='Good Block Count AND System(Free) Block Count'; //
  240: Result:='�����, ����������� �� ���������������� ��� (��� SSD "Vendor Specific")';
  241: Result:='����� �������� ������ LBA (SSD)'; //
  242: Result:='����� �������� ������ LBA (SSD)'; //
  249: Result:='NAND_Writes_1GiB';//
  250: Result:='���-�� ������ �� ����� ������';
  254: Result:='���-�� ������� ����� (��������������� ������������)';
 else  Result:='����������� �������';
 end;
end;

{

function TSmartHandler.Drives:Boolean;
var SpaceInt:Int64;
    Temp:TStrings;
    i:Word;
begin
 Result:=False;
 CurrentElement:=LangText(15, '�������� ������� ���������� ����� �� ������');
 Temp:=GetListLogicalDrives;
 if Temp.Count > 0 then
  for i := 0 to Temp.Count - 1 do
   begin
    SpaceInt:=GetDriveSpaceInfo(Temp.Strings[i]+':').FreeSize div (1024 * 1024);
    if SpaceInt < MinSpace then
     AddItemToDel(LangText(45, '���� ����� �� �����')+' "'+Temp.Strings[i]+'"',
                  dtSpace,
                  False,
                  LangText(46, '�� �����')+' "'+Temp.Strings[i]+':" '+LangText(47, '�����')+' '+GetSpacedInt(IntToStr(SpaceInt)) + ' '+LangText(48, '�����'));
   end
 else Exit;
 Result:=True;
end;

//������ ���������� ��������
function GetListLogicalDrives:TStrings;
var
  DriveNum: Integer;
  DriveChar: Char;
  DriveType: TDriveType;
  DriveBits: set of 0..25;
begin
 Result:=TStringList.Create;
 Integer(DriveBits):=GetLogicalDrives;
 for DriveNum:= 0 to 25 do
  begin
   if not (DriveNum in DriveBits) then Continue;
   DriveChar:=Char(DriveNum + Ord('a'));
   DriveType:=TDriveType(GetDriveType(PChar(DriveChar + ':\')));
   DriveChar:=UpCase(DriveChar);
   case DriveType of
    dtFixed, dtRAM: Result.Add(DriveChar);
   end;
  end;
end;
}

procedure TFormHDD.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

end.
