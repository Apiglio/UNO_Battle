unit CardDisplay;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  EditBtn, ExtCtrls, Windows, defination, card, player;



type

  TCardImage = class(TCustomImage)
    //property onKeyPress;
    //property onKeyUp;
    //property onClick;
  end;

  TCardDisplayForm = class(TForm)
  public
    Card:array[0..CARD_RANGE]of TCardImage;
    Desktop:record
      deck,discard,usage_stack:TScrollBox;
      GroupBox:TGroupBox;
    end;
    Player:array[0..PLAYER_RANGE]of record
      hand,attack,defend,blood,restrict:TScrollBox;
      GroupBox:TGroupBox;
    end;
  public
    constructor CreateNew(AOwner:TComponent);
    procedure MoveCardXY(Ca:CardNo;X,Y:longint);

  public
    procedure MoveCard(var Msg:TMessage);message Msg_Display_MoveCard;

  end;

var CardDisplayForm:TCardDisplayForm;

implementation

constructor TCardDisplayForm.CreateNew(AOwner:TComponent);
var CardId:CardNo;
    PlayerN:PlayerNo;
begin
  inherited CreateNew(AOwner);
  Self.Width:=800;
  Self.Height:=600;
  Self.Position:=poScreenCenter;
  for cardId:=1 to CARD_RANGE do
    begin
      if not Assigned(CardList[CardId]) then continue;
      Self.Card[CardId]:=TCardImage.Create(Self);
      Self.Card[CardId].Parent:=Self;
      Self.Card[CardId].Picture.LoadFromFile('png\'+CardList[CardId].name+'.png');
      //Self.Card[CardId].Proportional:=true;
      Self.Card[CardId].Stretch:=true;
      Self.Card[CardId].Width:=40;
      Self.Card[CardId].Height:=60;
      //Self.Card[CardId].AutoSize:=true;
      Self.Card[CardId].Top:=200;
      Self.Card[CardId].Left:=600;
    end;


  for playerN:=0 to PLAYER_RANGE do
    begin

      Self.Player[playerN].GroupBox:=TGroupBox.Create(Self);
      Self.Player[playerN].GroupBox.Parent:=Self;
      Self.Player[playerN].GroupBox.Caption:=PlayerList[playerN].name;
      Self.Player[playerN].GroupBox.Height:=64*4+40;
      Self.Player[playerN].GroupBox.Width:=32*6+2*7+20;


      Self.Player[PlayerN].hand:=TScrollBox.Create(Self);
      Self.Player[PlayerN].attack:=TScrollBox.Create(Self);
      Self.Player[PlayerN].defend:=TScrollBox.Create(Self);
      Self.Player[PlayerN].blood:=TScrollBox.Create(Self);
      Self.Player[PlayerN].restrict:=TScrollBox.Create(Self);
      Self.Player[PlayerN].hand.parent:=Self.Player[playerN].GroupBox;
      Self.Player[PlayerN].attack.parent:=Self.Player[playerN].GroupBox;
      Self.Player[PlayerN].defend.parent:=Self.Player[playerN].GroupBox;
      Self.Player[PlayerN].blood.parent:=Self.Player[playerN].GroupBox;
      Self.Player[PlayerN].restrict.parent:=Self.Player[playerN].GroupBox;

      Self.Player[PlayerN].hand.Height:=64;
      Self.Player[PlayerN].attack.Height:=64;
      Self.Player[PlayerN].defend.Height:=64;
      Self.Player[PlayerN].blood.Height:=64;
      Self.Player[PlayerN].restrict.Height:=64;

      Self.Player[PlayerN].hand.Width:=32*6+2*7;
      Self.Player[PlayerN].attack.Width:=32*2+2*3;
      Self.Player[PlayerN].defend.Width:=32*6+2*7;
      Self.Player[PlayerN].blood.Width:=32*6+2*7;
      Self.Player[PlayerN].restrict.Width:=32*1+2*2;

      Self.Player[PlayerN].hand.Left:=2;
      Self.Player[PlayerN].attack.Left:=2+Self.Player[PlayerN].restrict.Width+2;
      Self.Player[PlayerN].defend.Left:=2;
      Self.Player[PlayerN].blood.Left:=2;
      Self.Player[PlayerN].restrict.Left:=2;

      Self.Player[PlayerN].hand.Top:=2;
      Self.Player[PlayerN].attack.Top:=2+64+2;
      Self.Player[PlayerN].defend.Top:=2+64+2+64+2;
      Self.Player[PlayerN].blood.Top:=2+64+2+64+2+64+2;
      Self.Player[PlayerN].restrict.Top:=2+64+2;

    end;

  for CardId:=1 to 108 do begin
    //Self.Card[CardId].Parent:=Self.Player[7].hand;
    MoveCardXY(CardId,240+((CardId-1) mod 8)*35,((CardId-1) div 8)*70);
  end;

end;

procedure TCardDisplayForm.MoveCardXY(Ca:CardNo;X,Y:longint);
begin
  Self.Card[Ca].Left:=X;
  Self.Card[Ca].Top:=Y;
end;

procedure TCardDisplayForm.MoveCard(var Msg:TMessage);
begin

end;




end.

