unit HDD;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, OSInfo, COCUtils, StructUnit, WMI, Subs,
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
 uses System.IniFiles, Main, WbemScripting_TLB, Winapi.ActiveX, Winapi.RichEdit;
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
 else ShowMessage('Информация по атрибуту отсутствует.');
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
 Inform(LangText(-1, 'Получение информации о диске \\.\PhysicalDrive'+IntToStr(DriveNum)+'.'));
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
   Add.Caption:= 'Атрибут';
   Add.Caption:= 'Имя';
   Add.Caption:= 'Состояние';
   Add.Caption:= 'Текущее (у.е.)';
   Add.Caption:= 'Худшее';
   Add.Caption:= 'Порог';
   Add.Caption:= 'Значение';
   Add.Caption:= 'Критичный'; //Критичный атрибут
   Add.Caption:= 'Счетчик';
   Add.Caption:= 'Частота ошибок';
  end;
 ListView.Groups.Clear;
 ListView.GroupView:=True;
 G1:=GetGroup(ListView, 'Общая информация об устройстве', True);
 G2:=GetGroup(ListView, 'S.M.A.R.T.', True);
 for i:= 0 to ListView.Columns.Count - 1 do ListView.Columns[i].Width:=75;
 ListView.Columns[0].Width:= 120;
 ListView.Columns[1].Width:= 400;
 ListView.Columns[2].Width:= 90;
 with ListView.Items.Add do
  begin
   Caption:='Съемный носитель';
   SubItems.Add(BoolToLang(DriveResult.RemoveMedia));
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='Модель';
   SubItems.Add(DriveResult.ModelNumber);
   GroupID:=G1;
   ImageIndex:=4;
  end;
 with ListView.Items.Add do
  begin
   Caption:='Серийный номер';
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
     Caption:='Температура';
     SubItems.Add(IntToStr(SmartResult.Temperature)+'°C');
     GroupID:=G1;
     ImageIndex:=3;
    end;
   with ListView.Items.Add do
    begin
     Caption:='Время работы';
     SubItems.Add(IntToStr(SmartResult.HoursRunning));
     GroupID:=G1;
     ImageIndex:=3;
    end;
   with ListView.Items.Add do
    begin
     Caption:='Переназначенных секторов';
     SubItems.Add(IntToStr(SmartResult.ReallocSector));
     GroupID:=G1;
     ImageIndex:=2;
    end;
   with ListView.Items.Add do
    begin
     Caption:='Объем';
     SubItems.Add(IntToKbyte(DriveResult.CapacityNum, True));
     GroupID:=G1;
     ImageIndex:=4;
    end;
  end;
 with ListView.Items.Add do
  begin
   Caption:='Результат';
   if (SmartResult.SmartFailTot <> 0) or (not DriveResult.SmartEnabled) then
    begin
     SubItems.Add('Ошибка получения информации SMART. Неверных атрибут: '+IntToStr(SmartResult.SmartFailTot));
     SubItems.Add(DriveResult.ErrInfo);
    end
   else
    begin
     SubItems.Add('Информация SMART успешно получена');
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
  0: Result:='SMART не доступен';
  1: Result:='Частота возникновения ошибок';
  2: Result:='Значение средней производительности диска';
  3: Result:='Время последнего разгона шпинделя';
  4: Result:='Кол-во раз включения диска';
  5: Result:='Кол-во секторов, переназначенных в резервную область';
  6: Result:='Запас канала чтения (устар.)';
  7: Result:='Частота возникновения ошибок при позиционировании БМГ';
  8: Result:='Средняя производительность операций позиционирования головок';
  9: Result:='Суммарное время работы';
  10: Result:='Кол-во повторов запуска шпинделя';
  11: Result:='Кол-во повторных попыток сброса накопителя';
  12: Result:='Кол-во полных циклов «включение-отключение» диска';
  13: Result:='Частота возникновения ошибок чтения (по вине ПО)';
  99: Result:='Среднее FHC'; //
  100: Result:='Температура гермоблока (Seagate) / Циклы стирания (SSD)';
  101: Result:='Максимум FHC'; //
  103: Result:='Восстановления таблицы перемещений'; //
  //108: Result:='Unknown ';//
  167: Result:='SSD Режим защиты'; //
  168: Result:='Кол-во ошибок SATA PHY';      //
  169: Result:='Полное кол-во испорченных блоков'; //
  170: Result:='Кол-во резервных блоков'; //
  171: Result:='Кол-во ошибок программы'; //
  172: Result:='Кол-во ошибок стирания'; //
  173: Result:='Кол-во стираний'; //
  174: Result:='Неожиданное отключение питания'; //
  175: Result:='Кол-во испорченных таблиц кластерв'; //
  176: Result:='Кол-во неудачных стираний'; //
  177: Result:='Кол-во выравниваний износа';//
  178: Result:='Кол-во использующихся резервных блоков (SSD)'; //
  179: Result:='Кол-во использующихся резервных блоков (SSD)'; //
  180: Result:='Кол-во резервных секторов, доступных для ремапа';
  181: Result:='Кол-во ошибок программы';//
  182: Result:='Кол-во ошибок стирания'; //
  183: Result:='Кол-во неудачных попыток понижения режима SATA';
  184: Result:='Кол-во ошибок, возникших при передаче данных через кэш';
  185: Result:='Стабильность головок (WD)';
  186: Result:='Обнаруженные индуцированные вибрации (Induced Op-Vibration Detection)'; //
  187: Result:='Кол-во ошибок отбора секторов-кандидатов на переназначение';
  188: Result:='Кол-во таймаут-операций';
  189: Result:='Кол-во случаев записи при высоте полета головки выше рассчитанной';
  190: Result:='Температура гермоблока (Hitachi, Samsung, WD)';
  191: Result:='Кол-во критических ускорений';
  192: Result:='Выключения питания в аварийных ситуациях / Кол-во парковок БМГ';
  193: Result:='Кол-во полных циклов парковки/распарковки БМГ';
  194: Result:='Текущая температура диска';
  195: Result:='Кол-во ошибок, скорректированых аппаратными средствами ECC';
  196: Result:='Кол-во операций переназначения секторов';
  197: Result:='Кол-во секторов-кандидатов на переназначение в резервную область';
  198: Result:='Кол-во секторов-кандидатов на переназначение (Самоконтроль)';
  199: Result:='Кол-во ошибок, возникших при передаче в режиме UltraDMA';
  200: Result:='Частота возникновения ошибок при записи';
  201: Result:='Частота возникновения ошибок чтения (по вине ПО)';

  202: Result:='Кол-во ошибок адресов данных (DAM)';
  203: Result:='Кол-во ошибок ECC';
  204: Result:='Кол-во ошибок ECC, скорректированных программным способом';
  205: Result:='Кол-во ошибок, вызванных перегревом';
  206: Result:='Высота между головкой и поверхностью диска';
  207: Result:='Величина силы тока при раскрутке шпинделя';
  208: Result:='Кол-во процедур вибрирующей раскрутки шпинделя';
  209: Result:='Производительность поиска во время офлайновых операций';
  210: Result:='Вибрация во время записи. (Maxtor 6B200M0 200GB и Maxtor 2R015H1 15GB)';
  211: Result:='Вибрация во время записи';
  212: Result:='Удары во время записи';
  220: Result:='Сдвиг пластин диска относительно оси шпинделя';
  221: Result:='Число ошибок, возникших из-за внешних нагрузок и ударов';
  222: Result:='Время нахождения БМГ в перемещении';
  223: Result:='Количество повторных циклов парковки/распарковки БМГ';
  224: Result:='Величина силы трения БМГ при его выгрузке из парковочной области';
  225: Result:='Количество циклов парковки БМГ';
  226: Result:='Время выгрузки БМГ на диски';
  227: Result:='Кол-во попыток скомпенсировать вращающий момент';
  228: Result:='Кол-во повторов автоматической парковки БМГ, после отключения';
  229: Result:='Спецификация производителя'; //
  230: Result:='Амплитуда «дрожания»';
  231: Result:='Температура диска / Остаток жизни (SSD)';
  232: Result:='Кол-во завершенных циклов стирания от максимально возможного (%)';
  233: Result:='Кол-во часов во вкл. состоянии / Media Wearout Indicator (SSD)';
  234: Result:='Average erase count AND Maximum Erase Count'; //
  235: Result:='Good Block Count AND System(Free) Block Count'; //
  240: Result:='Время, затраченное на позиционирование БМГ (для SSD "Vendor Specific")';
  241: Result:='Всего операций записи LBA (SSD)'; //
  242: Result:='Всего операций чтения LBA (SSD)'; //
  249: Result:='NAND_Writes_1GiB';//
  250: Result:='Кол-во ошибок во время чтения';
  254: Result:='Кол-во падений диска (зафиксированное электроникой)';
 else  Result:='Неизвестный атрибут';
 end;
end;

{

function TSmartHandler.Drives:Boolean;
var SpaceInt:Int64;
    Temp:TStrings;
    i:Word;
begin
 Result:=False;
 CurrentElement:=LangText(15, 'Проверка наличия свободного места на дисках');
 Temp:=GetListLogicalDrives;
 if Temp.Count > 0 then
  for i := 0 to Temp.Count - 1 do
   begin
    SpaceInt:=GetDriveSpaceInfo(Temp.Strings[i]+':').FreeSize div (1024 * 1024);
    if SpaceInt < MinSpace then
     AddItemToDel(LangText(45, 'Мало места на диске')+' "'+Temp.Strings[i]+'"',
                  dtSpace,
                  False,
                  LangText(46, 'На диске')+' "'+Temp.Strings[i]+':" '+LangText(47, 'всего')+' '+GetSpacedInt(IntToStr(SpaceInt)) + ' '+LangText(48, 'Мбайт'));
   end
 else Exit;
 Result:=True;
end;

//Список логических разделов
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
