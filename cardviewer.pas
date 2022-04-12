unit cardviewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids, defination;

type
  TCardViewerForm = class(TForm)
    StringGrid:TStringGrid;
    Button:Tbutton;
    Button_Sort:TButton;
  protected
    sort_status:byte;
  public
    constructor CreateNew(AOwner:TComponent);
    procedure FormReSize(Sender:TObject);
    procedure ButtonClick(Sender:TObject);
    procedure ButtonSortClick(Sender:TObject);

  end;

implementation
uses card,player,main,Apiglio_Useful;

constructor TCardViewerForm.CreateNew(AOwner:TComponent);
var i:CardNo;
begin
  inherited CreateNew(AOwner);
  Self.position:=poScreenCenter;
  Self.Caption:='CardViewer';
  Self.Width:=640;
  Self.Height:=480;
  Button:=TButton.Create(Self);
  Button.Parent:=Self;
  Button.Caption:='刷新';
  Button.OnClick:=@ButtonClick;
  Button_Sort:=TButton.Create(Self);
  Button_Sort.Parent:=Self;
  Button_Sort.Caption:='排序'+'(CardId)';
  Button_Sort.OnClick:=@ButtonSortClick;
  sort_status:=0;
  StringGrid:=TStringGrid.Create(Self);
  StringGrid.Parent:=Self;
  Stringgrid.MouseWheelOption:=mwGrid;
  StringGrid.ColCount:=6;
  StringGrid.RowCount:=CARD_RANGE+1;
  for i:=1 to CARD_RANGE do StringGrid.Cells[0,i]:='#'+Usf.zeroplus(i,3);
  StringGrid.Cells[0,0]:='CardId';
  StringGrid.Cells[1,0]:='名称';
  StringGrid.Cells[2,0]:='数值';
  StringGrid.Cells[3,0]:='颜色';
  StringGrid.Cells[4,0]:='所属玩家';
  StringGrid.Cells[5,0]:='所属区域';
  StringGrid.ColWidths[1]:=120;
  StringGrid.ColWidths[4]:=90;
  StringGrid.ColWidths[5]:=150;


  Self.OnResize:=@FormReSize;
  FormReSize(nil);

end;

procedure TCardViewerForm.FormReSize(Sender:TObject);
begin
  StringGrid.Left:=10;
  StringGrid.Top:=10;
  StringGrid.Width:=Self.Width-20;
  StringGrid.Height:=Self.Height-80;
  Button.Top:=StringGrid.Height+20;
  Button.Left:=10;
  Button.Width:=Self.Width-20;
  Button.Height:=20;
  Button_Sort.Top:=StringGrid.Height+50;
  Button_Sort.Left:=10;
  Button_Sort.Width:=Self.Width-20;
  Button_Sort.Height:=20;


end;

procedure TCardViewerForm.ButtonClick(Sender:TObject);
var i,j:CardNo;
    tmp:string;
begin
  for j:=1 to CARD_RANGE do
    begin
      tmp:=StringGrid.Cells[0,j];
      delete(tmp,1,1);
      i:=StrToInt(tmp);
      StringGrid.Cells[1,j]:=Usf.zeroplus(i,3);
      if Assigned(CardList[i]) then
        begin
          StringGrid.Cells[1,j]:=CardList[i].name;
          if CardList[i] is TNumberCard then
            StringGrid.Cells[2,j]:=IntToStr((CardList[i] as TNumberCard).number)
          else
            StringGrid.Cells[2,j]:='N/A';
          StringGrid.Cells[3,j]:=ColorName(CardList[i].color);
          IF CardList[i].location=nil THEN
          BEGIN
            StringGrid.Cells[4,j]:='N/A';
            StringGrid.Cells[5,j]:='N/A';
          END ELSE BEGIN
          if (CardList[i].location.owner is TPlayer) then
            StringGrid.Cells[4,j]:=(CardList[i].location.owner as TPlayer).name
          else
            StringGrid.Cells[4,j]:='N/A';
          case CardList[i].location.typename of
            'attack':StringGrid.Cells[5,j]:='备战区';
            'defend':StringGrid.Cells[5,j]:='防御区';
            'hand':StringGrid.Cells[5,j]:='手牌区';
            'blood':StringGrid.Cells[5,j]:='血量区';
            'restrict':StringGrid.Cells[5,j]:='限制区';
            'deck':StringGrid.Cells[5,j]:='牌堆';
            'discard':StringGrid.Cells[5,j]:='弃牌堆';
            'usage_stack':StringGrid.Cells[5,j]:='结算队列';
            else StringGrid.Cells[5,j]:='N/A';
          end;
          END;
        end
      else
        begin
          StringGrid.Cells[1,j]:='';
          StringGrid.Cells[2,j]:='';
          StringGrid.Cells[3,j]:='';
          StringGrid.Cells[4,j]:='';
          StringGrid.Cells[5,j]:='';
        end;
    end;

    {
    if Assigned(CardList[StrToInt(StringGrid.Cells[0,j])]) then
    begin
      i:=StrToInt(StringGrid.Cells[0,j]);
      StringGrid.Cells[1,i]:=CardList[i].name;
      if CardList[i] is TNumberCard then
        StringGrid.Cells[2,i]:=IntToStr((CardList[i] as TNumberCard).number)
      else
        StringGrid.Cells[2,i]:='N/A';
      StringGrid.Cells[3,i]:=ColorName(CardList[i].color);
      IF CardList[i].location=nil THEN
      BEGIN
        StringGrid.Cells[4,i]:='N/A';
        StringGrid.Cells[5,i]:='N/A';
      END ELSE BEGIN
      if (CardList[i].location.owner is TPlayer) then
        StringGrid.Cells[4,i]:=(CardList[i].location.owner as TPlayer).name
      else
        StringGrid.Cells[4,i]:='N/A';
      case CardList[i].location.typename of
        'attack':StringGrid.Cells[5,i]:='备战区';
        'defend':StringGrid.Cells[5,i]:='防御区';
        'hand':StringGrid.Cells[5,i]:='手牌区';
        'blood':StringGrid.Cells[5,i]:='血量区';
        'restrict':StringGrid.Cells[5,i]:='限制区';
        'deck':StringGrid.Cells[5,i]:='牌堆';
        'discard':StringGrid.Cells[5,i]:='弃牌堆';
        'usage_stack':StringGrid.Cells[5,i]:='结算队列';
        else StringGrid.Cells[5,i]:='N/A';
      end;
      END;
    end
    else
    begin
      StringGrid.Cells[1,j]:='';
      StringGrid.Cells[2,j]:='';
      StringGrid.Cells[3,j]:='';
      StringGrid.Cells[4,j]:='';
      StringGrid.Cells[5,j]:='';

    end;
    }
end;

procedure TCardViewerForm.ButtonSortClick(Sender:TObject);
begin
  inc(Self.sort_status);
  if Self.sort_status>=StringGrid.ColCount then Self.sort_status:=0;
  (Sender as TButton).Caption:='排序('+StringGrid.Cells[Self.sort_status,0]+')';
  StringGrid.SortColRow(true,sort_status);

end;

end.

