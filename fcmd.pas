unit fcmd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { Tcmd }

  Tcmd = class(TForm)
    Memo: TMemo;
    procedure FormChangeBounds(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  public
    procedure ResizeMemo;
    procedure writeln(str:utf8string);
  end;


implementation

{$R *.lfm}

procedure Tcmd.FormChangeBounds(Sender: TObject);
begin
  ResizeMemo;
end;

procedure Tcmd.FormCreate(Sender: TObject);
begin
  ResizeMemo;
  Memo.Clear;
end;

procedure Tcmd.ResizeMemo;
begin
  Memo.Parent:=Self;
  Memo.Width:=Self.Width-20;
  Memo.Height:=Self.Height-20;
  Memo.Left:=10;
  Memo.Top:=10;
end;

procedure Tcmd.writeln(str:utf8string);
begin
  Memo.Lines.add(str);
end;

initialization

end.

