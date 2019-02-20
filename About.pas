unit About;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, Vcl.Grids, Vcl.ValEdit;

type
  TFormAbout = class(TForm)
    Image1: TImage;
    Bevel1: TBevel;
    ValueListEditorHemulGM: TValueListEditor;
    procedure FormCreate(Sender: TObject);
    procedure ListBoxHemulGMDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormAbout: TFormAbout;

implementation
 uses Winapi.ShellAPI;

{$R *.dfm}

procedure TFormAbout.FormCreate(Sender: TObject);
begin
 ValueListEditorHemulGM.Strings.Clear;
 ValueListEditorHemulGM.InsertRow('Описание', 'Комплекс обслуживания рабочих станций', True);
 ValueListEditorHemulGM.InsertRow('Автор программы', 'Геннадий Малинин aka HemulGM', True);
 ValueListEditorHemulGM.InsertRow('Страница', 'https://hemulgm.ru/cmw', True);
 ValueListEditorHemulGM.InsertRow('', 'Copyright 2014-2016 HemulGM', True);
end;

procedure TFormAbout.ListBoxHemulGMDblClick(Sender: TObject);
begin
 ShellExecute(0, 'open', 'https://hemulgm.ru/cmw', nil, nil, SW_NORMAL);
end;

end.
