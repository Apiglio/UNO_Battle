unit player;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, defination, card, client;

type

  TPlayer = class(TObject)
  public
    need:record
      defend,bleed:longint;//需要处理的被攻击数额或血量流失数额，数字0使用0.5替代
    end;
    origin:record
      defend,bleed:longint;//最初被攻击数额或血量流失数额，数字0使用0.5替代
    end;

    OnEvent:array[0..3]of TEvent;
  public
    id:PlayerNo;
    name:utf8string;
    desktop:record
      hand,blood,defend,attack,restrict:TCardSet;
    end;
    client:record
      hd:hwnd;
      form:TClientForm;
    end;//可能的客户端连接方式
    color_symbol:record
      Blue,Red,Green,Yellow:CardColor;
    end;//解释变色牌
    blood_info:record
      Number:longint;
      CardNumber:longint;
      Std:double;
    end;
    alive:boolean;//是否存活
    firstround:boolean;//是否开始了第一个回合

    RestAttack:byte;//剩余攻击次数
    RestDefend:byte;//剩余布防张数
    ColorChangeRestAttack:byte;//剩余攻击次数(变色牌回手后)
    ColorChangeRestDefend:byte;//剩余布防张数(变色牌回手后)


    DefendInputLocked_Round:byte;//禁止向防御区布置的限制回合数
    DefendOutputLocked_Round:byte;//禁止向防御区移出的限制回合数
    AttackInputLocked_Round:byte;//禁止向备战区布置的限制回合数
    AttackOutputLocked_Round:byte;//禁止向备战区移出的限制回合数


    Round:boolean;//是否在自己回合内
    RoundStatus:byte;//回合内的第几个阶段，回合外为0；备战阶段为1,3,5；战斗阶段为2,4
    InDefend,InBleed,InCounterGreen,InCounterRed,InCounterBlue:boolean;//是否在防御过程中、掉血过程中、防御成功后、掉血结算后和受到攻击结算后

    VitalDefendCard:boolean;//是否需要先打出一张防御牌（用于数字牌0）
    VitalBloodCard:boolean;//是否需要先打出一张血量牌（用于数字牌0）
    CanUseGreenReverse:boolean;//是否可以使用绿反，绿反生效、打出蓝反或结束反击阶段时复位。
    CanUseRedReverse:boolean;//是否可以使用红反，打出蓝反或结束反击阶段时复位。
    CanUseBlueReverse:boolean;//是否可以使用蓝反，结束反击阶段时复位。

    ForeCard:TCardSet;//反击流程的回溯栈

  protected
    function BloodCardNumber:longint;
    function BloodNumber:longint;
    function BloodStd(mean:double):double;
  public
    procedure setAttack(n:longint);
    procedure setBleed(n:longint);
    procedure decAttack(n:longint);
    procedure decBleed(n:longint);

    procedure decDefendInputLocked_Round;//减小禁止向防御区布置的限制回合数
    procedure decDefendOutputLocked_Round;//减小禁止向防御区移出的限制回合数
    procedure decAttackInputLocked_Round;//减小禁止向备战区布置的限制回合数
    procedure decAttackOutputLocked_Round;//减小禁止向备战区移出的限制回合数

    constructor Create(pid:PlayerNo);
    function Usage2CardColor(CColor:CardColor):CardColor;//将玩家视为的颜色转化为牌的实际颜色
    function Card2UsageColor(CColor:CardColor):CardColor;//将牌的实际颜色转化为玩家视为的颜色
    procedure renew_blood_info;


    procedure Defend_Process(Sender:TObject);
    procedure Bleed_Process(Sender:TObject);
    procedure ExtraDefend_Process(Sender:TObject);
    procedure ExtraBleed_Process(Sender:TObject);

    procedure Death;

  public
    property OnDefend:TEvent read OnEvent[0] write OnEvent[0];
    property OnBleed:TEvent read OnEvent[1] write OnEvent[1];
    property OnExtraDefend:TEvent read OnEvent[2] write OnEvent[2];
    property OnExtraBleed:TEvent read OnEvent[3] write OnEvent[3];


  end;

var playerList:array[0..PLAYER_RANGE]of TPlayer;


implementation
uses fcmd,main;

constructor TPlayer.Create(pid:PlayerNo);
begin
  inherited Create;
  Self.id:=pid;
  Self.desktop.attack:=TCardSet.Create(Self,'attack');
  Self.desktop.defend:=TCardSet.Create(Self,'defend');
  Self.desktop.blood:=TCardSet.Create(Self,'blood');
  Self.desktop.hand:=TCardSet.Create(Self,'hand');
  Self.desktop.restrict:=TCardSet.Create(Self,'restrict');
  with color_symbol do
    begin
      Blue:=CC_Blue;
      Red:=CC_Red;
      Green:=CC_Green;
      Yellow:=CC_Yellow;
    end;
  Self.OnBleed:=@Self.Bleed_Process;
  Self.OnDefend:=@Self.Defend_Process;
  Self.OnExtraBleed:=@Self.ExtraBleed_Process;
  Self.OnExtraDefend:=@Self.ExtraDefend_Process;

  InDefend:=false;
  InBleed:=false;
  InCounterRed:=false;
  InCounterBlue:=false;
  InCounterGreen:=false;

  ForeCard:=TCardSet.Create(Self,'fore');

  Self.alive:=true;
  ColorChangeRestAttack:=0;
  ColorChangeRestDefend:=0;

end;

function TPlayer.Card2UsageColor(CColor:CardColor):CardColor;
begin
  case CColor of
    CC_Black:result:=CC_Black;
    CC_Blue:result:=Self.color_symbol.Blue;
    CC_Red:result:=Self.color_symbol.Red;
    CC_Green:result:=Self.color_symbol.Green;
    CC_Yellow:result:=Self.color_symbol.Yellow;
  end;
end;
function TPlayer.Usage2CardColor(CColor:CardColor):CardColor;
begin

  if CColor = CC_Black then result:=CC_Black;
  if CColor = Self.color_symbol.Blue then result:=CC_Blue;
  if CColor = Self.color_symbol.Red then result:=CC_Red;
  if CColor = Self.color_symbol.Green then result:=CC_Green;
  if CColor = Self.color_symbol.Yellow then result:=CC_Yellow;
end;

function TPlayer.BloodCardNumber:longint;
begin
  result:=Self.desktop.blood.total;
end;

function TPlayer.BloodNumber:longint;
var acc:longint;
    tmp:TCardUnit;
begin
  acc:=0;
  tmp:=Self.desktop.blood.first;
  repeat
    acc:=acc+(tmp.card as TNumberCard).number;
    tmp:=tmp.next;
  until tmp=nil;
  result:=acc;
end;

function TPlayer.BloodStd(mean:double):double;
var acc:double;
    tmp:TCardUnit;
begin
  acc:=0.0;
  tmp:=Self.desktop.blood.first;
  repeat
    acc:=acc+sqr((tmp.card as TNumberCard).number - mean);
    tmp:=tmp.next;
  until tmp=nil;
  acc:=sqrt(acc);
  result:=acc;
end;

procedure TPlayer.renew_blood_info;
begin
  blood_info.CardNumber:=BloodCardNumber;
  blood_info.Number:=BloodNumber;
  blood_info.Std:=BloodStd(blood_info.Number / blood_info.CardNumber);

end;

procedure TPlayer.decDefendInputLocked_Round;
begin
  if DefendInputLocked_Round<>0 then dec(DefendInputLocked_Round);
end;
procedure TPlayer.decDefendOutputLocked_Round;
begin
  if DefendOutputLocked_Round<>0 then dec(DefendOutputLocked_Round);
end;
procedure TPlayer.decAttackInputLocked_Round;
begin
  if AttackInputLocked_Round<>0 then dec(AttackInputLocked_Round);
end;
procedure TPlayer.decAttackOutputLocked_Round;
begin
  if AttackOutputLocked_Round<>0 then dec(AttackOutputLocked_Round);
end;

procedure TPlayer.setAttack(n:longint);
begin
  cmd.writeln('TPlayer.setAttack('+ansitoutf8(IntToStr(n))+')->'+Self.name);
  Self.InDefend:=true;
  Self.VitalDefendCard:=true;
  Self.origin.defend:=n;
  Self.need.defend:=n;
  OnDefend(nil);
  //if n>0 then OnDefend(nil)
  //else if n<0 then OnExtraDefend(nil);
end;
procedure TPlayer.setBleed(n:longint);
begin
  cmd.writeln('TPlayer.setBleed('+ansitoutf8(IntToStr(n))+')->'+Self.name);
  Self.InBleed:=true;
  Self.VitalBloodCard:=true;
  Self.origin.bleed:=n;
  Self.need.bleed:=n;
  OnBleed(nil);
  //if n>0 then OnBleed(nil)
  //else if n<0 then OnExtraBleed(nil);
end;
procedure TPlayer.decAttack(n:longint);
begin
  cmd.writeln('TPlayer.decAttack('+ansitoutf8(IntToStr(n))+')->'+Self.name);
  Self.VitalDefendCard:=false;
  Self.need.defend:=Self.need.defend - n;
  if (Self.need.defend<=0) and (not Self.VitalDefendCard) then
    begin
      Self.InDefend:=false;
      Self.InCounterGreen:=true;
      Self.InCounterBlue:=true;
      Self.CanUseGreenReverse:=true;//TReverse(usage.color in [CC_Green,CC_Blue]).UseCard中将它赋值为false
      Self.CanUseBlueReverse:=true;//同上，但是不一定用到
      OnExtraDefend(nil);
    end
  else OnDefend(nil);
end;
procedure TPlayer.decBleed(n:longint);
begin
  cmd.writeln('TPlayer.decBleed('+ansitoutf8(IntToStr(n))+')->'+Self.name);
  Self.VitalDefendCard:=false;
  Self.need.bleed:=Self.need.bleed - n;
  if (Self.need.bleed<=0) and (not Self.VitalBloodCard) then
    begin
      Self.InBleed:=false;
      Self.InCounterRed:=true;
      Self.CanUseRedReverse:=true;//TReverse(usage.color=CC_Red).UseCard中将它赋值为false
      OnExtraBleed(nil)
    end
  else OnBleed(nil);
end;

procedure TPlayer.Defend_Process(Sender:TObject);
begin
  PostMessage(Self.client.hd,Msg_SendDefendNeed,Self.need.defend,0);
end;

procedure TPlayer.Bleed_Process(Sender:TObject);
begin
  PostMessage(Self.client.hd,Msg_SendBleedNeed,Self.need.defend,0);
end;

procedure TPlayer.ExtraDefend_Process(Sender:TObject);
begin
  PostMessage(Self.client.hd,Msg_SendCounterRound,Self.origin.defend-Self.need.defend,0);
end;

procedure TPlayer.ExtraBleed_Process(Sender:TObject);
begin
  PostMessage(Self.client.hd,Msg_SendCounterRound,Self.origin.bleed-Self.need.bleed,0);
end;


procedure TPlayer.Death;
begin
  PostMessage(Self.client.hd,Msg_SendDeath,0,0);
  Self.alive:=false;
end;


end.

