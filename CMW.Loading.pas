unit CMW.Loading;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.WinXCtrls;

type
  TFormLoading = class(TForm)
    Image1: TImage;
    LabelStep: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    procedure Step(Text:string);
  end;

var
  FormLoading: TFormLoading;

implementation

{$R *.dfm}

procedure TFormLoading.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action:=caFree;
end;

procedure TFormLoading.Step(Text: string);
begin
 LabelStep.Caption:=Text;
 Repaint;
end;

end.
