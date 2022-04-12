unit card;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, defination;

type

  TCard = class(TObject)
  protected
    usage:record
      user:TObject;//使用牌的玩家
      target:TObject;//牌的作用对象，可以是玩家(TPlayer)、牌(TCard)或区域(TCardSet)
      color:CardColor;//实际结算使用的颜色
      number:byte;//结算时的真实数量，与装备牌有关
      auxiliary_target:TObject;//辅助对象，用于部分反转牌的设置
    end;//用于生效使用效果的数据
  public
    property Usage_Target:TObject read usage.target;
    property Usage_User:TObject read usage.user;
    property Usage_Color:CardColor read usage.color;
    property Usage_number:byte read usage.number write usage.number;
  public//只读部分
    id:CardNo;
    color:CardColor;
    name:string;
    locked_round:byte;//位置封锁的回合数
    be_wasted:boolean;//是否需要弃置
    stack:record
      equipped:boolean;
      confirmed:boolean;
      from:TCardSet;
    end;//结算堆栈中的是否装备与是否确认

    location:TCardSet;//其所在的位置，有Desktop.deck,Desktop.discard和Player[].desktop.*几种
  public
    function PlayCard:boolean;virtual;//打出，返回是否打出成功
    procedure UseCard;virtual;abstract;//使用，结算
    function PutCard:boolean;//放置，返回是否放置成功
    function Exchange:TCard;//置换，返回置换的牌

    procedure DefineUserColor;virtual;//根据使用者更新使用颜色，并将Usage_Color的黄色转译
    function IsTargetOf(Card:Tcard):boolean;virtual;abstract;//返回Card能不能以此牌为对象
    function CanPlayInDefendRound:boolean;virtual;abstract;//是否能在备战阶段主动使用
    function CanPlayInAttackRound:boolean;virtual;abstract;//是否能在攻击阶段主动使用
    function CanPlayOnDefend:boolean;virtual;abstract;//是否能在防御时使用
    function CanPlayOnBleed:boolean;virtual;abstract;//是否能在掉血时使用
    function AtPosition:boolean;virtual;abstract;//这张牌是否在可以发动的位置上
    function ParamCheck:boolean;virtual;abstract;//这张牌是否具有正确的参数设置


    constructor Create(pid:CardNo;pcolor:CardColor);

    procedure SetTarget(TargetObj:TObject);virtual;//设置牌的作用对象
    procedure SetUser(PlayerObj:TObject);//设置牌的使用者
    procedure SetUseColor(pcolor:CardColor);
    procedure Used;virtual;//清零使用对象和作用对象

    procedure MoveTo(destination:TObject);//移动到指定位置
    procedure MoveToFirst(destination:TObject);//移动到指定位置
    procedure MoveToStack;//移动到Usage_Stack（上一个过程的特例，不能混用，否则不能触发TCardStack的事件）

  end;//所有牌的父类

  TNumberCard = class(TCard)
  public
    number:byte;
    constructor Create(pid:CardNo;pcolor:CardColor;pnumber:byte);
    procedure Used;override;
    //function PlayCard:boolean;override;
    procedure UseCard;override;
    procedure DefineUserColor;override;
    function IsTargetOf(Card:Tcard):boolean;override;
    function CanPlayInDefendRound:boolean;override;
    function CanPlayInAttackRound:boolean;override;
    function CanPlayOnDefend:boolean;override;
    function CanPlayOnBleed:boolean;override;
    function AtPosition:boolean;override;
    function ParamCheck:boolean;override;
  end;//数字牌

  TEquipmentCard = class(TCard)
  public
    number:byte;
    procedure SetTarget(TargetObj:TObject);override;
    constructor Create(pid:CardNo;pcolor:CardColor;pnumber:byte);
    procedure Used;override;
    procedure UseCard;override;
    //function PlayCard:boolean;override;
    procedure DefineUserColor;override;
    function IsTargetOf(Card:Tcard):boolean;override;
    function CanPlayInDefendRound:boolean;override;
    function CanPlayInAttackRound:boolean;override;
    function CanPlayOnDefend:boolean;override;
    function CanPlayOnBleed:boolean;override;
    function AtPosition:boolean;override;
    function ParamCheck:boolean;override;
  end;//装备牌

  TFunctionCard = class(TCard)
    //procedure Used;override;

  end;//功能牌

  TForbidCard = class(TFunctionCard)
    function IsTargetOf(Card:Tcard):boolean;override;
    function CanPlayInDefendRound:boolean;override;
    function CanPlayInAttackRound:boolean;override;
    function CanPlayOnDefend:boolean;override;
    function CanPlayOnBleed:boolean;override;
    function AtPosition:boolean;override;
    function ParamCheck:boolean;override;
    procedure UseCard;override;
  end;
  TReverseCard = class(TFunctionCard)
    function IsTargetOf(Card:Tcard):boolean;override;
    function AtPosition:boolean;override;
    function ParamCheck:boolean;override;
    function CanPlayInDefendRound:boolean;override;
    function CanPlayInAttackRound:boolean;override;
    function CanPlayOnDefend:boolean;override;
    function CanPlayOnBleed:boolean;override;
    procedure UseCard;override;
  end;
  TColorChangeCard = class(TFunctionCard)
    function IsTargetOf(Card:Tcard):boolean;override;
    function AtPosition:boolean;override;
    function ParamCheck:boolean;override;
    function CanPlayInDefendRound:boolean;override;
    function CanPlayInAttackRound:boolean;override;
    function CanPlayOnDefend:boolean;override;
    function CanPlayOnBleed:boolean;override;
    procedure UseCard;override;
  public
    Color1,Color2:CardColor;
  end;


  TBlueForbid = class(TForbidCard)
  end;
  TGreenForbid = class(TForbidCard)
  end;
  TRedForbid = class(TForbidCard)
  end;
  TYellowForbid = class(TForbidCard)
  end;
  TBlueReverse = class(TReverseCard)
  end;
  TGreenReverse = class(TReverseCard)
  end;
  TRedReverse = class(TReverseCard)
  end;
  TYellowReverse = class(TReverseCard)
  end;



var
  CardList:array[1..CARD_RANGE]of TCard;
  CardNumber:CardNo;
  i:integer;

implementation

uses player,main,Apiglio_Useful;

function CardNum(card:TCard):single;
begin
  if card is TNumberCard then
    begin
      if (card as TNumberCard).number = 0 then result:=0.5
      else result:=(card as TNumberCard).number;
    end
  else if card is TEquipmentCard then
    begin
      if (card as TEquipmentCard).number = 0 then result:=0.5
      else result:=(card as TEquipmentCard).number;
    end
  else result:=0;
end;


constructor TCard.Create(pid:CardNo;pcolor:CardColor);
begin
  inherited Create;
  id:=pid;
  color:=pcolor;
  location:=nil;
  be_wasted:=true;
  locked_round:=0;
end;

procedure TCard.MoveTo(destination:TObject);
begin
  if not (destination is TCardSet) then
    begin
      Err.message:='TCard.MoveTo|Error';
      raise Exception.Create('TCard不能移动至非牌堆对象。');
      exit
    end;
  if location<>nil then
    begin
      location.Remove(Self);
      cmd.writeln('TCard.MoveTo【'+Self.name+'】'+location.typename+'->'+(destination as TCardSet).typename);
    end
  else
    begin
      cmd.writeln('TCard.MoveTo【'+Self.name+'】'+'nil->'+(destination as TCardSet).typename);
    end;
  location:=destination as TCardSet;
  (destination as TCardSet).addCard(Self);
end;
procedure TCard.MoveToFirst(destination:TObject);
begin
  if not (destination is TCardSet) then
    begin
      Err.message:='TCard.MoveTo|Error';
      raise Exception.Create('TCard不能移动至非牌堆对象。');
      exit
    end;
  if location<>nil then
    begin
      location.Remove(Self);
      cmd.writeln('TCard.MoveTo【'+Self.name+'】'+location.typename+'->'+(destination as TCardSet).typename);
    end
  else
    begin
      cmd.writeln('TCard.MoveTo【'+Self.name+'】'+'nil->'+(destination as TCardSet).typename);
    end;
  location:=destination as TCardSet;
  (destination as TCardSet).addCardFirst(Self);
end;
procedure TCard.MoveToStack;
begin
  location.Remove(Self);
  location:=Desktop.Usage_Stack;
  Desktop.Usage_Stack.addCardFirst(Self);
end;

procedure TCard.SetUser(PlayerObj:TObject);
begin
  if PlayerObj is TPlayer then usage.user:=PlayerObj
  else usage.user:=nil;
end;
procedure TCard.SetTarget(TargetObj:TObject);
begin
  if TargetObj is TPlayer then usage.target:=TargetObj
  else if TargetObj is TCard then usage.target:=TargetObj
  else if TargetObj is TCardSet then usage.target:=TargetObj
  else usage.target:=nil;
end;
procedure TCard.SetUseColor(pcolor:CardColor);
begin
  Self.usage.color:=pcolor;
end;
procedure TCard.DefineUserColor;
begin
  Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
end;

procedure TCard.Used;
begin

  //Desktop.Usage_Stack.remove(Self);
  //location.remove(Self);
  //Desktop.discard.addCard(Self);
  //location:=Desktop.discard;

  if not Self.be_wasted then
    begin
      Self.MoveTo(Self.stack.from);
    end
  else if ((Self is TNumberCard) and (Self.usage.color=CC_blue)) or
  ((Self is TReverseCard) and (Self.usage.color in [CC_green,CC_blue,CC_red])) then
    begin
      Self.MoveToFirst((Self.usage.target as TPlayer).ForeCard);
    end
  else
    begin
      Self.MoveTo(Desktop.discard);
    end;
  Self.be_wasted:=true;

  //usage.user:=nil;
  //usage.target:=nil;
  //usage.color:=color;

end;


function TCard.PutCard:boolean;
begin
  cmd.writeln('TCard.PutCard【'+Self.name+'】'{+'->'+destination});
  if not (Self.usage.target is TCardSet) then begin Err.message:='TCard.PutCard|Error';raise Exception.Create('PutCard的目标对象必须为TCardSet')end;
  if ((Self.usage.target as TCardSet).typename='defend') then
    begin
      if (Self.usage.user as TPlayer).ColorChangeRestDefend>0 then dec((Self.usage.user as TPlayer).ColorChangeRestDefend)
      else begin
        if ((Self.usage.user as TPlayer).RestDefend<=0) and (Self.usage.user as TPlayer).firstround then
          begin result:=false;exit end
        else
          dec((Self.usage.user as TPlayer).RestDefend);
      end;
    end;
  Self.MoveTo(Self.usage.target);
  result:=true;
end;

function TCard.Exchange:TCard;
var tmp:TCard;
begin
  cmd.writeln('TCard.Exchange【'+Self.name+'】'{+'->'+destination});
  Self.MoveTo(Desktop.discard);
  //Self.location:=Desktop.discard;
  tmp:=Desktop.deal;
  tmp.MoveTo((Self.usage.user as TPlayer).desktop.hand);
  result:=tmp;
  //Self.Used;
end;
function TCard.PlayCard:boolean;
begin
  if not Self.AtPosition then begin result:=false;exit end;
  Self.stack.from:=Self.location;
  Self.MoveToStack;
end;


constructor TNumberCard.Create(pid:CardNo;pcolor:CardColor;pnumber:byte);
begin
  inherited Create(pid,pcolor);
  number:=pnumber;
end;

procedure TNumberCard.Used;
begin
  usage.number:=number;
  inherited Used;
end;
{
function TNumberCard.PlayCard:boolean;
begin
  //
  inherited PlayCard;
end;
}
procedure TNumberCard.UseCard;//数字牌使用效果
begin
  cmd.writeln('TNumberCard.UseCard【'+Self.name+'】'{+'->'+destination});

  case Self.usage.color of
    CC_Red://使用者为TPlayer，使用对象无意义
      begin
        //Self.MoveTo(Desktop.discard);
        (Self.usage.user as TPlayer).VitalBloodCard:=false;
        (Self.usage.user as TPlayer).decBleed(Self.usage.number);
      end;
    CC_Green://使用者为TPlayer，使用对象无意义
      begin
        //Self.MoveTo(Desktop.discard);
        (Self.usage.user as TPlayer).VitalDefendCard:=false;
        (Self.usage.user as TPlayer).decAttack(Self.usage.number);
      end;
    CC_Blue://使用者为TPlayer，使用对象为TPlayer
      begin
        //Self.MoveTo(Desktop.discard);
        (Self.usage.target as TPlayer).setAttack(Self.usage.number);
      end;
  end;
  Self.Used;
end;

procedure TNumberCard.DefineUserColor;
begin
  inherited DefineUserColor;
  if Self.usage.color = CC_Yellow then
    begin
      case Self.location.typename of
        'attack':Self.SetUseColor(CC_Blue);
        'defend':Self.SetUseColor(CC_Green);
        else exit;
      end;
    end;
end;

function TNumberCard.IsTargetOf(Card:Tcard):boolean;
begin
  if Card is TEquipmentCard then
    begin
      if Card.usage.color = Self.usage.color then begin result:=true;exit end;
      if Card.usage.color = CC_Black then begin result:=true;exit end;
    end
  else if Card is TFunctionCard then
    begin
      if (Self.usage.color = CC_Blue) and (Card is TBlueForbid) then begin result:=true;exit end;
      if (Self.usage.color = CC_Red) and (Card is TRedForbid) then begin result:=true;exit end;
    end;
  result:=false;
end;

function TNumberCard.CanPlayInDefendRound:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  //Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  result:=false;
end;
function TNumberCard.CanPlayInAttackRound:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  //Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  if Self.usage.color in [CC_Blue{,CC_Yellow}] then result:=true else result:=false;
end;
function TNumberCard.CanPlayOnDefend:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  //Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  if Self.usage.color in [CC_Green{,CC_Yellow}] then result:=true else result:=false;
end;
function TNumberCard.CanPlayOnBleed:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  //Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  if Self.usage.color = CC_Red then result:=true else result:=false;
end;
function TNumberCard.AtPosition:boolean;
begin
  if not (Self.usage.user = Self.location.owner) then begin result:=false;exit end;
  case Self.usage.color of
    CC_black:begin result:=false;exit end;
    CC_Red:begin
             if Self.location.typename <> 'blood' then result:=false
             else result:=true;
             exit
           end;
    CC_Blue:begin
             if Self.location.typename <> 'attack' then result:=false
             else result:=true;
             exit
           end;
    CC_Green:begin
             if Self.location.typename <> 'defend' then result:=false
             else result:=true;
             exit
           end;
    CC_Yellow:begin result:=false;exit end;
    else begin result:=false;exit end;
    end;
end;
function TNumberCard.ParamCheck:boolean;
begin
  result:=true;
  if not (Self.usage.user is TPlayer) then begin result:=false;exit end;
  case Self.usage.color of
    CC_black:result:=false;
    CC_Red:begin
             if (Self.usage.user as TPlayer).ForeCard.total=0 then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户来源区无牌');
                 exit
               end;
             if ((Self.usage.user as TPlayer).ForeCard.first.card as TCard).usage.target <> Self.usage.user then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户来源区的牌对象不是用户');
               end;
           end;
    CC_Blue:begin
             if not (Self.usage.target is TPlayer) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是玩家');
                 exit
               end;
             if (Self.usage.target as TPlayer).ForeCard.total <> 0 then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户来源区无牌');
               end;
             if not (Self.usage.target as TPlayer).firstround then result:=false;
           end;
    CC_Green:begin
             if (Self.usage.user as TPlayer).ForeCard.total=0 then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户来源区无牌');
                 exit
               end;
             if ((Self.usage.user as TPlayer).ForeCard.first.card as TCard).usage.target <> Self.usage.user then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户来源区的牌对象不是用户');
               end;
           end;
    CC_Yellow:result:=false;
    else result:=false;
  end;
end;

{TEquipmentCard}

procedure TEquipmentCard.SetTarget(TargetObj:TObject);
begin
  {
  if not (TargetObj is TCard) then begin
    cmd.writeln('TEquipmentCard.SetTarget: non-card object cannot be target of EquipmentCard');
    inherited SetTarget(nil);
  end else
  }
  inherited SetTarget(TargetObj);
end;
{
function TEquipmentCard.PlayCard:boolean;
begin
  //
  inherited PlayCard;
end;
}
procedure TEquipmentCard.Used;
begin
  inherited Used;
  usage.number:=number;

end;

procedure TEquipmentCard.UseCard;
begin
  cmd.writeln('TEquipmentCard.UseCard【'+Self.name+'】');

  (Self.usage.target as TCard).Usage_Number:=(Self.usage.target as TCard).Usage_Number+Self.Number;

  Self.Used;
end;

procedure TEquipmentCard.DefineUserColor;
begin
  inherited DefineUserColor;
  if not (Self.usage.target is TNumberCard) then exit;
  if Self.usage.color = CC_Yellow then
    begin
      case (Self.usage.target as TNumberCard).Usage_Color of
        CC_Blue:Self.SetUseColor(CC_Blue);
        CC_Green:Self.SetUseColor(CC_Green);
        else exit;
      end;
    end;
end;

function TEquipmentCard.IsTargetOf(Card:Tcard):boolean;
begin
  if Card is TYellowForbid then
    begin
      result:=true;
      exit
    end;
  result:=false;
end;
function TEquipmentCard.CanPlayInDefendRound:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  result:=false;
end;
function TEquipmentCard.CanPlayInAttackRound:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  result:=false;
end;
function TEquipmentCard.CanPlayOnDefend:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  result:=false;
end;
function TEquipmentCard.CanPlayOnBleed:boolean;
begin
  if not (usage.user is TPlayer) then begin result:=false;exit end;
  Self.usage.color:=(usage.user as TPlayer).Card2UsageColor(Self.color);
  result:=false;
end;
function TEquipmentCard.AtPosition:boolean;
begin
  if Self.location.owner <> Self.usage.user then begin result:=false;exit end;
  if (Self.location.typename <> 'restrict') and (Self.location.typename <> 'blood') then result:=true
  else result:=false;
end;
function TEquipmentCard.ParamCheck:boolean;
begin
  result:=true;
  if not (Self.usage.user is TPlayer) then begin result:=false;exit end;
  if not (Self.usage.target is TCard) then
    begin
      result:=false;
      cmd.writeln('ParamCheck('+Self.name+'): 对象不是牌');
      exit
    end;
  if (Self.usage.target as TCard).location <> Desktop.usage_stack then
    begin
      result:=false;
      cmd.writeln('ParamCheck('+Self.name+'): 对象牌不在结算栈');
      exit
    end;
  if not ((Self.usage.target as TCard) is TNumberCard) then
    begin
      result:=false;
      cmd.writeln('ParamCheck('+Self.name+'): 对象牌不是数字牌');
      exit
    end;
  case Self.usage.color of
    CC_black:result:=false;
    CC_Red,CC_Blue,CC_Green:
      begin
        if (Self.usage.target as TCard).usage.color <> Self.usage.color then
          begin
            result:=false;
            cmd.writeln('ParamCheck('+Self.name+'): 对象牌颜色与自身颜色不符');
          end;
      end;
    CC_Yellow:;//啥也不用做
    else result:=false;
  end;
end;
constructor TEquipmentCard.Create(pid:CardNo;pcolor:CardColor;pnumber:byte);
begin
  inherited Create(pid,pcolor);
  number:=pnumber;
end;



function TColorChangeCard.IsTargetOf(Card:Tcard):boolean;
begin
  if Card is TYellowForbid then
    begin
      result:=true;
      exit
    end;
  result:=false;
end;
function TColorChangeCard.AtPosition:boolean;
begin
  if Self.location.owner <> Self.usage.user then begin result:=false;exit end;
  if Self.location.typename = 'hand' then result:=true
  else result:=false;
end;
function TColorChangeCard.ParamCheck:boolean;
begin
  result:=true;
  if not (Self.usage.user is TPlayer) then begin result:=false;exit end;
  if Color1 in [CC_Red,CC_Blue,CC_Green,CC_Yellow] then else result:=false;
  if Color2 in [CC_Red,CC_Blue,CC_Green,CC_Yellow] then else result:=false;

end;
function TColorChangeCard.CanPlayInDefendRound:boolean;
begin
  result:=true;
end;
function TColorChangeCard.CanPlayInAttackRound:boolean;
begin
  result:=false;
end;
function TColorChangeCard.CanPlayOnDefend:boolean;
begin
  result:=false;
end;
function TColorChangeCard.CanPlayOnBleed:boolean;
begin
  result:=false;
end;
procedure TColorChangeCard.UseCard;
begin
  case Color1 of
    CC_Red:(Usage.Target as TPlayer).color_symbol.Red:=color2;
    CC_Blue:(Usage.Target as TPlayer).color_symbol.Blue:=color2;
    CC_Green:(Usage.Target as TPlayer).color_symbol.Green:=color2;
    CC_Yellow:(Usage.Target as TPlayer).color_symbol.Yellow:=color2;
    else begin raise Exception.Create('TColorChangeCard.UseCard:不能改变黑色');exit end;
  end;
  case Color2 of
    CC_Red:(Usage.Target as TPlayer).color_symbol.Red:=color1;
    CC_Blue:(Usage.Target as TPlayer).color_symbol.Blue:=color1;
    CC_Green:(Usage.Target as TPlayer).color_symbol.Green:=color1;
    CC_Yellow:(Usage.Target as TPlayer).color_symbol.Yellow:=color1;
    else begin raise Exception.Create('TColorChangeCard.UseCard:不能改变黑色');exit end;
  end;
  Used;
end;


function TForbidCard.IsTargetOf(Card:Tcard):boolean;
begin
  case usage.color of
  CC_Green:
    begin
      if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
      if (Card.usage.color = CC_Yellow) and (Card is TReverseCard) then begin result:=true;exit end;
      result:=false;
    end;
  CC_Yellow:
    begin
      if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
      result:=false;
    end;
  CC_Blue:
    begin
      if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
      result:=false;
    end;
  CC_Red:
    begin
      if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
      result:=false;
    end;
  else result:=false;
  end;
end;
function TForbidCard.AtPosition:boolean;
begin
  if Self.location.owner <> Self.usage.user then begin result:=false;exit end;

  case Self.usage.color of
    CC_Yellow:if (Self.location.typename = 'attack') or (Self.location.typename = 'defend') then begin result:=true;exit end;
    CC_Green:if Self.location.typename = 'hand' then begin result:=true;exit end;
    CC_Blue:if (Self.location.typename = 'attack') or (Self.location.typename = 'defend') then begin result:=true;exit end;
    CC_Red:if (Self.location.typename = 'attack') or (Self.location.typename = 'defend') then begin result:=true;exit end;
  end;
  result:=false;
end;
function TForbidCard.ParamCheck:boolean;
begin
  result:=true;
  if not (Self.usage.user is TPlayer) then begin result:=false;exit end;
  case Self.usage.color of
    CC_black:result:=false;
    CC_Red:begin
             if not (Self.usage.target is TCard) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是牌');
                 exit
               end;
             if (Self.usage.target as TCard).usage.color <> CC_red then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象牌不是红色');
                 exit
               end;
             if (Self.usage.target as TCard).location<>Desktop.usage_stack then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象牌不在结算栈');
                 exit
               end;
           end;
    CC_Blue:begin
             if not (Self.usage.target is TCard) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是牌');
                 exit
               end;
             if (Self.usage.target as TCard).location<>Desktop.usage_stack then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象牌结算栈');
                 exit
               end;
             if ((Self.usage.target as TCard).usage.color = CC_Blue) and (Self.usage.target is TNumberCard) then
               begin
                 result:=true;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象牌{是}蓝数字牌');
                 exit
               end;
             if ((Self.usage.target as TCard).usage.color in [CC_Blue,CC_Green]) and (Self.usage.target is TReverseCard) then
               begin
                 result:=true;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象牌{是}蓝绿反');
                 exit
               end;
             cmd.writeln('ParamCheck('+Self.name+'): 对象牌不符合牌面要求');
             result:=false;//这里默认情况改为否定，蓝禁条件苛刻
           end;
    CC_Green:begin
             if not (Self.usage.target is TPlayer) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是玩家');
                 exit
               end;
           end;
    CC_Yellow:begin
             if not ( Self.usage.target is TFunctionCard) and not(Self.usage.target is TEquipmentCard) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是功能牌或装备牌');
                 exit
               end;
             if (Self.usage.target as TFunctionCard).location<>Desktop.usage_stack then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象牌不在结算栈');
                 exit
               end;
           end;
    else result:=false;
  end;
end;
function TForbidCard.CanPlayInDefendRound:boolean;
begin
  case Self.usage.color of
    CC_Yellow:result:=false;
    CC_Green:result:=true;
    CC_Blue:result:=false;
    CC_Red:result:=false;
  end;
  result:=false;
end;
function TForbidCard.CanPlayInAttackRound:boolean;
begin
  result:=false;
end;
function TForbidCard.CanPlayOnDefend:boolean;
begin
  result:=false;
end;
function TForbidCard.CanPlayOnBleed:boolean;
begin
  result:=false;
end;
procedure TForbidCard.UseCard;
begin
  case Self.usage.color of
    CC_Red:(Usage.Target as TCard).be_wasted:=false;
    CC_Blue:begin
      (Usage.Target as TCard).locked_round:=(Usage.Target as TCard).locked_round+1;
      (Usage.Target as TCard).MoveTo((Usage.Target as TCard).Stack.from);
    end;//蓝禁应该对牌
    CC_Green:begin
      RuleForm.PostRuleMessage(Rule_GreenForbidChoiceRound_begin,(Usage.Target as TPlayer).id,0);
    end;
    CC_Yellow:(Usage.Target as TCard).MoveTo(Desktop.discard);
  end;
  Used;
end;



function TReverseCard.IsTargetOf(Card:Tcard):boolean;
  begin
  case usage.color of
    CC_Red:
      begin
        if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
        result:=false;
      end;
    CC_Yellow:
      begin
        if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
        result:=false;
      end;
    CC_Blue:
      begin
        if (Card.usage.color = CC_Yellow) and (Card is TReverseCard) then begin result:=true;exit end;
        if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
       if (Card.usage.color = CC_Blue) and (Card is TForbidCard) then begin result:=true;exit end;
        result:=false;
      end;
    CC_Green:
      begin
        if (Card.usage.color = CC_Yellow) and (Card is TReverseCard) then begin result:=true;exit end;
        if (Card.usage.color = CC_Yellow) and (Card is TForbidCard) then begin result:=true;exit end;
        if (Card.usage.color = CC_Blue) and (Card is TForbidCard) then begin result:=true;exit end;
        result:=false;
      end;
    else result:=false;
    end;
  end;
function TReverseCard.AtPosition:boolean;
begin
  if Self.location.owner <> Self.usage.user then begin result:=false;exit end;

  case Self.usage.color of
    CC_Yellow:if (Self.location.typename = 'attack') or (Self.location.typename = 'defend') then begin result:=true;exit end;
    CC_Green:if (Self.location.typename = 'attack') or (Self.location.typename = 'defend') then begin result:=true;exit end;
    CC_Blue:if Self.location.typename = 'attack' then begin result:=true;exit end;
    CC_Red:if (Self.location.typename = 'attack') or (Self.location.typename = 'defend') then begin result:=true;exit end;
  end;
  result:=false;
end;
function TReverseCard.ParamCheck:boolean;
begin
  result:=true;
  if not (Self.usage.user is TPlayer) then begin result:=false;exit end;
  case Self.usage.color of
    CC_black:result:=false;
    CC_Red:begin
             if not (Self.usage.target is TPlayer) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是玩家');
                 exit
               end;
             if not (Self.usage.user as TPlayer).CanUseRedReverse then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户不能打出红反');
                 exit
               end;
           end;
    CC_Blue:begin
             if not (Self.usage.target is TPlayer) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是玩家');
                 exit
               end;
             if not (Self.usage.auxiliary_target is TCard) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 辅助对象不是牌');
                 exit
               end;
             if (((Self.usage.auxiliary_target as TCard).location as TCardSet).owner<>Self.usage.user)
             or (((Self.usage.auxiliary_target as TCard).location as TCardSet).typename<>'attack') then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 辅助牌不在用户蓝区');
                 exit
               end;
             if not (Self.usage.user as TPlayer).CanUseBlueReverse then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户不能打出蓝反');
                 exit
               end;
             if not (Self.usage.auxiliary_target as TPlayer).firstround then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象玩家没有进行过第一回合');
               end;
           end;
    CC_Green:begin
             if not (Self.usage.target is TPlayer) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是玩家');
                 exit
               end;
             if not (Self.usage.user as TPlayer).CanUseGreenReverse then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 用户不能打出绿反');
               end;
           end;
    CC_Yellow:begin
             if not (Self.usage.target is TFunctionCard) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不是功能牌');
                 exit
               end;
             if (Self.usage.target as TFunctionCard).location<>Desktop.usage_stack then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象不在结算栈');
                 exit
               end;
             if not ((Self.usage.target as TFunctionCard).usage.target = Self.usage.user) then
               begin
                 result:=false;
                 cmd.writeln('ParamCheck('+Self.name+'): 对象牌的原始对象不是用户');
               end;

           end;
    else result:=false;
  end;
end;
function TReverseCard.CanPlayInDefendRound:boolean;
begin
  result:=false;
end;
function TReverseCard.CanPlayInAttackRound:boolean;
begin
  result:=false;
end;
function TReverseCard.CanPlayOnDefend:boolean;
begin
  result:=false;
end;
function TReverseCard.CanPlayOnBleed:boolean;
begin
  result:=false;
end;
procedure TReverseCard.UseCard;
begin
  case Self.usage.color of
    CC_Red:(Self.Usage.Target as TPlayer).setBleed((Self.Usage_User as TPlayer).origin.bleed - (Self.Usage_User as TPlayer).need.bleed);
    CC_Blue:begin
      (Self.Usage.Target as TPlayer).setBleed((Self.usage.auxiliary_target as TCard).usage.number);
    end;
    CC_Green:(Usage.Target as TPlayer).setAttack((Self.Usage_User as TPlayer).origin.defend - (Self.Usage_User as TPlayer).need.defend);
    CC_Yellow:begin
      (Self.Usage.Target as TCard).usage.user:=Self.usage.user;
      (Self.Usage.Target as TCard).usage.target:=Self.usage.auxiliary_target;
    end;
  end;
  Used;
end;







initialization

  //数字牌初始化

  //1-108为标准的一副牌
  //有可能添加其他临时代用牌，临时代用牌的编号段为109-216，这部分仅为指针，需要使用时构造，CardUse以后立即析构。
  //临时牌包括赠送的0血牌和蓝色反击造成的攻击的假想蓝色数字牌等

  for i:=1 to 4 do
  begin
    for CardNumber:=33 to 51 do
      begin
        CardList[CardNumber+(i-1)*19]:=TNumberCard.Create(CardNumber+(i-1)*19,CardColor(i),trunc((52-CardNumber) div 2));
        CardList[CardNumber+(i-1)*19].name:=Usf.i_to_s(trunc((52-CardNumber) div 2));
        case i of
          byte(CC_blue):CardList[CardNumber+(i-1)*19].name:='蓝'+CardList[CardNumber+(i-1)*19].name;
          byte(CC_red):CardList[CardNumber+(i-1)*19].name:='红'+CardList[CardNumber+(i-1)*19].name;
          byte(CC_green):CardList[CardNumber+(i-1)*19].name:='绿'+CardList[CardNumber+(i-1)*19].name;
          byte(CC_yellow):CardList[CardNumber+(i-1)*19].name:='黄'+CardList[CardNumber+(i-1)*19].name;

        end;
      end;
  end;
  for i:=1 to 4 do
    begin
      CardList[i]:=TColorChangeCard.Create(i,CardColor(0));
      CardList[i].name:='变色';
    end;
  for i:=5 to 8 do
    begin
      CardList[i]:=TEquipmentCard.Create(i,CardColor(0),4);
      CardList[i].name:='黑+4';
      (CardList[i] as TEquipmentCard).number:=4;
    end;


  CardList[9]:=TEquipmentCard.Create(9,CardColor(1),2);
  CardList[10]:=TEquipmentCard.Create(10,CardColor(1),2);
  CardList[11]:=TEquipmentCard.Create(11,CardColor(2),2);
  CardList[12]:=TEquipmentCard.Create(12,CardColor(2),2);
  CardList[13]:=TEquipmentCard.Create(13,CardColor(3),2);
  CardList[14]:=TEquipmentCard.Create(14,CardColor(3),2);
  CardList[15]:=TEquipmentCard.Create(15,CardColor(4),2);
  CardList[16]:=TEquipmentCard.Create(16,CardColor(4),2);
  CardList[9].name:='绿+2';
  CardList[10].name:='绿+2';
  CardList[11].name:='黄+2';
  CardList[12].name:='黄+2';
  CardList[13].name:='蓝+2';
  CardList[14].name:='蓝+2';
  CardList[15].name:='红+2';
  CardList[16].name:='红+2';
  for i:=9 to 16 do
    begin
      (CardList[i] as TEquipmentCard).number:=2;
    end;

  CardList[17]:=TGreenForbid.Create(17,CardColor(1));
  CardList[18]:=TGreenForbid.Create(18,CardColor(1));
  CardList[19]:=TYellowForbid.Create(19,CardColor(2));
  CardList[20]:=TYellowForbid.Create(20,CardColor(2));
  CardList[21]:=TBlueForbid.Create(21,CardColor(3));
  CardList[22]:=TBlueForbid.Create(22,CardColor(3));
  CardList[23]:=TRedForbid.Create(23,CardColor(4));
  CardList[24]:=TRedForbid.Create(24,CardColor(4));
  CardList[17].name:='绿禁';
  CardList[18].name:='绿禁';
  CardList[19].name:='黄禁';
  CardList[20].name:='黄禁';
  CardList[21].name:='蓝禁';
  CardList[22].name:='蓝禁';
  CardList[23].name:='红禁';
  CardList[24].name:='红禁';

  CardList[25]:=TGreenReverse.Create(25,CardColor(1));
  CardList[26]:=TGreenReverse.Create(26,CardColor(1));
  CardList[27]:=TYellowReverse.Create(27,CardColor(2));
  CardList[28]:=TYellowReverse.Create(28,CardColor(2));
  CardList[29]:=TBlueReverse.Create(29,CardColor(3));
  CardList[30]:=TBlueReverse.Create(30,CardColor(3));
  CardList[31]:=TRedReverse.Create(31,CardColor(4));
  CardList[32]:=TRedReverse.Create(32,CardColor(4));
  CardList[25].name:='绿反';
  CardList[26].name:='绿反';
  CardList[27].name:='黄反';
  CardList[28].name:='黄反';
  CardList[29].name:='蓝反';
  CardList[30].name:='蓝反';
  CardList[31].name:='红反';
  CardList[32].name:='红反';


  for i:=0 to PLAYER_RANGE do
    begin
      CardList[109+i]:=TNumberCard.Create(i+109,CC_Red,0);
      CardList[109+i].name:='虚拟红0';
    end;
  //虚拟的“0”

end.

