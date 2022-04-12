//{$define insert}
{$define TEST}
{$define UseCardViewer}


unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Messages, Windows, LazUTF8{$ifndef insert}, Apiglio_Useful, defination, card, player, client, fcmd, cardviewer, CardDisplay{$endif};


type

  TDesktop = class(TObject)
    deck,discard:TCardSet;//牌堆、弃牌堆
    usage_stack:TCardStack;//牌结算栈
  public
    constructor Create;
    procedure shuffle;//洗牌
    function Deal:TCard;//发牌
  end;


  { TRuleForm }

  TRuleForm = class(TForm)
    Memo_cmd: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure Memo_cmdKeyPress(Sender: TObject; var Key: char);
  public
    next_message:record
      hd:hwnd;
      code:integer;
      wParam,lParam:dword;
    end;//下一个消息，由onAllConfirm事件的AllConfirmed函数发送
  protected
    confirm:array[0..PLAYER_RANGE]of record
      checked,enable:boolean;
    end;//玩家确认数组
    //event_stack:array[0..31]of TEvent;//事件压栈，默认为nil
    AllConfirm:TEvent;
    Special_Round:boolean;
    Selection:longint;//Msg_Default返回的选项
  protected
    procedure ts(str:string);
    procedure ts(str:string;dwd:dword);overload;
    procedure ts(str:string;dwd1,dwd2:dword);overload;

    function GetAllConfirm:TEvent;
    procedure SetAllConfirm(evt:TEvent);
    procedure CheckConfirm(playerN:PlayerNo;boo:boolean);//指定序号的玩家确认
    procedure EnableConfirm(playerN:PlayerNo;boo:boolean);//指定序号的玩家确认
    function IsConfirm(playerN:PlayerNo):boolean;//指定序号的玩家确认

  private
    //player:array[0..PLAYER_RANGE]of TPlayer;
  public

    procedure InfoConfirm;//玩家确认数组的初始，comfirm[]=[false,false]
    procedure PrintConfirm;//在cmd里头打印enable和checked的情况
    procedure NextMessage(_hd:hwnd;_code:integer;_wp,_lp:dword);


    function initative_player:playerNo;//返回可以主动出牌的玩家位序
    function initative_player_status:string;//返回主动玩家的所属阶段

    procedure PostRuleMessage(_code:integer;_wp,_lp:dword);//自己给自己发消息



    {
    //事件
    procedure PushEvent(evt:TEvent);//将当前事件压入栈中
    procedure PopEvent(evt:TEvent);//从栈中取得当前事件
    }

    property cfm_enable[index:PlayerNo]:boolean read IsConfirm write EnableConfirm;
    property cfm_checked[index:PlayerNo]:boolean write CheckConfirm;

    property onAllConfirm:TEvent read GetAllConfirm write SetAllConfirm;
    procedure AllConfirmed(Sender:TObject);

    //一次完整的主机响应：
      //初始化玩家确认数组
      //确认那些玩家需要进行响应
      //设置OnAllConfirm为下一个过程
      //发送向这些客户端发送消息


    //消息接收函数




    //流程函数

    procedure NoEquippment(var Msg:TMessage);message Stack_NoEquippment;
    procedure StackConfirmed(var Msg:TMessage);message Stack_StackConfirmed;

    procedure Confirm_Message(var Msg:TMessage);message Msg_Default;
    procedure PutCard(var Msg:TMessage);message Msg_PutCard;
    procedure PlayCard(var Msg:TMessage);message Msg_PlayCard;
    procedure Exchange(var Msg:TMessage);message Msg_Exchange;
    procedure ReturnHand(var Msg:TMessage);message Msg_ReturnHand;

    procedure DoNotDefend(var Msg:TMessage);message Msg_DoNotDefend;
    procedure DoNotBleed(var Msg:TMessage);message Msg_DoNotBleed;

    {
    procedure DoNotCounterGreen(var Msg:TMessage);message Msg_DoNotCounterGreen;
    procedure DoNotCounterRed(var Msg:TMessage);message Msg_DoNotCounterRed;
    procedure DoNotCounterBlue(var Msg:TMessage);message Msg_DoNotCounterBlue;
    }
    procedure DoNotCounter(var Msg:TMessage);message Msg_DoNotCounter;


    procedure DealCard_begin(var Msg:TMessage);message Rule_DealCard_begin;
    procedure DealCard_end(var Msg:TMessage);message Rule_DealCard_end;
    procedure DealCard(var Msg:TMessage);message Rule_DealCard;

    procedure ColorChangeRound_begin(var Msg:TMessage);message Rule_ColorChangeRound_begin;
    procedure ColorChangeRound_end(var Msg:TMessage);message Rule_ColorChangeRound_end;

    procedure BloodCardRound_begin(var Msg:TMessage);message Rule_BloodCardRound_begin;
    procedure BloodCardRound_end(var Msg:TMessage);message Rule_BloodCardRound_end;
    procedure BloodCardRound(var Msg:TMessage);message Rule_BloodCardRound;
    procedure BloodCardRound_BloodEnd(var Msg:TMessage);message Msg_BloodEnd;

    procedure SortPlayer(var Msg:TMessage);message Rule_SortPlayer;

    procedure PlayerRound_begin(var Msg:TMessage);message Rule_PlayerRound_begin;
    procedure AttackRound_begin(var Msg:TMessage);message Rule_AttackRound_begin;
    procedure AttackRound_end(var Msg:TMessage);message Msg_AttackEnd;
    procedure AttackRound_play_card(var Msg:TMessage);message Msg_AttackCard;//可能删除
    procedure DefendRound_begin(var Msg:TMessage);message Rule_DefendRound_begin;
    procedure DefendRound_end(var Msg:TMessage);message Msg_DefendEnd;
    procedure DefendRound_play_card(var Msg:TMessage);message Msg_DefendCard;//可能删除
    procedure PlayerRound_end(var Msg:TMessage);message Rule_PlayerRound_end;

    procedure GreenForbidChoiceRound_begin(var Msg:TMessage);message Rule_GreenForbidChoiceRound_begin;
    procedure GreenForbidChoiceRound_end(var Msg:TMessage);message Rule_GreenForbidChoiceRound_end;
    procedure ColorChangeReturnRound_begin(var Msg:TMessage);message Rule_ColorChangeReturnRound_begin;
    procedure ColorChangeReturnRound_end(var Msg:TMessage);message Rule_ColorChangeReturnRound_end;


  end;






var
  RuleForm: TRuleForm;
  //ClientForm:array[0..PLAYER_RANGE]of TClientForm;
  //playerList:array[0..PLAYER_RANGE]of TPlayer;
  Desktop:TDesktop;
  cmd:Tcmd;
  CardViewerForm:TCardViewerForm;

implementation


{$R *.lfm}

function PlayerExists(playerNo:dword):boolean;
begin
  result:=true;
  if PlayerNo>=PLAYER_RANGE then result:=false;
  if PlayerNo<0 then result:=false;

end;

procedure WriteCardList;
var i:byte;
begin
    for i:=1 to 108 do
    if CardList[i]<>nil then
    if CardList[i] is TFunctionCard then cmd.writeln(Usf.zeroplus(CardList[i].id,3)+':'+Usf.zeroplus(byte(CardList[i].color),3))
    else if CardList[i] is TNumberCard then cmd.writeln(Usf.zeroplus(CardList[i].id,3)+':'+Usf.zeroplus(byte(CardList[i].color),3)+','+Usf.zeroplus((CardList[i] as TNumberCard).number,3))
    else cmd.writeln(Usf.zeroplus(CardList[i].id,3)+':'+Usf.zeroplus(byte(CardList[i].color),3)+','+Usf.zeroplus((CardList[i]as TEquipmentCard).number,3));
end;

function GetHWND(str:utf8string):hwnd;
var tmp:hwnd;
    s:PChar;
begin
  tmp:=GetDesktopWindow;
  tmp:=GetWindow(tmp,GW_CHILD);
  repeat
    GetMem(s,200);
    GetWindowText(tmp,s,200);
    if wincptoutf8(s)=str then break;
    tmp:=GetWindow(tmp,GW_HWNDNEXT);
    FreeMem(s,0);
  until tmp=0;
  result:=tmp;
end;

{ TDesktop }

constructor TDesktop.Create;
begin
  deck:=TCardSet.Create(Self,'deck');
  discard:=TCardSet.Create(Self,'discard');
  usage_stack:=TCardStack.Create(Self,'usage_stack');

end;

procedure TDesktop.shuffle;
begin
  if Self.deck.total<>0 then begin cmd.writeln('牌堆有牌，不能洗牌！');exit end;
  deck.Free;
  deck:=discard;
  deck.typename:='deck';
  discard:=TCardSet.Create(Self,'discard');

end;

function TDesktop.deal:TCard;
begin
  result:=(Self.deck.randomPop as TCard);
  if Self.deck.total=0 then Self.shuffle;
end;

{ TRuleForm }

procedure TRuleForm.FormCreate(Sender: TObject);
var pid:PlayerNo;
    i:integer;
begin
  cmd:=Tcmd.Create(Application);
  cmd.Show;

  //{$undef UseCardViewer}
  {$ifdef UseCardViewer}
  CardViewerForm:=TCardViewerForm.CreateNew(Application);
  CardViewerForm.show;
  {$endif}

  Caption:='规则主机';
  //cmd.writeln('HWND of RuleForm='+Usf.i_to_s(Self.Handle));

  onAllConfirm:=@AllConfirmed;
  Special_Round:=false;

  for pid:=0 to PLAYER_RANGE do
    begin
      playerList[pid]:=TPlayer.Create(pid);
      playerList[pid].name:='玩家'+Usf.zeroplus(pid,3);
      ClientForm[pid]:=TClientForm.Create(Self,pid);
      ClientForm[pid].show;
      ClientForm[pid].Left:=30+(pid mod 3)*(ClientForm[pid].Width+20);
      ClientForm[pid].Top:= 50+(pid div 3)*(ClientForm[pid].Height+40);
      PlayerList[pid].client.form:=ClientForm[pid];

      //ClientForm[pid].hide;
      playerList[pid].client.hd:=ClientForm[pid].Handle;
      ClientForm[pid].self_hwnd:=playerList[pid].client.hd;
      ClientForm[pid].parent_hwnd:=Self.Handle;
      //cmd.writeln('HWND of ClientForm['+Usf.i_to_s(pid)+']='+Usf.i_to_s(PlayerList[pid].client.hd));
    end;

  Desktop:=TDesktop.Create;
  for i:=1 to 108 do
    begin
      //Desktop.deck.AddCardFirst(CardList[i]);
      CardList[i].MoveTo(Desktop.deck);
      //CardList[i].location:=Desktop.deck;
    end;

  //后面开始是临时测试代码


  //CardDisplayForm:=TCardDisplayForm.CreateNew(Application);
  //CardDisplayForm.show;
  //太恐怖了，界面先放一放

  PostMessage(RuleForm.Handle,Rule_DealCard_begin,0,(108-20) div (PLAYER_RANGE+1));
  //PostMessage(RuleForm.Handle,Rule_PlayerRound_begin,0,0);



end;

procedure TRuleForm.Memo_cmdKeyPress(Sender: TObject; var Key: char);
begin
  //////////
end;

procedure TRuleForm.PostRuleMessage(_code:integer;_wp,_lp:dword);
begin
  PostMessage(Self.Handle,_code,_wp,_lp);
end;

procedure TRuleForm.ts(str:string);
begin
  Self.Memo_cmd.lines.add(str);
end;
procedure TRuleForm.ts(str:string;dwd:dword);
begin
  Self.Memo_cmd.lines.add(str+':'+Usf.i_to_s(dwd));
end;
procedure TRuleForm.ts(str:string;dwd1,dwd2:dword);
begin
  Self.Memo_cmd.lines.add(str+':'+Usf.i_to_s(dwd1)+','+Usf.i_to_s(dwd2));
end;

procedure TRuleForm.AllConfirmed(Sender:TObject);
begin
  //cmd.writeln('onAllConfirm');
  with Self.next_message do PostMessage(hd,code,wParam,lParam);
end;

procedure TRuleForm.NextMessage(_hd:hwnd;_code:integer;_wp,_lp:dword);
begin
  with Self.next_message do
    begin
      hd:=_hd;
      code:=_code;
      wParam:=_wp;
      lParam:=_lp;
    end;
end;


function TRuleForm.GetAllConfirm:TEvent;
begin
  result:={Self.event_stack[0]}AllConfirm;
end;

procedure TRuleForm.SetAllConfirm(evt:TEvent);
begin
  {Self.event_stack[0]}AllConfirm:=evt;
end;

{
procedure TRuleForm.PushEvent(evt:TEvent);//将当前事件压入栈中
var i:byte;
begin
  if Self.event_stack[31]<>nil then begin messagebox(0,'事件栈已满','Error',MB_OK);exit end;
  for i:=31 downto 1 do Self.event_stack[i]:=Self.event_stack[i-1];
  Self.event_stack[0]:=nil;
end;

procedure TRuleForm.PopEvent(evt:TEvent);//从栈中取得当前事件
var i:byte;
begin
  if Self.event_stack[0]<>nil then begin messagebox(0,'当前事件非空，不能pop','Error',MB_OK);exit end;
  for i:=1 to 31 do Self.event_stack[i-1]:=Self.event_stack[i];
  Self.event_stack[31]:=nil;
end;
}


function TRuleForm.initative_player:playerNo;//返回可以主动出牌的玩家位序
var playerN:playerNo;
begin
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InDefend then begin result:=playerN;exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InBleed then begin result:=playerN;exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InCounterGreen then begin result:=playerN;exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InCounterRed then begin result:=playerN;exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InCounterBlue then begin result:=playerN;exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].Round then begin result:=playerN;exit end;
    end;
  ts('找不到主动玩家');
end;

function TRuleForm.initative_player_status:string;//返回主动玩家的所属阶段
var playerN:playerNo;
begin
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InDefend then begin result:='on_defend';exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InBleed then begin result:='on_bleed';exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InCounterGreen then begin result:='co_green';exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InCounterRed then begin result:='co_red';exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].InCounterBlue then begin result:='co_blue';exit end;
    end;
  for playerN:=0 to PLAYER_RANGE do
    begin
      if PlayerList[playerN].Round then
        begin
          if PlayerList[playerN].RoundStatus in [1,3,5] then result:='rd_defend'
          else if PlayerList[playerN].RoundStatus in [2,4] then result:='rd_attack'
          else result:='err_error';
          exit
        end;
    end;
  ts('找不到主动玩家');
end;



procedure TRuleForm.InfoConfirm;//玩家确认数组的初始，comfirm[]=[false,false]
var i:PlayerNo;
begin
  for i:=0 to PLAYER_RANGE do with Self.confirm[i] do
    begin
      checked:=false;
      enable:=false;
    end;

end;

procedure TRuleForm.PrintConfirm;//在cmd里头打印enable和checked的情况
var i:PlayerNo;
    s:string;
begin
  s:='checked=[';
  for i:=0 to PLAYER_RANGE do if confirm[i].checked then s:=s+'1' else s:=s+'0';
  s:=s+']';
  cmd.writeln(s);
  s:='enable=[';
  for i:=0 to PLAYER_RANGE do if confirm[i].enable then s:=s+'1' else s:=s+'0';
  s:=s+']';
  cmd.writeln(s);
end;

procedure TRuleForm.EnableConfirm(playerN:PlayerNo;boo:boolean);//指定玩家序号列入需等待玩家行列
begin
  Self.confirm[playerN].enable:=boo;
end;

function TRuleForm.IsConfirm(playerN:PlayerNo):boolean;//指定玩家序号列入需等待玩家行列
begin
  result:=Self.confirm[playerN].enable;
end;

procedure TRuleForm.CheckConfirm(playerN:PlayerNo;boo:boolean);//指定序号的玩家确认
var i:integer;
    all_confirm:boolean;
begin
  Self.confirm[playerN].checked:=boo;
  //{$ifdef TEST}PrintConfirm;{$endif}
  if not boo then exit;
  i:=playerN+1;
  all_confirm:=true;
  while all_confirm do
    begin
      if (Self.confirm[i mod (PLAYER_RANGE + 1)].enable) and (not Self.confirm[i mod (PLAYER_RANGE + 1)].checked)
      then all_confirm:=false;
      inc(i);
      if i > playerN + PLAYER_RANGE - 1 then break;
    end;
  if all_confirm then
    begin
      Self.OnAllConfirm(nil);
      Self.infoconfirm;
    end;
end;



procedure TRuleForm.NoEquippment(var Msg:TMessage);
begin
  ts('Stack_NoEquippment');
  (Desktop.Usage_Stack.first.card as TCard).stack.equipped:=true;
  Desktop.Usage_Stack.AskBroadcast;
end;

procedure TRuleForm.StackConfirmed(var Msg:TMessage);
begin
  ts('Stack_StackConfirmed');
  Desktop.Usage_Stack.ConfirmFirst;
end;

procedure TRuleForm.Confirm_Message(var Msg:TMessage);
var PlayerNumber:PlayerNo;
begin
  ts('Msg_Default',Msg.wParam,Msg.lParam);
  PlayerNumber:=Msg.wParam;
  if (PlayerNumber>PLAYER_RANGE) then exit;
  if (PlayerNumber<0) then exit;
  if cfm_enable[PlayerNumber]=false then exit;
  cfm_checked[PlayerNumber]:=true;
  Selection:=Msg.wParam;

end;
procedure TRuleForm.ReturnHand(var Msg:TMessage);
var CardId:CardNo;
    PlayerN:PlayerNo;
begin
  ts('Msg_ReturnHand',Msg.wParam,Msg.lParam);
  CardId:=Msg.lParam;
  PlayerN:=Msg.wParam;
  if not (PlayerList[PlayerN]=CardList[CardId].location.owner) then begin ts('玩家只能回手自己的牌');exit end;
  case CardList[CardId].location.typename of 'attack','defend':;else begin ts('玩家只能回手场上的牌');exit end;end;
  CardList[CardId].MoveTo(PlayerList[playerN].desktop.hand);
  if (CardList[CardId].location.typename<>'defend') then inc(PlayerList[PlayerN].ColorChangeRestDefend);
  if (CardList[CardId].location.typename<>'attack') then inc(PlayerList[PlayerN].ColorChangeRestAttack);
  PostMessage(PlayerList[PlayerN].client.hd,Msg_SendHandCard,CardId,0);
end;
procedure TRuleForm.Exchange(var Msg:TMessage);
var CardId:CardNo;
    PlayerN:PlayerNo;
    tmp:TCard;
begin
  ts('Msg_Exchange',Msg.wParam,Msg.lParam);
  CardId:=Msg.lParam;
  PlayerN:=Msg.wParam;
  if not (PlayerList[PlayerN]=CardList[CardId].location.owner) then begin ts('玩家只能置换自己的牌');exit end;
  if not (CardList[CardId].location.typename='hand') then begin ts('玩家只能置换手牌');exit end;
  tmp:=CardList[CardId].Exchange;
  PostMessage(PlayerList[PlayerN].client.hd,Msg_SendHandCard,tmp.id,0);
end;
procedure TRuleForm.PutCard(var Msg:TMessage);
var CardId:CardNo;
    PlayerN:PlayerNo;
begin
  ts('Msg_PutCard',Msg.wParam,Msg.lParam);
  //暂时没有考虑区域数量限制和玩家确认
  CardId:=Msg.lParam;
  PlayerN:=Msg.wParam;
  if not PlayerList[PlayerN].Round then begin ts('玩家不能在回合外放置牌');exit end;
  if not PlayerList[PlayerN].RoundStatus in [1,3,5] then begin ts('玩家不能在备战阶段外放置牌');exit end;
  if CardList[CardId].location<>PlayerList[PlayerN].desktop.hand then begin ts('玩家无该手牌');exit end;
  if not CardList[CardId].PutCard then ts('玩家剩余布防次数不足');

end;

procedure TRuleForm.PlayCard(var Msg:TMessage);
var CardId:CardNo;
    PlayerN:PlayerNo;
    initiative_status:string;
begin
  //cmd.writeln('playcard');
  ts('Msg_PlayerCard',Msg.wParam,Msg.lParam);
  CardId:=Msg.lParam;
  PlayerN:=Msg.wParam;
  //判定出牌是否有效
  //对象是玩家的牌只能在玩家回合内打出
  //对象是牌的牌只能在指向对象的牌是active的时候打出
  /////////////////////
  if Special_Round then begin ts('特殊过程中不能出牌');exit;end;

  CardList[CardId].DefineUserColor;//设置颜色
  if not CardList[CardId].ParamCheck then begin ts('参数设置不符合规则');exit end;
  if not CardList[CardId].AtPosition then begin ts('发起位置不符合规则');exit end;


  if Desktop.Usage_Stack.total=0 then
    begin
      if (CardList[CardId].Usage_Target is TPlayer) then
        begin
          if CardList[CardId].Usage_User <> PlayerList[Self.initative_player] then
            begin
              ts('非主动玩家不能在此时主动出牌');
            end;
          initiative_status:=Self.initative_player_status;
          delete(initiative_status,5,999);
          case initiative_status of
            'on_d':begin
                     if not CardList[CardId].CanPlayOnDefend
                     then begin ts('只能打绿色数字牌');exit end;
                   end;
            'on_b':begin
                     if not CardList[CardId].CanPlayOnBleed
                       then begin ts('只能打红色数字牌');exit end;
                   end;
            'co_g':begin
                     if not(CardList[CardId] is TReverseCard) or not(CardList[CardId].Usage_Color=CC_Green)
                       then begin ts('只能打绿色反击牌');exit end;
                   end;
            'co_r':begin
                     if not(CardList[CardId] is TReverseCard) or not(CardList[CardId].Usage_Color=CC_Red)
                       then begin ts('只能打红色反击牌');exit end;
                   end;
            'co_b':begin
                     if not(CardList[CardId] is TReverseCard) or not(CardList[CardId].Usage_Color=CC_Blue)
                       then begin ts('只能打蓝色反击牌');exit end;
                   end;
            'rd_a':begin
                     if not CardList[CardId].CanPlayInAttackRound
                       then begin ts('只能打蓝色数字牌');exit end;

                   end;
            'rd_d':begin
                     if not CardList[CardId].CanPlayInDefendRound
                       then begin ts('只能打变色或绿禁');exit end;
                   end;
            else begin ts('主动玩家状态未知');exit end
          end;
        end
      else if (CardList[CardId].Usage_Target is TCard) then
        begin
          ts('结算队列无牌，出牌对象不能是牌');
          exit
        end
      else begin MessageBox(0,'TRuleForm.PlayCard 未知的对象类型','Error',MB_OK);exit end;
    end
  else
    begin
      if (CardList[CardId].Usage_Target is TPlayer) then
        begin
          ts('结算队列有牌，不能打出指定玩家的牌');
          exit
        end
      else if (CardList[CardId].Usage_Target is TCard) then
        begin
          if not (Desktop.Usage_Stack.first.card as TCard).IsTargetOf(CardList[CardId]) then
            begin ts('牌使用对象不合要求');exit end;
        end
      else begin MessageBox(0,'TRuleForm.PlayCard 未知的对象类型','Error',MB_OK);exit end;
    end;

  if not CardList[CardId].PlayCard then ts('出牌失败：发起位置与牌面不符');       //Desktop.Usage_Stack.first.card  PlayerList

end;



procedure TRuleForm.DoNotDefend(var Msg:TMessage);
begin
  if not PlayerList[Msg.wParam].InDefend then begin ts('玩家不在防御过程中');exit end;
  ts('玩家放弃防御',Msg.wParam,Msg.lParam);
  PlayerList[Msg.wParam].InDefend:=false;
  PlayerList[Msg.wParam].VitalDefendCard:=false;
  PlayerList[Msg.wParam].setBleed(PlayerList[Msg.wParam].need.defend);
  PlayerList[Msg.wParam].need.defend:=0;
end;
procedure TRuleForm.DoNotBleed(var Msg:TMessage);
begin
  if not PlayerList[Msg.wParam].InBleed then begin ts('玩家不在掉血过程中');exit end;
  ts('玩家放弃掉血',Msg.wParam,Msg.lParam);
  PlayerList[Msg.wParam].InBleed:=false;
  PlayerList[Msg.wParam].VitalBloodCard:=false;
  PlayerList[Msg.wParam].need.bleed:=0;
  PlayerList[Msg.wParam].Death;
end;
{
procedure TRuleForm.DoNotCounterGreen(var Msg:TMessage);
begin
  ts('玩家放弃超额防御反击',Msg.wParam,Msg.lParam);
  if not PlayerList[Msg.wParam].InCounterGreen then begin ts('玩家不在超额防御反击过程中');exit end;
  PlayerList[Msg.wParam].need.defend:=0;
  PlayerList[Msg.wParam].origin.defend:=0;
  PlayerList[Msg.wParam].CanUseGreenReverse:=false;
  PlayerList[Msg.wParam].CanUseBlueReverse:=false;
  PlayerList[Msg.wParam].InCounterGreen:=false;
end;
procedure TRuleForm.DoNotCounterRed(var Msg:TMessage);
begin
  ts('玩家放弃掉血结算反击',Msg.wParam,Msg.lParam);
  if not PlayerList[Msg.wParam].InCounterRed then begin ts('玩家不在血量结算反击过程中');exit end;
  PlayerList[Msg.wParam].need.bleed:=0;
  PlayerList[Msg.wParam].origin.bleed:=0;
  PlayerList[Msg.wParam].CanUseRedReverse:=false;
  PlayerList[Msg.wParam].InCounterRed:=false;
end;
procedure TRuleForm.DoNotCounterBlue(var Msg:TMessage);
begin
  ts('玩家放弃掉血结算反击',Msg.wParam,Msg.lParam);
  if not PlayerList[Msg.wParam].InCounterBlue then begin ts('玩家不在受到攻击后反击过程中');exit end;
  PlayerList[Msg.wParam].need.bleed:=0;
  PlayerList[Msg.wParam].origin.bleed:=0;
  PlayerList[Msg.wParam].CanUseRedReverse:=false;
  PlayerList[Msg.wParam].InCounterRed:=false;
end;
}
procedure TRuleForm.DoNotCounter(var Msg:TMessage);
begin
  if (not PlayerList[Msg.wParam].InCounterBlue)
  and (not PlayerList[Msg.wParam].InCounterGreen)
  and (not PlayerList[Msg.wParam].InCounterRed)
  then begin ts('玩家不在受到攻击后反击过程中');exit end;

  ts('玩家放弃反击',Msg.wParam,Msg.lParam);
  PlayerList[Msg.wParam].need.bleed:=0;
  PlayerList[Msg.wParam].origin.bleed:=0;
  PlayerList[Msg.wParam].need.defend:=0;
  PlayerList[Msg.wParam].origin.defend:=0;
  PlayerList[Msg.wParam].CanUseRedReverse:=false;
  PlayerList[Msg.wParam].CanUseBlueReverse:=false;
  PlayerList[Msg.wParam].CanUseGreenReverse:=false;
  PlayerList[Msg.wParam].InCounterRed:=false;
  PlayerList[Msg.wParam].InCounterBlue:=false;
  PlayerList[Msg.wParam].InCounterGreen:=false;
  (PlayerList[Msg.wParam].ForeCard.first.card as TCard).MoveTo(Desktop.discard);
end;

procedure TRuleForm.DealCard_begin(var Msg:TMessage);
begin
  ts('发牌过程开始',Msg.wParam,Msg.lParam);
  cmd.writeln('DealCardRound');
  PostMessage(Self.Handle,Rule_DealCard,0,Msg.lParam);
end;

procedure TRuleForm.DealCard_end(var Msg:TMessage);
begin
  ts('发牌过程结束',Msg.wParam,Msg.lParam);
  PostMessage(RuleForm.Handle,Rule_ColorChangeRound_begin,0,0);
end;

procedure TRuleForm.DealCard(var Msg:TMessage);
var playerN:PlayerNo;
    Card:TCard;
begin
  ts('发牌一张牌',Msg.wParam,Msg.lParam);
  PlayerN:=Msg.wParam;
  InfoConfirm;
  Self.cfm_enable[Msg.wParam]:=true;
  if PlayerN=PLAYER_RANGE then
    begin
      case Msg.lParam of
        1:NextMessage(Self.Handle,Rule_DealCard_end,0,0);
        else NextMessage(Self.Handle,Rule_DealCard,0,Msg.lParam-1);
      end;
    end
  else
    begin
      NextMessage(Self.Handle,Rule_DealCard,PlayerN+1,Msg.lParam);
    end;
  Card:=Desktop.Deal;
  Card.MoveTo(PlayerList[PlayerN].desktop.hand);
  SendMessage(PlayerList[PlayerN].client.hd,Msg_SendHandCard,Card.id,0);
end;


procedure TRuleForm.ColorChangeRound_begin(var Msg:TMessage);
var i:PlayerNo;
begin
  ts('变色回合开始',Msg.wParam,Msg.lParam);
  cmd.writeln('ColorChangeRound');
  //Self.infoConfirm;
  for i:=0 to PLAYER_RANGE do
    begin
      cfm_enable[i]:=true;
      PlayerList[i].Round:=true;
    end;
  //printConfirm;
  NextMessage(RuleForm.Handle,Rule_ColorChangeRound_end,0,0);
  for i:=0 to PLAYER_RANGE do
    begin
      PostMessage(PlayerList[i].client.hd,Msg_SendColorChangeRound,0,0);
    end;
end;

procedure TRuleForm.ColorChangeRound_end(var Msg:TMessage);
var i:PlayerNo;
begin
  ts('变色回合结束',Msg.wParam,Msg.lParam);
  for i:=0 to PLAYER_RANGE do
    begin
      PlayerList[i].Round:=false;
    end;
  PostMessage(Self.Handle,Rule_BloodCardRound_begin,0,0);
end;

procedure TRuleForm.BloodCardRound_begin(var Msg:TMessage);
begin
  cmd.writeln('BloodCardRound');
  ts('血牌放置回合开始',Msg.wParam,Msg.lParam);
  PostMessage(Self.Handle,Rule_BloodCardRound,0,0);
end;

procedure TRuleForm.BloodCardRound_end(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  ts('血牌放置回合结束',Msg.wParam,Msg.lParam);
  //虚拟〇血牌设置
  for PlayerN:=0 to PLAYER_RANGE do
    if PlayerList[PlayerN].desktop.blood.total=0 then
      CardList[109+PlayerN].MoveTo(PlayerList[PlayerN].desktop.blood);
  {
  for PlayerN:=0 to PLAYER_RANGE do
    begin
      cmd.writeln('玩家'+Usf.i_to_s(PlayerN)+'的血牌区：');
      PlayerList[PlayerN].desktop.blood.print;
    end;
  }
  PostMessage(Self.Handle,Rule_SortPlayer,0,0);
end;

procedure TRuleForm.SortPlayer(var Msg:TMessage);
var PlayerN,i,j:PlayerNo;
    ExPlayer:TPlayer;
begin
  ts('根据玩家血量重新排序玩家',Msg.wParam,Msg.lParam);
  for PlayerN:=0 to PLAYER_RANGE do
    begin
      PlayerList[PlayerN].renew_blood_info;
    end;
  for i:=0 to PLAYER_RANGE-1 do
    begin
      for j:=PLAYER_RANGE downto i do
        begin
          if PlayerList[i].blood_info.Number < PlayerList[j].blood_info.Number then
            begin
              exPlayer:=PlayerList[i];
              PlayerList[i]:=PlayerList[j];
              PlayerList[j]:=ExPlayer;
              continue;
            end
          else if PlayerList[i].blood_info.Number > PlayerList[j].blood_info.Number then continue;
          if PlayerList[i].blood_info.CardNumber < PlayerList[j].blood_info.CardNumber then
            begin
              exPlayer:=PlayerList[i];
              PlayerList[i]:=PlayerList[j];
              PlayerList[j]:=ExPlayer;
              continue;
            end
          else if PlayerList[i].blood_info.CardNumber > PlayerList[j].blood_info.CardNumber then continue;
          if PlayerList[i].blood_info.Std < PlayerList[j].blood_info.Std then
            begin
              exPlayer:=PlayerList[i];
              PlayerList[i]:=PlayerList[j];
              PlayerList[j]:=ExPlayer;
              continue;
            end
          else if PlayerList[i].blood_info.Std = PlayerList[j].blood_info.Std then
            begin
              randomize;
              if random(1)=0 then continue;
              exPlayer:=PlayerList[i];
              PlayerList[i]:=PlayerList[j];
              PlayerList[j]:=ExPlayer;
            end;
        end;
    end;
  for i:=0 to PLAYER_RANGE do
    begin
      PlayerList[i].id:=i;
      PlayerList[i].client.form.player_id:=i;
      with PlayerList[i].blood_info do cmd.writeln(PlayerList[i].name+'::'+Usf.i_to_s(Number)+'-'+Usf.i_to_s(CardNumber)+'-'+Usf.f_to_s(Std,5));
    end;
  ts('排序完成',Msg.wParam,Msg.lParam);
  PostMessage(Self.Handle,Rule_PlayerRound_begin,0,0);
end;

procedure TRuleForm.BloodCardRound(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  ts('玩家血牌放置回合开始',Msg.wParam,Msg.lParam);
  PlayerN:=Msg.wParam;
  PlayerList[PlayerN].Round:=true;
  PostMessage(PlayerList[PlayerN].client.hd,Msg_SendBloodCardRound,0,0);
end;

procedure TRuleForm.BloodCardRound_BloodEnd(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  PlayerN:=Msg.wParam;
  if PlayerN>PLAYER_RANGE then exit;
  if PlayerN<0 then exit;
  if not PlayerList[PlayerN].round then exit;
  if PlayerList[PlayerN].firstround then exit;
  ts('玩家血牌放置回合结束',Msg.wParam,Msg.lParam);

  PlayerList[PlayerN].Round:=false;
  if PlayerN = PLAYER_RANGE then
    begin
      PostMessage(Self.Handle,Rule_BloodCardRound_end,0,0);
    end
  else
    begin
      PostMessage(Self.Handle,Rule_BloodCardRound,PlayerN+1,0);
    end;
end;


procedure TRuleForm.PlayerRound_begin(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  ts('玩家回合开始',Msg.wParam,Msg.lParam);
  PlayerN:=Msg.wParam;
  PlayerList[PlayerN].Round:=true;
  PlayerList[PlayerN].RoundStatus:=0;
  PlayerList[PlayerN].RestDefend:=2;
  PostMessage(Self.Handle,Rule_DefendRound_begin,PlayerN,0);
end;

procedure TRuleForm.PlayerRound_end(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  ts('玩家回合结束',Msg.wParam,Msg.lParam);
  PlayerN:=Msg.wParam;
  PlayerList[PlayerN].firstround:=true;
  PlayerList[PlayerN].Round:=false;
  PlayerList[PlayerN].RoundStatus:=0;
  PlayerList[PlayerN].RestDefend:=0;
  PlayerList[PlayerN].decDefendInputLocked_Round;
  PlayerList[PlayerN].decDefendOutputLocked_Round;
  PlayerList[PlayerN].decAttackInputLocked_Round;
  PlayerList[PlayerN].decAttackOutputLocked_Round;
  inc(PlayerN);
  PlayerN:=PlayerN mod (PLAYER_RANGE + 1);
  PostMessage(Self.Handle,Rule_PlayerRound_begin,PlayerN,0);
end;

procedure TRuleForm.AttackRound_begin(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  ts('玩家攻击阶段发送',Msg.wParam,Msg.lParam);
  PlayerN:=Msg.wParam;
  inc(PlayerList[PlayerN].RoundStatus);
  PlayerList[PlayerN].RestAttack:=1;
  PostMessage(PlayerList[PlayerN].client.hd,Msg_SendAttackRound,0,0);
end;

procedure TRuleForm.AttackRound_end(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  PlayerN:=Msg.wParam;
  if Special_Round then begin ts('特殊结算过程内不能结束阶段');exit end;
  if not PlayerList[PlayerN].Round then begin ts('玩家不在回合内');exit end;
  if Self.initative_player <> PlayerN then begin ts('结算未完成不能结束回合');exit end;
  ts('玩家攻击阶段结束',Msg.wParam,Msg.lParam);
  dec(PlayerList[PlayerN].RestAttack);
  postMessage(Self.Handle,Rule_DefendRound_begin,PlayerN,0);
end;

procedure TRuleForm.AttackRound_play_card(var Msg:TMessage);//可能删除
var PlayerN:PlayerNo;
begin
  PlayerN:=Msg.wParam;
  if not PlayerList[PlayerN].Round then exit;
  ts('玩家攻击出牌',Msg.wParam,Msg.lParam);

  //打什么牌的处理


  dec(PlayerList[PlayerN].RestAttack);
  PostMessage(PlayerList[PlayerN].client.hd,Msg_SendAttackRound,0,0);
end;

procedure TRuleForm.DefendRound_begin(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  ts('玩家备战阶段发送',Msg.wParam,Msg.lParam);
  PlayerN:=Msg.wParam;
  inc(PlayerList[PlayerN].RoundStatus);
  //
  PostMessage(PlayerList[PlayerN].client.hd,Msg_SendDefendRound,0,0);
end;

procedure TRuleForm.DefendRound_end(var Msg:TMessage);
var PlayerN:PlayerNo;
begin
  PlayerN:=Msg.wParam;
  if not PlayerList[PlayerN].Round then begin ts('玩家不在回合内');exit end;
  if Special_Round then begin ts('特殊结算过程内不能结束阶段');exit end;
  ts('玩家备战阶段结束',Msg.wParam,Msg.lParam);
  case PlayerList[PlayerN].RoundStatus of
    1:postMessage(Self.Handle,Rule_AttackRound_begin,PlayerN,0);
    3:postMessage(Self.Handle,Rule_AttackRound_begin,PlayerN,0);
    5:postMessage(Self.Handle,Rule_PlayerRound_end,PlayerN,0);
  end;

end;

procedure TRuleForm.DefendRound_play_card(var Msg:TMessage);//可能删除
var PlayerN:PlayerNo;
begin
  PlayerN:=Msg.wParam;
  if not PlayerList[PlayerN].Round then exit;
  ts('玩家备战阶段出牌',Msg.wParam,Msg.lParam);
  //打什么牌的处理，如果是放置，需要将PlayerList[PlayerN].RestDefend减一

  PostMessage(PlayerList[PlayerN].client.hd,Msg_SendDefendRound,0,0);
end;



procedure TRuleForm.GreenForbidChoiceRound_begin(var Msg:TMessage);
var playerN:playerNo;
begin
  PlayerN:=Msg.wParam;
  Special_Round:=true;
  ts('*绿禁功能选择阶段开始',Msg.wParam,Msg.lParam);
  RuleForm.InfoConfirm;
  RuleForm.cfm_enable[playerN]:=true;
  RuleForm.NextMessage(RuleForm.Handle,Rule_GreenForbidChoiceRound_end,Msg.wParam,0);
  PostMessage(PlayerList[playerN].client.hd,Msg_SendChoice,1,0)
end;
procedure TRuleForm.GreenForbidChoiceRound_end(var Msg:TMessage);
var playerN:playerNo;
begin
  PlayerN:=Msg.wParam;
  case Selection of
    1:begin
        if PlayerList[PlayerN].Round then begin
          PlayerList[PlayerN].DefendInputLocked_Round:=2;
          PlayerList[PlayerN].AttackInputLocked_Round:=2;
        end else begin
          PlayerList[PlayerN].DefendInputLocked_Round:=1;
          PlayerList[PlayerN].AttackInputLocked_Round:=1;
        end;
      end;
    2:begin
        if PlayerList[PlayerN].Round then begin
          PlayerList[PlayerN].AttackOutputLocked_Round:=2;
          PlayerList[PlayerN].AttackInputLocked_Round:=2;
        end else begin
          PlayerList[PlayerN].AttackOutputLocked_Round:=1;
          PlayerList[PlayerN].AttackInputLocked_Round:=1;
        end;
      end;
    else
      begin
        ts('没有有效选择，重复发送选择请求');
        PostMessage(RuleForm.Handle,Rule_GreenForbidChoiceRound_begin,Msg.wParam,0);
      end;
  end;
  Special_Round:=false;
  ts('*绿禁功能选择阶段结束',Msg.wParam,Msg.lParam);
end;
procedure TRuleForm.ColorChangeReturnRound_begin(var Msg:TMessage);
var playerN:playerNo;
begin
  PlayerN:=Msg.wParam;
  Special_Round:=true;
  ts('*变色牌回手阶段开始',Msg.wParam,Msg.lParam);
  RuleForm.InfoConfirm;
  RuleForm.cfm_enable[playerN]:=true;
  RuleForm.NextMessage(RuleForm.Handle,Rule_ColorChangeReturnRound_end,Msg.wParam,0);
  PostMessage(PlayerList[playerN].client.hd,Msg_SendReturnHandRound,Msg.wParam,0);
end;
procedure TRuleForm.ColorChangeReturnRound_end(var Msg:TMessage);
var playerN:playerNo;
begin
  PlayerN:=Msg.wParam;
  PlayerList[PlayerN].ColorChangeRestDefend:=0;
  PlayerList[PlayerN].ColorChangeRestAttack:=0;
  Special_Round:=false;
  ts('*变色牌回手阶段结束',Msg.wParam,Msg.lParam);
end;



initialization



end.

