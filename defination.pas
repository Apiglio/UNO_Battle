{$define TEST}


unit defination;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows;

const
  PLAYER_RANGE = 1;
  CARD_RANGE = 216;




  {规则主机 -> 显示端}
  Msg_Display_MoveCard = WM_USER + 10;//移动牌
  //在CardDisplayForm中显示牌的移动 wParam = Card.Id lParam = CardSet
  //牌桌：牌堆= -1  弃牌堆= -2  结算堆= -3
  //玩家[00-70]：手牌=1 备战区=2 防御区=3 血牌区=4 限制区=5

  Msg_Display_ShowCard = WM_USER + 11;//展示牌
  Msg_Display_HideCard = WM_USER + 12;//掩盖牌
  Msg_Display_SendChat = WM_USER + 13;//发送聊天


  Msg_Control_Attack = WM_USER + 20;  //使用数字牌攻击 (w = 牌id ,l = 玩家id)
  Msg_Control_Put = WM_USER + 21;     //将牌放置在某区域 (w = 牌id ,l = 位置)
  Msg_Control_Exchange = WM_USER + 22;//置换手牌 (w = 牌id ,l = 玩家id)
  Msg_Control_Show = WM_USER + 23;    //展示指定牌 (w = 牌id ,l = 展示对象)
  Msg_Control_Defend = WM_USER + 24;  //使用数字牌防御 (w = 牌id)
  Msg_Control_Bleed = WM_USER + 25;   //使用数字牌掉血 (w = 牌id)
  Msg_Control_Functional_Player = WM_USER + 26;//使用效果牌 (w = 牌id ,l = 玩家id)
  Msg_Control_Functional_Card = WM_USER + 27;//使用装备牌 (w = 牌id ,l = 牌id)
  Msg_Control_Choice = WM_USER + 28;  //做出选择 (w = 选项)
  Msg_Control_Chat = WM_USER + 29;    //发送聊天 (w = 聊天对象)

  Msg_Err_ErrorCode = WM_USER + 40;//发送错误代码 (w = 错误代码)
  Msg_Err_GetDesktopRequest = WM_USER + 41;//掉线后同步数据请求 (w = 玩家id)
  Msg_Err_ReIntroduce_begin = WM_USER + 42;//客户端同步开始
  Msg_Err_ReIntroduce_end = WM_USER + 43;//客户端同步结束



  {客户端 -> 规则主机}
  Msg_Default = WM_USER + 200;
  //玩家确认(wParam = PlayerNo. lParam = 0)
  //玩家选择 (wParam = PlayerNo. lParam = 选项)

  Msg_PlayCard = WM_USER + 201;//玩家出牌(w=playerNo. l=Card)
  Msg_PutCard = WM_USER + 202;//玩家放置(w=playerNo. l=Card)
  Msg_Exchange = WM_USER + 203;//玩家置换牌(w=playerNo. l=Card)
  Msg_ReturnHand = WM_USER + 204;//玩家回手(w=playerNo. l=Card)


  {可能删除}Msg_AttackCard = WM_USER + 291;//wParam = PlayerNo. lParam = Card
  {可能删除}Msg_DefendCard = WM_USER + 292;//wParam = PlayerNo. lParam = Card

  Msg_AttackEnd = WM_USER + 221;//wParam = PlayerNo.
  Msg_DefendEnd = WM_USER + 222;//wParam = PlayerNo.
  Msg_BloodEnd = WM_USER + 223;//wParam = PlayerNo.

  Msg_DoNotDefend = WM_USER + 245;//玩家放弃继续防御 wParam = PlayerNo.
  Msg_DoNotBleed = WM_USER + 246;//玩家放弃继续掉血 wParam = PlayerNo.

  {
  Msg_DoNotCounterGreen = WM_USER + 251;//玩家放弃超额防御反击 wParam = PlayerNo.
  Msg_DoNotCounterRed = WM_USER + 252;//玩家放弃血量结算反击 wParam = PlayerNo.
  Msg_DoNotCounterBlue = WM_USER + 253;//玩家放弃受到攻击后反击 wParam = PlayerNo.
  }
  Msg_DoNotCounter = WM_USER + 250;//玩家放弃反击 wParam = PlayerNo.



  {规则主机 -> 客户端}
  Msg_SendDeath = WM_USER + 400;//玩家阵亡

  Msg_SendHandCard = WM_USER + 401;//向指定玩家手牌发一张牌
  Msg_SendDefendCard = WM_USER + 402;//向指定玩家防御区发一张牌
  Msg_SendAttackCard = WM_USER + 403;//向指定玩家备战区发一张牌
  Msg_SendBloodCard = WM_USER + 404;//向指定玩家血牌区发一张牌
  Msg_SendRestrictCard = WM_USER + 405;//向指定玩家判定区发一张牌

  Msg_SendAttackRound = WM_USER + 411;//向一个玩家发送攻击阶段
  Msg_SendDefendRound = WM_USER + 412;//向一个玩家发送备战阶段
  {
  Msg_SendGreenCounterRound = WM_USER + 421;//向一个玩家发送绿色反击阶段 wParam = 反击数额
  Msg_SendBlueCounterRound = WM_USER + 422;//向一个玩家发送蓝色反击阶段 wParam = 可能存在的反击上限或其他数值
  Msg_SendRedCounterRound = WM_USER + 423;//向一个玩家发送红色反击阶段 wParam = 反击数额
  }
  Msg_SendCounterRound = WM_USER + 420;//向一个玩家发送反击阶段 wParam = 反击数额

  Msg_SendColorChangeRound = WM_USER + 416;//向一个玩家发送第一个回合之前的变色阶段
  Msg_SendBloodCardRound = WM_USER + 417;//向一个玩家发送第一个回合之前的血牌明置阶段
  Msg_SendReturnHandRound = WM_USER + 418;//向一个玩家发送变色牌生效后的回手阶段


  Msg_SendDefendNeed = WM_USER + 431;//向一个玩家发送防御要求 wParam = defendneed
  Msg_SendBleedNeed = WM_USER + 432;//向一个玩家发送掉血要求 wParam = bleedneed

  Msg_SendEquipNeed = WM_USER + 451;//向一个玩家发送装备要求
  Msg_SendFunctionNeed = WM_USER + 452;//向一个玩家发送使用功能牌要求

  {可能删除}Msg_SendPlaySuccess = WM_USER + 491;//先玩家发送出牌成功消息
  {可能删除}Msg_SendPlayFailed = WM_USER + 492;//先玩家发送出牌失败消息


  Msg_SendChoice = WM_USER + 600;//向玩家发送选择请求 wParam = 预设选项编号
  //1=绿禁选择
  //2=
  //3=

  Msg_Rule = WM_USER + 1000;//这条消息不使用

  {规则主机内部流程消息}

  Stack_NoEquippment = WM_USER + 50;
  Stack_StackConfirmed = WM_USER + 51;


  Rule_DealCard_begin = Msg_Rule + 101;//lParam为发几张牌
  Rule_DealCard = Msg_Rule + 102;//wParam为玩家编号，lParam为发几张牌，如果下一张牌发给玩家0则张数参数自减1
  Rule_DealCard_end = Msg_Rule + 109;

  Rule_ColorChangeRound_begin = Msg_Rule + 111;
  Rule_ColorChangeRound_end = Msg_Rule + 119;

  Rule_BloodCardRound_begin = Msg_Rule + 121;
  Rule_BloodCardRound = Msg_Rule + 122;//wParam=PlayerNo
  Rule_BloodCardRound_end = Msg_Rule + 129;

  Rule_SortPlayer = Msg_Rule +130;

  Rule_PlayerRound_begin = Msg_Rule + 200;//wParam=PlayerNo
  Rule_DefendRound_begin = Msg_Rule + 201;//wParam=PlayerNo
  Rule_AttackRound_begin = Msg_Rule + 202;//wParam=PlayerNo
  Rule_PlayerRound_end = Msg_Rule + 209;


  Rule_GreenForbidChoiceRound_begin = Msg_Rule + 300;//开始绿禁选择阶段 wParam=PlayerNo
  Rule_GreenForbidChoiceRound_end = Msg_Rule + 301;//结束绿禁选择阶段 wParam=PlayerNo

  Rule_ColorChangeReturnRound_begin = Msg_Rule + 302;//开始变色牌回手阶段 wParam=PlayerNo
  Rule_ColorChangeReturnRound_end = Msg_Rule + 303;//结束变色牌回手阶段 wParam=PlayerNo




type
  PlayerNo = 0..PLAYER_RANGE;
  CardNo = 0..CARD_RANGE;
  CardColor = (CC_Black=0,CC_Green=1,CC_Yellow=2,CC_Blue=3,CC_Red=4);
  TEvent = procedure(Sender:TObject)of object;


  { TCardUnit }
  TCardUnit = class(TObject)
  public
    card:TObject;
    next:TCardUnit;
    constructor Create(CardObj:TObject);
  end;

  { TCardSet }
  TCardSet = class(TObject)
  public
    first,last:TCardUnit;
    total:longint;
  public
    owner:TObject;
    typename:string;
  protected
    procedure AddLast(obj:TCardUnit);
    procedure AddFirst(obj:TCardUnit);
  public
    procedure AddCardLast(obj:TObject);
    procedure AddCard(obj:TObject);
    procedure AddCardFirst(obj:TObject);virtual;
    function ColorNumberPop(pcolor:CardColor):TObject;
    function Have(AClass:TClass):boolean;
    function Remove(obj:TObject):boolean;
    function RandomPop:TObject;
    function FirstPop:TObject;
    procedure Sort;
    {$ifdef TEST}
    procedure Print;
    {$endif}

    constructor Create(AOwner:TObject;ATypename:string);
  end;

  { TErr }
  TErr = class(TCardSet)
    message:string;
  end;


  TCardStack = class(TCardSet)
  protected
    NumberCard:TEvent;//当堆栈为一张且本张牌为数字牌时触发
    ChangeCard:TEvent;//当堆栈数量发生变化时触发，在前一个事件之后触发
  public
    property onNumberCard:TEvent read NumberCard write NumberCard;
    property onChangeCard:TEvent read ChangeCard write ChangeCard;

    procedure AddCardFirst(obj:TObject);override;
    procedure ConfirmFirst;//确认最上面的一张牌的效果并执行结算
    procedure AskBroadcast;//确认最上面的一张牌的效果并执行结算


  end;

  function ColorName(Acolor:CardColor):string;

var Err:TErr;

implementation

uses main,Apiglio_Useful,card,player;

function ColorName(Acolor:CardColor):string;
begin
  case AColor of
    CC_Black:result:='黑';
    CC_Blue:result:='蓝';
    CC_Green:result:='绿';
    CC_Red:result:='红';
    CC_Yellow:result:='黄';
    else result:='NA';
  end;
end;

{ TCardUnit }
constructor TCardUnit.Create(CardObj:TObject);
begin
  inherited Create;
  card:=CardObj;
end;

{ TCardSet }
constructor TCardSet.Create(AOwner:TObject;ATypename:string);
begin
  inherited Create;
  total:=0;
  first:=nil;
  last:=nil;
  owner:=AOwner;
  typename:=ATypename;
end;

procedure TCardSet.AddLast(obj:TCardUnit);
begin
  if first=nil then begin
    first:=obj;
  end
  else begin
    last.next:=obj;
  end;
  last:=obj;
  total:=total+1;
end;
procedure TCardSet.AddFirst(obj:TCardUnit);
begin
  obj.next:=Self.first;
  Self.first:=obj;
  total:=total+1;
end;

procedure TCardSet.AddCardLast(obj:TObject);
var tmp:TCardUnit;
begin
  //cmd.writeln('addlast');
  if not (obj is TCard) then begin messagebox(0,'AddCard需要指定牌为参数','Error',MB_OK);exit end;
  tmp:=TCardUnit.Create(obj);
  Self.AddLast(tmp);
  //(obj as TCard).location:=Self;//这个不该放在这里，移至TCard.MoveTo
end;
procedure TCardSet.AddCard(obj:TObject);
begin
  AddCardFirst(obj);
end;
procedure TCardSet.AddCardFirst(obj:TObject);
var tmp:TCardUnit;
begin
  //cmd.writeln('addfirst');
  if not (obj is TCard) then begin messagebox(0,'AddCard需要指定牌为参数','Error',MB_OK);exit end;
  tmp:=TCardUnit.Create(obj);
  Self.AddFirst(tmp);
  //(obj as TCard).location:=Self;//这个不该放在这里，移至TCard.MoveTo
end;

function TCardSet.Remove(obj:TObject):boolean;
var tmp,tmp_old:TCardUnit;
begin
  //cmd.writeln('remove');
  if total=0 then begin result:=false end;
  tmp_old:=nil;
  tmp:=Self.first;
  repeat
    if tmp.card=obj then
      begin
        result:=true;
        if tmp_old=nil then first:=tmp.next
        else begin
          if tmp=nil then tmp_old.next:=nil
          else tmp_old.next:=tmp.next;
        end;
        tmp.Free;
        Self.total:=Self.total - 1;
        break;//也可以不退出，删除所有一样的元素，对于集合中没有重复元素的情况下去掉该语句只会降低运行速度，不影响运行结果
      end;
    tmp_old:=tmp;
    tmp:=tmp.next;
  until tmp=nil;
  result:=false;
end;

function TCardSet.ColorNumberPop(pcolor:CardColor):TObject;
var tmp,tmp_old:TCardUnit;
    found:boolean;
begin
  if Self.total=0 then begin result:=nil;exit end;
  tmp:=first;
  tmp_old:=nil;
  found:=false;
  while tmp<>nil do
    begin
      if ((tmp.card as TCard).color=pcolor) and (tmp.card is TNumberCard) then found:=true;
      if found then break;
      tmp_old:=tmp;
      tmp:=tmp.next;
    end;
  if found then
    begin
      result:=tmp.card;
      if tmp_old=nil then first:=tmp.next
      else begin
        if tmp=nil then tmp_old.next:=nil
        else tmp_old.next:=tmp.next;
      end;
      tmp.Free;
      total:=total-1;
    end
  else result:=nil;
end;

function TCardSet.Have(AClass:TClass):boolean;
var tmp,tmp_old:TCardUnit;
    found:boolean;
begin
  if Self.total=0 then begin result:=false;exit end;
  tmp:=first;
  tmp_old:=nil;
  found:=false;
  while tmp<>nil do
    begin
      //cmd.writeln('TCardSet.Have:'+tmp.card.classname);
      if (tmp.card is AClass) then found:=true;
      if found then begin result:=true;exit end;
      tmp_old:=tmp;
      tmp:=tmp.next;
    end;
  result:=false;
end;

function TCardSet.RandomPop:TObject;
var rand:longint;
    tmp,tmp_old:TCardUnit;
begin
  if Self.total=0 then begin result:=nil;exit end;
  randomize;
  rand:=random(Self.total-1)+1;
  tmp_old:=nil;
  tmp:=Self.first;
  while rand<>0 do
    begin
      rand:=rand-1;
      if rand=0 then
        begin
          if tmp_old=nil then Self.first:=tmp.next
          else
            begin
              if tmp=nil then tmp_old.next:=nil
              else tmp_old.next:=tmp.next;
            end;
          result:=tmp.card;
          tmp.Free;
          total:=total-1;
          break;
        end;
      tmp_old:=tmp;
      tmp:=tmp.next;
    end;

end;

function TCardSet.FirstPop:TObject;
var tmp:TCardUnit;
begin
  if Self.total=0 then begin raise Exception.Create('空牌堆不能pop'); end;
  tmp:=Self.first;
  Self.first:=tmp.next;
  result:=tmp.card;
  tmp.free;
end;



procedure TCardSet.Sort;//单向链表目前用冒泡排序
var tmp_old,tmp1,tmp2,tmp_ex:TCardUnit;
begin

  if Self.total=1 then exit;
  if Self.total=2 then
    begin
      if (Self.first.Card as TCard).id > (Self.last.Card as TCard).id then
        begin
          Self.first.next:=nil;
          Self.last.next:=Self.first;
          tmp_ex:=Self.first;
          Self.first:=Self.last;
          Self.last:=tmp_ex;
        end;
      exit;
    end;

  tmp_old:=nil;
  tmp1:=Self.first;
  repeat
    tmp2:=tmp1.next;
    repeat
      if (tmp1.Card as TCard).id > (tmp2.Card as TCard).id then
        begin
          if tmp_old=nil then Self.first:=tmp2
          else tmp_old.next:=tmp2;
          tmp1.next:=tmp2.next;
          tmp2.next:=tmp1;
        end;
      tmp2:=tmp2.next;
    until tmp2=nil;
    tmp_old:=tmp1;
    tmp1:=tmp1.next;
  until tmp1=nil;
end;

{$ifdef TEST}
procedure TCardSet.Print;
var tmp:TCardUnit;
begin
  tmp:=Self.first;
  while tmp<>nil do
    begin
      cmd.writeln('CardId='+Usf.i_to_s((tmp.card as TCard).id));
      tmp:=tmp.next;
    end;
end;

{$endif}


{ TCardStack }

procedure TCardStack.AddCardFirst(obj:TObject);
begin
  (obj as TCard).stack.equipped:=false;
  (obj as TCard).stack.confirmed:=false;
  inherited AddCardFirst(obj);
  Self.AskBroadcast;
end;

procedure TCardStack.ConfirmFirst;
var pid:PlayerNo;
begin
  //cmd.writeln('confirmfirst');
  (Self.first.card as TCard).UseCard;
  if Self.total=0 then exit;
  Self.AskBroadcast;

end;

procedure TCardStack.AskBroadcast;
var pid:PlayerNo;
begin
  //cmd.writeln('askbroadcast');
  if Self.total=0 then exit;
  if (Self.first.card is TNumberCard) and (not (Self.first.card as TCard).stack.equipped) then
    begin
      RuleForm.InfoConfirm;
      for pid:=0 to PLAYER_RANGE do RuleForm.cfm_enable[pid]:=true;
      RuleForm.NextMessage(RuleForm.Handle,Stack_NoEquippment,0,0);
      for pid:=0 to PLAYER_RANGE do PostMessage(PlayerList[pid].client.hd,Msg_SendEquipNeed,0,0);
      exit
    end
  else
    begin
      RuleForm.InfoConfirm;
      for pid:=0 to PLAYER_RANGE do RuleForm.cfm_enable[pid]:=true;
      RuleForm.NextMessage(RuleForm.Handle,Stack_StackConfirmed,0,0);
      for pid:=0 to PLAYER_RANGE do PostMessage(PlayerList[pid].client.hd,Msg_SendFunctionNeed,0,0);
      exit
    end;
end;



initialization

Err:=TErr.Create(nil,'');
Err.message:='在这里写可能导致错误的备忘';



end.


{$undef TEST}
