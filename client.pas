//{$define insert}

unit client;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Messages, LazUtf8,
  Windows, StdCtrls, {$ifndef insert}Apiglio_Useful, {$endif}defination, card, fcmd;

type

  TClientCombo = class(TComboBox)
    procedure Class_Seleted(Sender:TObject);
  public
    related_combo:TComboBox;
  end;

  TClientButton = class(TButton)
    procedure Parameter(Sender:TObject;out p1,p2,p3:TObject);

    procedure PlayCard(Sender:TObject);
    procedure PutCard(Sender:TObject);
    procedure ExchangeCard(Sender:TObject);

    procedure SendDefault(Sender:TObject);
    procedure SendAttackEnd(Sender:TObject);
    procedure SendDefendEnd(Sender:TObject);
    procedure SendDoNotDefend(Sender:TObject);
    procedure SendDoNotBleed(Sender:TObject);
    procedure SendDoNotCounter(Sender:TObject);


    //procedure SendDefault(Sender:TObject);

  end;

  TClientForm = class(TForm)
    Memo_cmd:TMemo;

  public
    Buttons:array[0..35]of TClientButton;
    ComboBoxs:array[0..5]of TClientCombo;

  public
    player_id:PlayerNo;
    self_hwnd:hwnd;
    parent_hwnd:hwnd;
    player:TObject;
    constructor Create(Sender:TComponent;pid:PlayerNo);
    procedure FormResize(sender:TObject);

  private
    procedure ts(str:string);
    procedure ts(str:string;dwd:dword);overload;
    procedure ts(str:string;dwd1,dwd2:dword);overload;

    procedure Memo_cmdKeyPress(Sender: TObject; var Key: char);
    procedure Show_have;

  private

    procedure GetDeath(var Msg:TMessage);message Msg_SendDeath;

    procedure GetHandCard(var Msg:TMessage);message Msg_SendHandCard;

    procedure GetAttackRound(var Msg:TMessage);message Msg_SendAttackRound;
    procedure GetDefendRound(var Msg:TMessage);message Msg_SendDefendRound;
    procedure GetColorChangeRound(var Msg:TMessage);message Msg_SendColorChangeRound;
    procedure GetBloodCardRound(var Msg:TMessage);message Msg_SendBloodCardRound;

    procedure GetCounterRound(var Msg:TMessage);message Msg_SendCounterRound;


    procedure GetDefendNeed(var Msg:TMessage);message Msg_SendDefendNeed;
    procedure GetBleedNeed(var Msg:TMessage);message Msg_SendBleedNeed;



    procedure GetEquipNeed(var Msg:TMessage);message Msg_SendEquipNeed;
    procedure GetFunctionNeed(var Msg:TMessage);message Msg_SendFunctionNeed;

    procedure SendAttackEnd;
    procedure SendDefendEnd;
    procedure SendBloodEnd;
    procedure SendDefault;
    procedure SendDoNotDefend;
    procedure SendDoNotBleed;
    procedure SendDoNotCounter;

    procedure PutCard(Card:TCard;Target:Tobject);
    procedure PlayCard(Card:TCard;Target:Tobject);
    procedure Exchange(Card:TCard);



  end;

var
  ClientForm:array[0..PLAYER_RANGE] of TClientForm;

implementation
uses player, main;

procedure TClientCombo.Class_Seleted(Sender:TObject);
var tmp:TObject;
    i:integer;
    card_unit:TCardUnit;
    function zeroplus(inp:integer):string;
    begin
      result:=IntToStr(inp);
      while length(result)<3 do result:='0'+result;
    end;

begin
  tmp:=nil;
  (Sender as TClientCombo).related_combo.clear;
  case (Sender as TClientCombo).Items[(Sender as TClientCombo).ItemIndex] of
    '手牌'  :tmp:=PlayerList[(Self.Parent as TClientForm).player_id].desktop.hand;
    '红区牌':tmp:=PlayerList[(Self.Parent as TClientForm).player_id].desktop.blood;
    '蓝区牌':tmp:=PlayerList[(Self.Parent as TClientForm).player_id].desktop.attack;
    '绿区牌':tmp:=PlayerList[(Self.Parent as TClientForm).player_id].desktop.defend;
    '结算栈':tmp:=Desktop.usage_stack;
    '*限制区'   :tmp:=PlayerList[(Self.Parent as TClientForm).player_id].desktop.restrict;
    '*来源暂存' :tmp:=PlayerList[(Self.Parent as TClientForm).player_id].ForeCard;
    '玩家'  :begin
               for i:=0 to Player_Range do
                 begin
                   (Sender as TClientCombo).related_combo.AddItem('['+zeroplus(PlayerList[i].id)+']'+PlayerList[i].name,Playerlist[i]);
                 end;
             end;
    '区域'  :begin
               (Sender as TClientCombo).related_combo.AddItem('[]牌堆',Desktop.deck);
               (Sender as TClientCombo).related_combo.AddItem('[]弃牌堆',Desktop.discard);
               (Sender as TClientCombo).related_combo.AddItem('[]结算栈',Desktop.usage_stack);
               for i:=0 to Player_Range do
                 begin
                   (Sender as TClientCombo).related_combo.AddItem('['+PlayerList[i].name+']'+utf8toansi('手牌'),Playerlist[i].desktop.hand);
                   (Sender as TClientCombo).related_combo.AddItem('['+PlayerList[i].name+']'+utf8toansi('红区'),Playerlist[i].desktop.blood);
                   (Sender as TClientCombo).related_combo.AddItem('['+PlayerList[i].name+']'+utf8toansi('绿区'),Playerlist[i].desktop.defend);
                   (Sender as TClientCombo).related_combo.AddItem('['+PlayerList[i].name+']'+utf8toansi('蓝区'),Playerlist[i].desktop.attack);
                   (Sender as TClientCombo).related_combo.AddItem('['+PlayerList[i].name+']'+utf8toansi('限制区'),Playerlist[i].desktop.restrict);
                   (Sender as TClientCombo).related_combo.AddItem('['+PlayerList[i].name+']'+utf8toansi('来源暂存'),Playerlist[i].ForeCard);

                 end;
             end;
  end;
  if tmp is TCardSet then
    begin
      card_unit:=(tmp as TCardSet).first;
      while card_unit<>nil do
        begin
          (Sender as TClientCombo).related_combo.AddItem('['+zeroplus((Card_unit.card as TCard).id)+']'+(Card_unit.card as TCard).name,Card_unit.card);
          card_unit:=card_unit.next;
        end;
    end
  else
    begin
      //
    end;
end;

procedure TClientButton.Parameter(Sender:TObject;out p1,p2,p3:TObject);
var RForm:TClientForm;
    i1,i2,i3:longint;
begin
  RForm:=(Self.Parent as TClientForm);
  i1:=RForm.ComboBoxs[3].ItemIndex;
  i2:=RForm.ComboBoxs[4].ItemIndex;
  i3:=RForm.ComboBoxs[5].ItemIndex;
  if i1>=0 then p1:=RForm.ComboBoxs[3].Items.Objects[i1] else p1:=RForm.player as TPlayer;
  if i2>=0 then p2:=RForm.ComboBoxs[4].Items.Objects[i2] else p2:=RForm.player as TPlayer;
  if i3>=0 then p3:=RForm.ComboBoxs[5].Items.Objects[i3] else p3:=RForm.player as TPlayer;
end;

procedure TClientButton.PlayCard(Sender:TObject);
var p1,p2,p3:TObject;
begin
  Self.Parameter(Sender,p1,p2,p3);
  if p1 is TCard then else exit;
  (Self.Parent as TClientForm).PlayCard(p1 as TCard,p2);
end;
procedure TClientButton.PutCard(Sender:TObject);
var p1,p2,p3:TObject;
begin
  Self.Parameter(Sender,p1,p2,p3);
  if p1 is TCard then else exit;
  (Self.Parent as TClientForm).PutCard(p1 as TCard,p2);
end;
procedure TClientButton.ExchangeCard(Sender:TObject);
var p1,p2,p3:TObject;
begin
  Self.Parameter(Sender,p1,p2,p3);
  if p1 is TCard then else exit;
  (Self.Parent as TClientForm).Exchange(p1 as TCard);
end;
procedure TClientButton.SendDefault(Sender:TObject);
begin
  (Self.Parent as TClientForm).SendDefault;
end;
procedure TClientButton.SendAttackEnd(Sender:TObject);
begin
  (Self.Parent as TClientForm).SendAttackEnd;
end;
procedure TClientButton.SendDefendEnd(Sender:TObject);
begin
  (Self.Parent as TClientForm).SendDefendEnd;
end;
procedure TClientButton.SendDoNotDefend(Sender:TObject);
begin
  (Self.Parent as TClientForm).SendDoNotDefend;
end;
procedure TClientButton.SendDoNotBleed(Sender:TObject);
begin
  (Self.Parent as TClientForm).SendDoNotBleed;
end;
procedure TClientButton.SendDoNotCounter(Sender:TObject);
begin
  (Self.Parent as TClientForm).SendDoNotCounter;
end;


constructor TClientForm.Create(Sender:TComponent;pid:PlayerNo);
var i:integer;
begin
  inherited CreateNew(Owner);
  player_id:=pid;
  player:=PlayerList[player_id] as TPlayer;
  Self.Caption:=PlayerList[player_id].name;
  Self.Width:=440;
  Self.Height:=280;
  Memo_cmd:=TMemo.Create(Self);
  Memo_cmd.parent:=Self;
  Memo_cmd.ScrollBars:=ssAutoVertical;
  Memo_cmd.onKeyPress:=@Memo_cmdKeyPress;

  for i:= 0 to 5 do
    begin
      ComboBoxs[i]:=TClientCombo.Create(Self);
      ComboBoxs[i].Parent:=Self;
      ComboBoxs[i].Clear;
    end;
  for i:= 0 to 2 do
    begin
        ComboBoxs[i].OnChange:=@ComboBoxs[i].Class_Seleted;
        ComboBoxs[i].related_combo:=ComboBoxs[i+3];
        ComboBoxs[i].AddItem('手牌',nil);
        ComboBoxs[i].AddItem('红区牌',nil);
        ComboBoxs[i].AddItem('蓝区牌',nil);
        ComboBoxs[i].AddItem('绿区牌',nil);
        ComboBoxs[i].AddItem('------',nil);
        ComboBoxs[i].AddItem('玩家',nil);
        ComboBoxs[i].AddItem('区域',nil);
        ComboBoxs[i].AddItem('结算栈',nil);
        ComboBoxs[i].AddItem('------',nil);
        ComboBoxs[i].AddItem('*限制区',nil);
        ComboBoxs[i].AddItem('*来源暂存',nil);

    end;
  for i:= 3 to 5 do
    begin
      ComboBoxs[i].Sorted:=true;
    end;
  for i:= 0 to 35 do
    begin
      Buttons[i]:=TClientButton.Create(Self);
      Buttons[i].Parent:=Self;
      Buttons[i].ShowHint:=true;
    end;

  Buttons[0].Caption:='出牌';
  Buttons[0].OnClick:=@Buttons[0].PlayCard;
  Buttons[1].Caption:='放置';
  Buttons[1].OnClick:=@Buttons[1].PutCard;
  Buttons[2].Caption:='置换';
  Buttons[2].OnClick:=@Buttons[2].ExchangeCard;

  Buttons[4].Caption:='结束备战阶段';
  Buttons[4].OnClick:=@Buttons[4].SendDefendEnd;
  Buttons[5].Caption:='结束攻击阶段';
  Buttons[5].OnClick:=@Buttons[5].SendAttackEnd;

  Buttons[8].Caption:='放弃防御';
  Buttons[8].OnClick:=@Buttons[8].SendDoNotDefend;
  Buttons[9].Caption:='放弃掉血';
  Buttons[9].OnClick:=@Buttons[9].SendDoNotBleed;
  Buttons[10].Caption:='放弃反击';
  Buttons[10].OnClick:=@Buttons[10].SendDoNotCounter;
  Buttons[11].Caption:='跳过确认';
  Buttons[11].OnClick:=@Buttons[11].SendDefault;


  for i:= 0 to 35 do Buttons[i].Hint:=Buttons[i].Caption;
  Self.OnResize:=@Self.FormResize;
  FormResize(nil);


end;

procedure TClientForm.FormResize(sender:TObject);
var i:integer;
    unit_width:word;
begin

  Memo_cmd.Left:=5;
  Memo_cmd.Top:=5;
  Memo_cmd.Width:=Self.Width-10-(Self.Width-15) div 3;
  Memo_cmd.Height:=Self.Height-10-55;

  unit_width:=(Self.Width-15) div 3;
  for i:=0 to 5 do
    begin
      ComboBoxs[i].Width:=unit_width;
      ComboBoxs[i].Height:=20;
      ComboBoxs[i].Left:=5*((i mod 3)+1)+(i mod 3)*unit_width;
      ComboBoxs[i].Top:=Self.Height - 55 + 25*(i div 3);
    end;
  for i:= 0 to 35 do
    begin
      Buttons[i].Width:=(unit_width-5) div 4;
      Buttons[i].Height:=22;
      Buttons[i].Left:=15+2*unit_width+(i mod 4)*(Buttons[i].Width+1);
      Buttons[i].Top:=5+(i div 4)*(22+2);
    end;

end;

procedure TClientForm.ts(str:string);
begin
  Self.Memo_cmd.lines.add(str);
end;
procedure TClientForm.ts(str:string;dwd:dword);
begin
  Self.Memo_cmd.lines.add(str+':'+Usf.i_to_s(dwd));
end;
procedure TClientForm.ts(str:string;dwd1,dwd2:dword);
begin
  Self.Memo_cmd.lines.add(str+':'+Usf.i_to_s(dwd1)+','+Usf.i_to_s(dwd2));
end;

procedure TClientForm.show_have;
begin
  if (Self.Player as TPlayer).desktop.hand.Have(TCard) then ts('任何牌：有')
  else ts('任何牌：无');
  if (Self.Player as TPlayer).desktop.hand.Have(TNumberCard) then ts('数字牌：有')
  else ts('数字牌：无');
  if (Self.Player as TPlayer).desktop.hand.Have(TEquipmentCard) then ts('装备牌：有')
  else ts('装备牌：无');
  if (Self.Player as TPlayer).desktop.hand.Have(TFunctionCard) then ts('功能牌：有')
  else ts('功能牌：无');

end;

procedure TClientForm.Memo_cmdKeyPress(Sender: TObject; var Key: char);
var cmdline:string;
begin
  if Key=#13 then begin
    cmdline:=lowercase((Sender as TMemo).Lines.Strings[(Sender as TMemo).Lines.Count-1]);
    Auf.ReadArgs(cmdline);
    case Auf.nargs[0].arg of
      'showhave':show_have;
      'ae':SendAttackEnd;
      'de':SendDefendEnd;
      'be':SendBloodEnd;
      'df':SendDefault;
      '!def':SendDoNotDefend;
      '!bld':SendDoNotBleed;
      '!ctr':SendDoNotCounter;
      'put':
        begin
          case Auf.nargs[1].arg of
            'def':PutCard(CardList[StrtoInt(Auf.nargs[2].arg)],(player as TPlayer).desktop.defend);
            'atk':PutCard(CardList[StrtoInt(Auf.nargs[2].arg)],(player as TPlayer).desktop.attack);
            'bld':PutCard(CardList[StrtoInt(Auf.nargs[2].arg)],(player as TPlayer).desktop.blood);
            else ts('put之后需要def|atk|bld参数')
          end;
        end;
      'play':
        begin
          case Auf.nargs[1].arg of
            'p':PlayCard(CardList[StrtoInt(Auf.nargs[2].arg)],PlayerList[StrToInt(Auf.nargs[3].arg)]);
            'c':PlayCard(CardList[StrtoInt(Auf.nargs[2].arg)],CardList[StrToInt(Auf.nargs[3].arg)]);
            else ts('play之后需要card|player参数')
          end;
        end;
      'exchange':
        begin
          Exchange(CardList[StrToInt(Auf.nargs[1].arg)]);
        end
      else ts('未知指令');
    end;
  end;
end;

procedure TClientForm.GetDeath(var Msg:TMessage);
begin
  ts('玩家阵亡！');
end;

procedure TClientForm.SendAttackEnd;
begin
  PostMessage(parent_hwnd,Msg_AttackEnd,Self.player_id,0);
end;

procedure TClientForm.SendDefendEnd;
begin
  PostMessage(parent_hwnd,Msg_DefendEnd,Self.player_id,0);
end;

procedure TClientForm.SendBloodEnd;
begin
  PostMessage(parent_hwnd,Msg_BloodEnd,Self.player_id,0);
end;

procedure TClientForm.SendDefault;
begin
  PostMessage(parent_hwnd,Msg_Default,Self.player_id,0);
end;
procedure TClientForm.SendDoNotDefend;
begin
  PostMessage(parent_hwnd,Msg_DoNotDefend,Self.player_id,0);
end;
procedure TClientForm.SendDoNotBleed;
begin
  PostMessage(parent_hwnd,Msg_DoNotBleed,Self.player_id,0);
end;
procedure TClientForm.SendDoNotCounter;
begin
  PostMessage(parent_hwnd,Msg_DoNotCounter,Self.player_id,0);
end;

procedure TClientForm.PutCard(Card:TCard;Target:Tobject);
begin
  Card.SetTarget(Target);
  Card.SetUser(Self.Player as TPlayer);
  SendMessage(parent_hwnd,Msg_PutCard,Self.player_id,Card.id);
end;

procedure TClientForm.PlayCard(Card:TCard;Target:Tobject);
begin
  Card.SetTarget(Target);
  Card.SetUser(Self.Player as TPlayer);
  if Card is TNumberCard then Card.Usage_Number:=(Card as TNumberCard).number;
  Card.SetUseColor((Self.Player as TPlayer).Card2UsageColor(Card.color));
  SendMessage(parent_hwnd,Msg_PlayCard,Self.player_id,Card.id);
end;
procedure TClientForm.Exchange(Card:TCard);
begin
  Card.SetUser(Self.player as TPlayer);
  //Card.SetTarget(nil);
  SendMessage(parent_hwnd,Msg_Exchange,Self.player_id,Card.id);
end;






procedure TClientForm.GetHandCard(var Msg:TMessage);
begin
  ts('获得手牌'+'【'+CardList[Msg.wParam].name+'】',Msg.wParam,Msg.lParam);
  SendDefault;
end;

procedure TClientForm.GetAttackRound(var Msg:TMessage);
begin
  ts('攻击阶段(输入ae结束)',Msg.wParam,Msg.lParam);
  //ts('玩家编号：'+Usf.i_to_s((Self.player as TPlayer).id));
  sleep(200);
  //SendAttackEnd;
end;
procedure TClientForm.GetDefendRound(var Msg:TMessage);
begin
  ts('备战阶段(输入de结束)',Msg.wParam,Msg.lParam);
  sleep(200);
  //SendDefendEnd;
end;


procedure TClientForm.GetCounterRound(var Msg:TMessage);
begin
  ts('反击阶段(输入!ctr结束)',Msg.wParam,Msg.lParam);
  //sleep(200);
  //SendDoNotCounter;
end;


procedure TClientForm.GetColorChangeRound(var Msg:TMessage);
begin
  ts('首个回合前的变色阶段(自动跳过)',Msg.wParam,Msg.lParam);
  //sleep(200);
  SendDefault;
end;
procedure TClientForm.GetBloodCardRound(var Msg:TMessage);
var tmp:TCard;
begin
  ts('选择性血量明置阶段(自动处理)',Msg.wParam,Msg.lParam);
  //sleep(200);

  repeat
  tmp:=(Self.Player as TPlayer).desktop.hand.ColorNumberPop((Self.Player as TPlayer).Usage2CardColor(CC_red)) as TCard;
  if tmp<>nil then
    begin
      PutCard(tmp,(Self.Player as TPlayer).desktop.blood);
    end;
  until tmp=nil;
  SendBloodEnd;
end;
procedure TClientForm.GetEquipNeed(var Msg:TMessage);
var tmp:TCard;
begin
  ts('加装备请求',Msg.wParam,Msg.lParam);

  if (Self.Player as TPlayer).desktop.hand.have(TEquipmentCard)
  or (Self.Player as TPlayer).desktop.attack.have(TEquipmentCard)
  or (Self.Player as TPlayer).desktop.defend.have(TEquipmentCard)
  then ts('PlayCard或SendDefault')
  else SendDefault;
end;
procedure TClientForm.GetFunctionNeed(var Msg:TMessage);
var tmp:TCard;
begin
  ts('确认生效请求',Msg.wParam,Msg.lParam);
  //sleep(200);
  ts('自动确认');
  SendDefault;
end;
procedure TClientForm.GetDefendNeed(var Msg:TMessage);
begin
  ts('需要防御(输入!def掉血)',Msg.wParam,Msg.lParam);
  //SendDoNotDefend;
end;

procedure TClientForm.GetBleedNeed(var Msg:TMessage);
begin
  ts('需要掉血(输入!bld死亡)',Msg.wParam,Msg.lParam);
  //SendDoNotBleed;
end;




end.


{$undef insert}
