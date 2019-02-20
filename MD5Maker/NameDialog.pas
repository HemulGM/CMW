unit NameDialog;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TFormMD5Name = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Bevel1: TBevel;
    Button1: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    EditSrc: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMD5Name: TFormMD5Name;

implementation

{$R *.dfm}

end.
