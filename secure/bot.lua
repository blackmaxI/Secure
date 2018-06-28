URL = require "socket.url"
http = require "socket.http"
https = require "ssl.https"
ltn12 = require "ltn12"
local utf8 = require 'lua-utf8'
serpent = require("serpent")
json = (loadfile "./libs/JSON.lua")()
redis = require "redis"
redis = redis.connect("127.0.0.1", 6379)
JSON = require "dkjson"
tdcli = dofile("tdcli.lua")
http.TIMEOUT = 10
local day = 86400
local bot_id = 493766156
local sudo_id = 206480168
sudo_users = {206480168} 
function dl_cb(arg, data)
end
local delete_msg = function(chatid, mid)
tdcli_function({ID = "DeleteMessages",chat_id_ = chatid,message_ids_ = mid}, dl_cb, nil)
end
local function getParseMode(parse_mode)
local P
if parse_mode then
local mode = parse_mode:lower()
if mode == 'markdown' or mode == 'md' then
P = {ID = "TextParseModeMarkdown"}
elseif mode == 'html' then
P = {ID = "TextParseModeHTML"}
end
end
  return P
end
local sendText = function(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, text, disable_web_page_preview, parse_mode, cb, cmd)
local TextParseMode = getParseMode(parse_mode)
local input_message_content = {ID = "InputMessageText",text_ = text,disable_web_page_preview_ = disable_web_page_preview,clear_draft_ = 0,entities_ = {},parse_mode_ = TextParseMode,}
tdcli_function ({ID = 'SendMessage',chat_id_ = chat_id,reply_to_message_id_ = reply_to_message_id,disable_notification_ = disable_notification,from_background_ = from_background,reply_markup_ = reply_markup,input_message_content_ = input_message_content,}, cb or dl_cb, cmd)
end
local changeChatMemberStatus = function(chat_id, user_id, status, cb, cmd)
tdcli_function ({ID = "ChangeChatMemberStatus",chat_id_ = chat_id,user_id_ = user_id,status_ = {ID = "ChatMemberStatus" .. status},}, cb or dl_cb, cmd)
end
function getInputFile(file)
if file:match("/") then
infile = {
ID = "InputFileLocal",
path_ = file
}
elseif file:match("^%d+$") then
infile = {
ID = "InputFileId",
id_ = file
}
else
infile = {
ID = "InputFilePersistentId",
persistent_id_ = file
}
end
return infile
end
local sendPhoto = function(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
tdcli_function({ID = "SendMessage",chat_id_ = chat_id,reply_to_message_id_ = reply_to_message_id,disable_notification_ = disable_notification,from_background_ = from_background,reply_markup_ = reply_markup,input_message_content_ = {ID = "InputMessagePhoto",photo_ = getInputFile(photo),added_sticker_file_ids_ = {},width_ = 0,height_ = 0,caption_ = caption}}, dl_cb, nil)
end
local getUserProfilePhotos = function(user_id, offset, limit, cb, cmd)
tdcli_function ({ID = "GetUserProfilePhotos",user_id_ = user_id,offset_ = offset,limit_ = limit}, cb or dl_cb, cmd)
end
local searchPublicChat = function(username, cb, cmd)
tdcli_function ({ID = "SearchPublicChat",username_ = username}, cb or dl_cb, cmd)
end
local getMessage = function(chat_id, message_id, cb, cmd)
tdcli_function ({ID = "GetMessage",chat_id_ = chat_id,message_id_ = message_id}, cb or dl_cb, cmd)
end
function is_sudo(msg)
local var = false
for v,user in pairs(sudo_users) do
if user == msg.sender_user_id_ then
var = true
end
end
return var
end
function vardump(value)
print(serpent.block(value, {comment=false}))
end
function is_bot(msg)
local var = false
if bot_id == msg.sender_user_id_ then
var = true
end
return var
end
function sleep(n) 
os.execute("sleep " .. tonumber(n)) 
end
function is_muted(user_id, chat_id)
local var = false
local hash = 'muted:'..chat_id
local silent = redis:sismember(hash, user_id)
if silent then
var = true
end
return var
end
function is_filter(msg, value)
local hash = redis:smembers('filters:'..msg.chat_id_)
if hash then
local names = redis:smembers('filters:'..msg.chat_id_)
local text = ''
for i=1, #names do
if string.match(value:lower(), names[i]:lower()) and not is_mod(msg) then
local id = msg.id_
local msgs = {[0] = id}
local chat = msg.chat_id_
delete_msg(chat,msgs)
end;end;end;end
function is_banned(user_id, chat_id)
local var = false
local hash = 'ban:'..chat_id
local banned = redis:sismember(hash, user_id)
if banned then
var = true
end
return var
end
function is_gbanned(user_id)
local var = false
local hash = 'gban:'
local gbanned = redis:sismember(hash, user_id)
if gbanned then
var = true
end
return var
end
function is_admin(msg)
local user = msg.sender_user_id_ 
local hash = redis:sismember('botadmin:', user)
if hash or is_bot(msg) or is_sudo(msg) then
return true
else
return false
end
end
function is_admin2(user_id, chat_id)
local var = false
local admins = "botadmin:"
local admin = redis:sismember(admins, user_id)
if admin then
var = true
end
for k,v in pairs(sudo_users) do
if user_id == v then
var = true
end
end
return var
end
function is_owner(msg)
local user = msg.sender_user_id_ 
local chat_id = tostring(msg.chat_id_)
local hash = redis:sismember("owner:"..chat_id, user)
if hash or is_bot(msg) or is_admin(msg) or is_sudo(msg) then
return true
else
return false
end
end
function is_mod(msg)
local user = msg.sender_user_id_ 
local chat_id = tostring(msg.chat_id_)
local hash = redis:sismember("mod:"..chat_id, user)
if hash or is_bot(msg) or is_owner(msg) or is_admin(msg) or is_sudo(msg) then
return true
else
return false
end
end
function is_mod2(user_id, chat_id)
local var = false
local hash =  "mod:"..chat_id
local mod = redis:sismember(hash, user_id)
local hashss =  "owner:"..chat_id
local owner = redis:sismember(hashss, user_id)
local admins = "botadmin:"
local admin = redis:sismember(admins, user_id)
if admin then
var = true
end
if mod then
var = true
end
if owner then
var = true
end
if user_id == bot_id then
var = true
end
for k,v in pairs(sudo_users) do
if user_id == v then
var = true
end
end
return var
end
function getUser(user_id, cb)
tdcli_function ({ID = "GetUser",user_id_ = user_id}, cb, nil)
end
function getChatId(id)
local chat = {}
local id = tostring(id)
if id:match('^-100') then
local channel_id = id:gsub('-100', '')
chat = {ID = channel_id, type = 'channel'}
else
local group_id = id:gsub('-', '')
chat = {ID = group_id, type = 'group'}
end
return chat
end
function blockUser(user_id)
tdcli_function ({ID = "BlockUser",user_id_ = user_id}, dl_cb, nil)
end
function unblockUser(user_id)
tdcli_function ({ID = "UnblockUser",user_id_ = user_id}, dl_cb, nil)
end
local function openChat(chat_id, cb)
tdcli_function ({ID = "OpenChat",chat_id_ = chat_id}, cb or dl_cb, nil)
end
function writefile(filename, input)
local file = io.open(filename, "w")
file:write(input)
file:flush()
file:close()
return true
end
function SendMetion(chat_id, user_id, msg_id, text, offset, length)
tdcli_function ({ID = "SendMessage",chat_id_ = chat_id,reply_to_message_id_ = msg_id,disable_notification_ = 0,from_background_ = 1,reply_markup_ = nil,input_message_content_ = {ID = "InputMessageText",text_ = text,disable_web_page_preview_ = 1,clear_draft_ = 0,entities_ = {[0]={ID="MessageEntityMentionName",offset_=offset,length_=length,user_id_=user_id},},},}, dl_cb, nil)
end
local getChat = function(chat_id, cb)
tdcli_function({ID = "GetChat", chat_id_ = chat_id}, cb or dl_cb, nil)
end
function tdcli_update_callback(data)
if (data.ID == "UpdateNewMessage") then
local msg = data.message_
local chat_id = tostring(msg.chat_id_)
local user_id = msg.sender_user_id_
local reply_id = msg.reply_to_message_id_
local txt = msg.content_.text_
local caption = msg.content_.caption_
function uptime()
  local uptime = io.popen("uptime"):read("*all")
  local uptime2 = io.popen("uptime -p"):read("*all")
  days = uptime:match("up %d+ days")
hours = uptime2:match(", %d+ hours")
  minutes = uptime:match(":%d+,")
    sec = uptime:match(":%d+ up")
  if hours then
    hours = hours
  else
    hours = ""
  end
  if days then
    days = days
  else
    days = ""
  end
  if minutes then
    minutes = minutes
  else
    minutes = ""
  end
  days = days:gsub("up", "")
  local a_ = string.match(days, "%d+")
  local b_ = string.match(hours, "%d+")
  local c_ = string.match(minutes, "%d+")
   local d_ = string.match(sec, "%d+")
  if a_ then
    a = a_
  else
    a = 0
  end
  if b_ then
    b = b_
  else
    b = 0
  end
  if c_ then
    c = c_
  else
    c = 0
  end
    if d_ then
    d = d_
  else
    d = 0
  end
return a..' روز و '..b..' ساعت و '..c..' دقیقه و '..d..' ثانیه'
end
tdcli.viewMessages(chat_id, {[0] = msg.id_})
local nerkh = 'ربات آنتی اسپم سیکیور :\n\n\nقیمت ربات آنتی اسپم <b>Secure</b> :\n\n1 ماهه : 7 هزار تومان\n\n2 ماهه : 14 هزار تومان\n\n3 ماهه : 20 هزار تومان\n\nمشخصات فنی سرور : \n\n مقدار فضای رم سرور : 6GB | DDR4\nنوع هارد : SSD NVMe\nمقدار فضای هارد : 30GB\nنوع پردازنده سرور : Intel(R) Xeon(R)\nپردازنده سرور : 3600 MHz\n\n\n\n›› سازنده و مالک ربات :\n@Secure_Dev\n›› کانال ما : \n@Secure_Tm\n›› ربات پشتیبانی برای خرید :\n@SecureSupportBot \n\n›› لینک گروه پشتیبانی :\nhttps://t.me/joinchat/DE6jKEHsNosxJU_lDjR_5w'
if msg.date_ < (os.time() - 30) then;return false;end
if msg.content_.ID == 'MessagePinMessage' then;if is_owner(msg) and redis:get("lockpin"..chat_id) then;redis:set('pinned'..chat_id, msg.content_.message_id_);elseif not redis:get("lockpin"..chat_id) then;redis:set('pinned'..chat_id, msg.content_.message_id_);end;end
if not is_owner(msg) then
if redis:get("lockpin"..chat_id) then;if msg.content_.ID == 'MessagePinMessage' then;sendText(chat_id, msg.id_, 0, 1, nil, '■ قفل سنجاق فعال است!\n*››* شما اجازه دسترسی به سنجاق پیام را ندارید، به همین دلیل پیام قبلی مجدد سنجاق میگردد.', 1, 'md');tdcli.unpinChannelMessage(msg.chat_id_);local PinnedMessage = redis:get('pinned'..msg.chat_id_);if PinnedMessage then;tdcli.pinChannelMessage(msg.chat_id_,tonumber(PinnedMessage), 0);end;end;end
if msg.content_.ID == "MessageChatAddMembers" then;if msg.content_.members_[0].type_.ID == 'UserTypeBot' then;if redis:get("lockbots"..chat_id) then;function bot_msg(extra, result, success);local first_name = string.gsub(result.first_name_,"#", "");local first_name = string.gsub(result.first_name_,"@", "");local first_name = string.gsub(result.first_name_,'\n', " ");local first_name = string.gsub(result.first_name_," ", "‌");local text = '■ کاربر [ '..first_name..' - '..result.id_..' ] قفل ربات در این گروه فعال است و افزودن ربات ممنوع میباشد!\n\n›› ربات [ '..msg.content_.members_[0].first_name_..' - @'..msg.content_.members_[0].username_..' ] اخراج شد.';SendMetion(chat_id, user_id, msg.id_, text, 10, utf8.len(first_name));end;tdcli.getUser(user_id, bot_msg, nil);changeChatMemberStatus(chat_id, msg.content_.members_[0].id_, 'Kicked');end;end;end
end
local is_service = msg.content_.ID == "MessageChatJoinByLink" or msg.content_.ID == "MessageChatAddMembers" or msg.content_.ID == "MessageChatDeleteMember";if is_service and redis:get("locktgservice"..chat_id) then;delete_msg(msg.chat_id_, {[0] = msg.id_});end
if not is_mod(msg) then
 if msg.content_.caption_ then
local is_link_msg = caption:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") or caption:match("[Tt].[Mm][Ee]/") or msg.content_.entities_ and msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityUrl" or msg.content_.entities_ and msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityTextUrl";if is_link_msg and redis:get("locklink"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end
local is_tag = caption:match("#") or caption:match("@");if is_tag and redis:get("locktag"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end
local is_farsi = caption:match("[\216-\219][\128-\191]");if is_farsi and redis:get("lockfarsi"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end
local is_eng = caption:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]");if is_eng and redis:get("lockenglish"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end	
end
if msg.content_.ID == "MessageText" then
local is_link_msg = txt:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") or txt:match("[Tt].[Mm][Ee]/") or msg.content_.entities_ and msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityUrl" or msg.content_.entities_ and msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityTextUrl";if is_link_msg and redis:get("locklink"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end
local is_tag = txt:match("#") or txt:match("@") or msg.content_.entities_ and msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityMentionName";if is_tag and redis:get("locktag"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end
local is_farsi = txt:match("[\216-\219][\128-\191]");if is_farsi and redis:get("lockfarsi"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end
local is_eng = txt:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]");if is_eng and redis:get("lockenglish"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end	
local _nl, ctrl_chars = string.gsub(txt, '%c', '');local _nl, real_digits = string.gsub(txt, '%d', '');local hash = 'cher'..msg.chat_id_;if not redis:get(hash) then;sens = 400;else;sens = tonumber(redis:get(hash));end
if redis:get('lockcher'..msg.chat_id_) then;if string.len(msg.content_.text_) > (sens) or ctrl_chars > (sens) or real_digits > (sens) then;delete_msg(chat_id, {[0] = msg.id_});end;end
if redis:get("locktext"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.forward_info_ then;if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then;if redis:get("lockfwd"..chat_id) then;delete_msg(chat_id, {[0] = msg.id_});end;end;end
if redis:get("lockchat"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end
if redis:get("atolct2"..msg.chat_id_) or redis:get("atolct2"..msg.chat_id_) then
local time = os.date("%H%M")
local time2 = redis:get("atolct1"..msg.chat_id_)
time2 = time2.gsub(time2,":","")
local time3 = redis:get("atolct2"..msg.chat_id_)
time3 = time3.gsub(time3,":","")
if tonumber(time3) < tonumber(time2) then
if tonumber(time) <= 2359 and tonumber(time) >= tonumber(time2) then
if not redis:get("lc_ato:"..msg.chat_id_) then
redis:set("lc_ato:"..msg.chat_id_,true)
 sendText(chat_id, '', 0, 1, nil, '■ قفل خودکار ربات فعال شد!\n\n*››* از کاربران گروه خواهشمندیم از ارسال هر گونه مطلب در گروه خودداری کنند.\nگروه تا ساعت *'..redis:get("atolct2"..msg.chat_id_)..'* تعطیل میباشد.', 1, 'md')
end
elseif tonumber(time) >= 0000 and tonumber(time) < tonumber(time3) then
if not redis:get("lc_ato:"..msg.chat_id_) then
sendText(chat_id, '', 0, 1, nil, '■ قفل خودکار ربات فعال شد!\n\n*››* از کاربران گروه خواهشمندیم از ارسال هر گونه مطلب در گروه خودداری کنند.\nگروه تا ساعت *'..redis:get("atolct2"..msg.chat_id_)..'* تعطیل میباشد.', 1, 'md')
redis:set("lc_ato:"..msg.chat_id_,true)
end
else
if redis:get("lc_ato:"..msg.chat_id_) then
redis:del("lc_ato:"..msg.chat_id_, true)
end
end
elseif tonumber(time3) > tonumber(time2) then
if tonumber(time) >= tonumber(time2) and tonumber(time) < tonumber(time3) then
if not redis:get("lc_ato:"..msg.chat_id_) then
sendText(chat_id, '', 0, 1, nil, '■ قفل خودکار ربات فعال شد!\n\n*››* از کاربران گروه خواهشمندیم از ارسال هر گونه مطلب در گروه خودداری کنند.\nگروه تا ساعت *'..redis:get("atolct2"..msg.chat_id_)..'* تعطیل میباشد.', 1, 'md')
redis:set("lc_ato:"..msg.chat_id_,true)
end
else
if redis:get("lc_ato:"..msg.chat_id_) then
redis:del("lc_ato:"..msg.chat_id_, true)
end
end
end
end
if redis:get("lc_ato:"..msg.chat_id_) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end
if msg.content_.ID == 'MessageContact' then;if redis:get("lockcontact"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.reply_markup_ and msg.reply_markup_.ID == 'ReplyMarkupInlineKeyboard' or msg.content_.game_ or tonumber(msg.via_bot_user_id_) ~= 0 then;if redis:get("lockinline"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.content_.ID == "MessageUnsupported" then;if redis:get("lockselfvideo"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.content_.ID == 'MessageAnimation' then;if redis:get("lockgif"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.content_.ID == 'MessageVideo' then;if redis:get("lockvideo"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.content_.ID == 'MessagePhoto' then;if redis:get("lockphoto"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.content_.ID == 'MessageAudio' or msg.content_.ID == 'MessageVoice' then;if redis:get("lockaudio"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.content_.ID == 'MessageSticker' then;if redis:get("locksticker"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
if msg.content_.ID == 'MessageDocument' then;if redis:get("lockfile"..chat_id) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end;end
local flmax = 'floodmax'..chat_id;if not redis:get(flmax) then;floodMax = 5;else;floodMax = tonumber(redis:get(flmax));end;
local pm = 'flood:'..user_id..':'..chat_id..':msgs';if not redis:get(pm) then;msgs = 0;else;msgs = tonumber(redis:get(pm));end
local TIME_CHECK = 2;if redis:get("lockflood"..chat_id) then;if msg.content_.ID == "MessageChatAddMembers" then;else;if msgs > (floodMax - 1) then;if redis:get('sender:'..user_id..':flood') then;return;else;changeChatMemberStatus(chat_id, msg.sender_user_id_, 'Kicked');tdcli.deleteMessagesFromUser(chat_id, msg.sender_user_id_);SendMetion(chat_id, user_id, msg.id_, 'کاربر '..user_id..' به دلیل ارسال بیش از '..floodMax..' پیام اخراج شد.', 6, utf8.len(user_id));redis:setex('sender:'..user_id..':flood', 30, true);end;end;redis:setex(pm, TIME_CHECK, msgs+1);end;end
if msg.content_.ID == "MessageChatJoinByLink" then;if not is_gbanned(msg.sender_user_id_) then;if not is_banned(msg.sender_user_id_, msg.chat_id_) then;function get_welcome(extra,result,success);local text = redis:get("wlc:"..chat_id);local grules = redis:get("rules:"..chat_id);local chat = msg.chat_id_;if grules then;grouprules = grules;else;grouprules = "";end;if result.username_ then;user_name = '@'..result.username_;else;user_name = "";end;local text = text:gsub('{firstname}',(result.first_name_ or ''));local text = text:gsub('{lastname}',(result.last_name_ or ''));local text = text:gsub('{username}',(user_name));local text = text:gsub('{rules}',('قوانین گروه : \n'..grouprules));sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html');end;if redis:get("wlc:"..chat_id) then;getUser(msg.sender_user_id_,get_welcome);end;end;end;end
if is_muted(msg.sender_user_id_, msg.chat_id_) then;local id = msg.id_;local msgs = {[0] = id};local chat = msg.chat_id_;delete_msg(chat,msgs);end
if txt then;if is_filter(msg,txt) then;delete_msg(chat_id,{[0] = msg.id_});end;end
if caption then;if is_filter(msg,caption) then;delete_msg(chat_id,{[0] = msg.id_});end;end
function botkick_msg(extra, result, success);if result.type_.ID == "UserTypeBot" then;if redis:get("lockbots"..chat_id) then;changeChatMemberStatus(chat_id, msg.sender_user_id_, 'Kicked');delete_msg(chat_id, {[0] = msg.id_});end;end;end;getUser(msg.sender_user_id_,botkick_msg)
end
if not is_admin(msg) then
if msg.content_.ID == "MessageChatAddMembers" then
if is_banned(msg.content_.members_[0].id_, msg.chat_id_) then;changeChatMemberStatus(chat_id, msg.content_.members_[0].id_, 'Kicked');SendMetion(chat_id, msg.content_.members_[0].id_, msg.id_, '■ کاربر '..msg.content_.members_[0].id_..' به دلیل مسدودیت از گروه اخراج شد.', 8, utf8.len(msg.content_.members_[0].id_));end
if is_gbanned(msg.content_.members_[0].id_) then;changeChatMemberStatus(chat_id, msg.content_.members_[0].id_, 'Kicked');SendMetion(chat_id, msg.content_.members_[0].id_, msg.id_, '■ کاربر '..msg.content_.members_[0].id_..' به دلیل مسدودیت همگانی از گروه اخراج شد.', 8, utf8.len(msg.content_.members_[0].id_));end
end
if is_banned(msg.sender_user_id_, msg.chat_id_) then;changeChatMemberStatus(chat_id, msg.sender_user_id_, 'Kicked');delete_msg(chat_id,{[0] = msg.id_});end
if is_gbanned(msg.sender_user_id_) then;changeChatMemberStatus(chat_id, msg.sender_user_id_, 'Kicked');delete_msg(chat_id,{[0] = msg.id_});end
end
local function delmsg (secure,dev);msgs = secure.msgs ;for k,v in pairs(dev.messages_) do;msgs = msgs - 1;delete_msg(v.chat_id_,{[0] = v.id_});if msgs == 1 then;delete_msg(dev.messages_[0].chat_id_,{[0] = dev.messages_[0].id_});return false;end;end;tdcli.getChatHistory(dev.messages_[0].chat_id_, dev.messages_[0].id_,0 , 100, delmsg, {msgs=msgs});end
local function del_stats(chat_id)
redis:del('max_warn:'..chat_id);redis:del('warn:'..chat_id);redis:del('muted:'..chat_id);redis:del('ban:'..chat_id);redis:del('mod:'..chat_id);redis:del('owner:'..chat_id);redis:del('filters:'..chat_id);redis:del("link:"..chat_id);redis:del("rules:"..chat_id);redis:del("wlc:"..chat_id);redis:del("locklink"..chat_id);redis:del("lockchat"..chat_id);redis:del("lockflood"..chat_id);redis:del('floodmax'..chat_id);redis:del('cher'..chat_id);redis:del("lockcontact"..chat_id);redis:del("lockedit"..chat_id);redis:del("lockinline"..chat_id);redis:del("lockfarsi"..chat_id);redis:del("lockselfvideo"..chat_id);redis:del("locktext"..chat_id);redis:del("locksticker"..chat_id);redis:del("lockaudio"..chat_id);redis:del("lockenglish"..chat_id);redis:del("lockfwd"..chat_id);redis:del("lockphoto"..chat_id);redis:del("lockcher"..chat_id);redis:del("lockvideo"..chat_id);redis:del("locktgservice"..chat_id);redis:del("lockcmd"..chat_id);redis:del("lockpin"..chat_id);redis:del("lockfile"..chat_id);redis:del("locktag"..chat_id);redis:del("lockbots"..chat_id);redis:del("lockgif"..chat_id);redis:del("lc_ato:"..chat_id);redis:del("atolct1"..chat_id);redis:del("atolct2"..chat_id);
end
local function forward()
tdcli_function({ID = "ForwardMessages",chat_id_ = -263678237,from_chat_id_ = chat_id,message_ids_ = {[0] = msg.id_},disable_notification_ = 0,from_background_ = 1}, dl_cb, nil)
end
local id = tostring(chat_id);if id:match("^-100(%d+)$") then;grouptype = "supergroup";if not redis:sismember("sgps:", chat_id) then;redis:sadd("sgps:",chat_id);end;elseif id:match("^-(%d+)$") then;grouptype = "group";if not redis:sismember("gps:", chat_id) then;redis:sadd("gps:",chat_id);end;elseif id:match("^(%d+)$") then;grouptype = "pv";if not redis:sismember("pv:", chat_id) then;redis:sadd("pv:",chat_id);end;end
redis:incr("allmsg:")
if msg.content_.ID == "MessageText" then
if grouptype == "pv" then
if not is_admin(msg) and not redis:get("monshi:"..chat_id) then;local utf8 = require 'lua-utf8';function pv_msg(extra, result, success);local first_name = string.gsub(result.first_name_,"#", "");local first_name = string.gsub(result.first_name_,"@", "");local first_name = string.gsub(result.first_name_,'\n', " ");local first_name = string.gsub(result.first_name_," ", "‌");local text = 'سلام ‌'..first_name..'‌ ؛ \n\nمن رباتی هستم که میتوانم گروه شمارو ضد لینک و ضد تبلیغ کنم ، اسم من سیکیور هست☺️\nخب اگه میخوای منو داشته باشی و به من نیاز داری که تو گروهت مدیریت کنم وارد گروه پشتیبانی شو🙈\n\nلینک گروه پشتیبانی : https://t.me/joinchat/DE6jKEHsNosxJU_lDjR_5w\n\nبرای کسب اطلاعات بیشتر میتوانید در کانال ما عضو شوید : @Secure_Tm\n\nبرای دریافت لیست دستورات "راهنما" رو ارسال کنید.';SendMetion(chat_id, user_id, msg.id_, text, 6, utf8.len(first_name));end;tdcli.getUser(user_id, pv_msg, nil);redis:set("monshi:"..chat_id, true);redis:setex("not:"..chat_id, 2, true);tdcli.addChatMember(-1001105999499, user_id, 20);end
if txt:match("^راهنما$") then;sendText(chat_id, '', 0, 1, nil, 'لیست دستورات من : \n\n`=======`\nآیدی\n- دریافت شناسه شما\n`=======`\nنرخ\n-نمایش نرخ ربات \n`=======`\nارسال پیام رگباری در اینجا ممنوع است!\n`=======`\nبا فوروارد کردن پیام هر شخص شناسه کاربر شخص را دریافت کنید.', 1, 'md');elseif txt:match("^آیدی$") then;sendText(chat_id, '', 0, 1, nil, 'شناسه کاربری شما : '..user_id..'', 1, 'md');elseif txt:match("^نرخ$") then;sendText(chat_id, '', 0, 1, nil, nerkh, 1, 'html');end;if msg.forward_info_ and tonumber(chat_id) == tonumber(user_id)then;local text = msg.forward_info_.sender_user_id_;sendText(chat_id, msg.id_, 0, 1, nil, 'آیدی شخص فوروارد شده : '..text..'\nآیدی شما : '..user_id..'', 1, 'md');end
if not msg.forward_info_ and not txt:match("^نرخ$") and not txt:match("^آیدی$") and not txt:match("^راهنما$") and not redis:get("not:"..chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'دستور مورد نظر یافت نشد.\n\nلطفا "راهنما" را ارسال کنید.', 1, 'md');end
local floodpv = 'floodpv:'..msg.sender_user_id_;if not redis:get(floodpv) then;msgsonpv = 0;else;msgsonpv = tonumber(redis:get(floodpv));end
if not is_admin(msg) then;if msgsonpv > (13 - 1) then;blockUser(msg.sender_user_id_);sendText(chat_id, '', 0, 1, nil, 'شما به دلیل ارسال پیام رگباری از خصوصی ربات بلاک شده و از همه گروه ها مسدود شدید!\n\nاز ربات پشتیبانی درخواست آنبلاک کردن کنید : @SecureSupportBot ', 1, 'md');redis:sadd('gban:', msg.sender_user_id_);local ggps = redis:smembers('addbot:') or 0;for i=1, #ggps do;changeChatMemberStatus(ggps[i], msg.sender_user_id_, 'Kicked');end;end;local idmem = tostring(msg.chat_id_);if idmem:match("^(%d+)") then;redis:setex(floodpv, 2, msgsonpv+1);end;end
end
if grouptype == "group" or grouptype == "supergroup" then
if not is_admin(msg) then
if not redis:get("adder:"..chat_id) then;sendText(chat_id, '', 0, 1, nil, '*››* این گروه نامعتبر میباشد ربات از گروه خارج میشود!\n\nجهت خرید ربات به ربات پشتیبانی مراجعه کنید.\n■ آیدی ربات پشتیبانی : @SecureSupportBot', 1, 'md');changeChatMemberStatus(chat_id, bot_id, 'Left');end
if not redis:get("chargeg:"..msg.chat_id_) and is_owner(msg) then;sendText(chat_id, msg.id_, 0, 1, nil, '■ تاریخ انقضا گروه شما به اتمام رسید...\nبرای خرید سرویس  جدید یا تمدید سرویس  به آیدی @SecureSupportBot  مراجعه کنید. \n\n›› لینک گروه پشتیبانی : \nhttps://t.me/joinchat/DE6jKEHsNosxJU_lDjR_5w\n\n›› کانال ما : @Secure_Tm', 1, 'html');sendText(-263678237, '', 0, 1, nil, 'با سلام خدمت ادمین های محترم \n*››* شارژ گروه [ '..chat_id..' - '..(redis:get("groupName:"..chat_id) or '----')..' ] به پایان رسید و ربات با موفقیت از گروه خارج شد.', 1, 'md');changeChatMemberStatus(chat_id, bot_id, 'Left');redis:srem("addbot:", chat_id);redis:del("adder:"..chat_id, true);return del_stats(msg.chat_id_);end
end
if is_admin(msg) then
if not redis:get("adder:"..chat_id) then;sendText(-263678237, '', 0, 1, nil, '■ کاربر '..user_id..' من را به گروه ( '..chat_id..' ) دعوت کرد.', 1, 'md');redis:set("adder:"..chat_id, true);end
if txt:match('^بروز$') then;loadfile("./bot.lua")();sendText(chat_id, msg.id_, 0, 1, nil, 'ربات بازخوانی شد.', 1, 'md');local chat = redis:smembers('addbot:');local limit = 5;for i=1, #chat do;tdcli.openChat(chat[i]);tdcli.getChatHistory(chat[i], 0, 0, limit + 1,cb);end;end
if txt:match('^راهنمای ادمین$') then;sendText(chat_id, msg.id_, 0, 1, nil, '*››* برای مشاهده راهنمای ادمین به لینک پایینی مراجعه کنید.\n\nhttps://t.me/SecureBotHelp/8', 1, 'md');end
if txt:match('^نصب ربات$') then;function addbot(extra,result,success);if redis:sismember("addbot:", chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, '*››*گروه افزوده شده بوده!', 1, 'md');else;redis:sadd("addbot:", chat_id);sendText(chat_id, msg.id_, 0, 1, nil, '■ مدیریت ربات آغاز شد!\nلطفا ربات را ادمین کنید.\nسپس راهنما را مطالعه کنید.', 1, 'md');tdcli.sendContact(msg.chat_id_, '', 0, 1, nil, 79772718830, 'Secure', 'TG', bot_id);return forward();end;end;getUser(msg.sender_user_id_,addbot);end
if txt:match("^لیست گروه ها$") then;local text = "لیست گروه های مدیریتی\n====\n";for k,v in pairs(redis:smembers('addbot:')) do;local ex = redis:ttl("chargeg:"..v);if ex == -1 then;gpcharge = 'نامحدود';else;local expire = math.floor(ex/day) + 1;gpcharge = ''..expire..' روز';end;local gpnm = redis:get("groupName:"..v);if gpnm then;gpnme = gpnm;else;gpnme = '--';end;text = text..""..k.." - ("..v..")\nنام گروه : "..gpnme.."\n[انقضا : "..gpcharge.."]\n➖➖➖➖➖➖➖➖\n";gpnumber = k;end;writefile("group_list.txt", text) ;tdcli_function({ID = "SendMessage",chat_id_ = chat_id,reply_to_message_id_ = msg.id_,disable_notification_ = 1,from_background_ = 1,reply_markup_ = cmd,input_message_content_ = {ID = "InputMessageDocument",document_ = {ID = "InputFileLocal",path_ = "group_list.txt"},caption_ = "›› لیست گروه های مدیریتی به همراه انقضا.\n\n■ تعداد گروه ها : "..gpnumber..""}}, cb or dl_cb, cmd);end
if txt:match("^آمار$") then;local gps = redis:scard("gps:");local users = redis:scard("pv:");local allmgs = redis:get("allmsg:");local sgps = redis:scard("sgps:");local k = 0;for k,v in pairs(redis:smembers('addbot:')) do;x = k;end;local text = ( io.popen("sh ./serverinfo.sh"):read("*a") );sendText(chat_id, msg.id_, 0, 1, nil, "*››* آمار ربات سیکیور :\n\n■ سوپرگروه ها : "..sgps.."\n\n□ گروه ها : "..gps.."\n\n■ کاربران : "..users.."\n\n□ گروه های مدیریتی : "..x.."\n\n■ پیام های ارسالی : "..allmgs.."\n\n*››* اطلاعات کنونی سرور : \n\n □ زمان سرور : "..os.date("%H:%M:%S").."\n\n"..text.."□ آپتایم : "..uptime().."\n\n• @Secure\\_Tm", 1, 'md');end
if txt:match('^لغو نصب$') then;redis:srem("addbot:", chat_id);redis:del("adder:"..chat_id, true);redis:del("chargeg:"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '■ مديريت گروه لغو شد.', 1, 'md');return del_stats(msg.chat_id_);elseif txt:match("^لغو نصب (-%d+)$") then;redis:srem("addbot:", txt:match("^لغو نصب (-%d+)$"));redis:del("adder:"..txt:match("^لغو نصب (-%d+)$"), true);redis:del("chargeg:"..txt:match("^لغو نصب (-%d+)$"), true);sendText(txt:match("^لغو نصب (-%d+)$"), '', 0, 1, nil, '■ مدیریت گروه به دستور ادمین لغو شد!\n*››* برای پیگیری دلیل لغو مدیریت ربات به ایدی @SecureSupportBot مراجعه کنید.', 1, 'md');sendText(chat_id, msg.id_, 0, 1, nil, '■ ربات با موفقیت در گروه '..txt:match("^لغو نصب (-%d+)$")..' لغو نصب شد.', 1, 'md');return del_stats(txt:match("^لغو نصب (-%d+)$"));end
if txt:match("^خروج ربات$") then;sendText(chat_id, msg.id_, 0, 1, nil, '■ ربات با موفقیت خارج شد.', 1, 'md');changeChatMemberStatus(chat_id, bot_id, 'Left');elseif txt:match("^خروج ربات (-%d+)$") then;sendText(txt:match("^خروج ربات (-%d+)$"), '', 0, 1, nil, '■ربات بنا به درخواست ادمین از گروه خارج میشود!\n*››* لطفا برای پیگیری دلیل خروج به ایدی @SecureSupportBot مراجعه کنید.', 1, 'md');sendText(chat_id, msg.id_, 0, 1, nil, '■ ربات با موفقیت از گروه '..txt:match("^خروج ربات (-%d+)$")..' خارج شد.', 1, 'md');changeChatMemberStatus(txt:match("^خروج ربات (-%d+)$"), bot_id, 'Left');end
if txt:match("^ورود ([https?://w]*.?telegram.me/joinchat/.*)$") or  txt:match("^ورود ([https?://w]*.?t.me/joinchat/.*)$") then;local link = txt:match("^ورود ([https?://w]*.?telegram.me/joinchat/.*)$") or  txt:match("^ورود ([https?://w]*.?t.me/joinchat/.*)$");if link:match('t.me') then;link = string.gsub(link, 't.me', 'telegram.me');end;tdcli.importChatInviteLink(link, dl_cb, nil);sendText(chat_id, msg.id_, 0, 1, nil, '<b>››</b> با موفقیت وارد شدم ●_●', 1, 'html');end
if txt:match("^دعوت$") and reply_id then;function inv_reply(extra, result, success);tdcli.addChatMember(chat_id, result.sender_user_id_, 20);end;tdcli.getMessage(chat_id,msg.reply_to_message_id_,inv_reply,nil);elseif txt:match("^دعوت @(.*)$") then;function inv_username(extra, result, success);if result.id_ then;tdcli.addChatMember(chat_id, result.id_, 20);else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد', 1, 'md');end;end;tdcli.searchPublicChat(txt:match("^دعوت @(.*)$"),inv_username);end
if txt:match("بکنش") and tonumber(reply_id) > 0 then;function bokonesh(extra, result, success);if result.sender_user_id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, '😂❤️صیک', 1, 'md');elseif result.sender_user_id_ == sudo_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'برو عمتو بکن جاکش😂', 1, 'md');else;sleep(2);tdcli.sendSticker(msg.chat_id_, msg.reply_to_message_id_, 0, 1, nil, 'CAADBAAD1wcAAiijTgwGQo5NpRo9cgI');sleep(4);sendText(chat_id, msg.id_, 0, 1, nil, 'حله داداچ ریختم توش😐', 1, 'md');sleep(5);sendText(chat_id, msg.reply_to_message_id_, 0, 1, nil, 'دردت گرفت؟ خوب میشی😐', 1, 'md');end;end;getMessage(chat_id,msg.reply_to_message_id_,bokonesh,nil);end
if txt:match("^تنظیم مقام (.*)$") and tonumber(reply_id) > 0 then;function rank_reply(extra, result, success);local rank = txt:match("^تنظیم مقام (.*)$");redis:set("rank:"..result.sender_user_id_, rank);SendMetion(chat_id, result.sender_user_id_, msg.id_, '■ مقام '..result.sender_user_id_..' به '..rank..' تنظیم شد.', 7, utf8.len(result.sender_user_id_));end;getMessage(chat_id,msg.reply_to_message_id_,rank_reply,nil);end
if txt:match("^حذف مقام$") and tonumber(reply_id) > 0 then;function delrank_reply(extra, result, success);redis:del("rank:"..result.sender_user_id_);sendText(chat_id, msg.id_, 0, 1, nil, 'مقام شخص مورد نظر حذف شد.', 1, 'md');end;getMessage(chat_id,msg.reply_to_message_id_,delrank_reply,nil);end
if txt:match('^شارژ یک ماهه (-%d+)$') then;local timeplan = 2592000;local gp = txt:match('^شارژ یک ماهه (-%d+)$');redis:setex("chargeg:"..gp,timeplan,true);sendText(gp, '', 0, 1, nil, 'گروه شما به دستور ادمین با موفقیت به میزان [30] روز شارژ شد.', 1, 'md');sendText(chat_id, msg.id_, 0, 1, nil, 'گروه '..gp..' به میزان [30] روز شارژ شد.', 1, 'md');end
if txt:match('^شارژ سه ماهه (-%d+)$') then;local timeplan = 7776000;local gp = txt:match('^شارژ سه ماهه (-%d+)$');redis:setex("chargeg:"..gp,timeplan,true);sendText(gp, '', 0, 1, nil, 'گروه شما به دستور ادمین با موفقیت به میزان [90] روز شارژ شد.', 1, 'md');sendText(chat_id, msg.id_, 0, 1, nil, 'گروه '..gp..' به میزان [90] روز شارژ شد.', 1, 'md');end
if txt:match('^شارژ دائمی (-%d+)$') then;local gp = txt:match('^شارژ دائمی (-%d+)$');redis:set("chargeg:"..gp,true);sendText(gp, '', 0, 1, nil, 'گروه شما به دستور ادمین با موفقیت به میزان [نامحدود(دائمی)] شارژ شد.', 1, 'md');sendText(chat_id, msg.id_, 0, 1, nil, 'گروه '..gp..' به میزان [نامحدود(دائمی)] شارژ شد.', 1, 'md');end
if txt:match('^تنظیم انقضا (%d+)$') then;local gp = txt:match('تنظیم انقضا (%d+)$');local time = gp * day;redis:setex("chargeg:"..msg.chat_id_,time,true);sendText(chat_id, msg.id_, 0, 1, nil, 'گروه با موفقیت به میزان ['..gp..'] روز شارژ شد.', 1, 'md');return forward();end;
if txt:match('^تنظیم انقضا دائمی$') then;redis:set("chargeg:"..msg.chat_id_,true);sendText(chat_id, msg.id_, 0, 1, nil, 'گروه با موفقیت به میزان [نامحدود(دائمی)] شارژ شد.', 1, 'md');return forward();end
if txt:match("^سوپر بن$") and tonumber(reply_id) > 0 then;function gban_reply(extra, result, success);if result.sender_user_id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم رو از همه گروه مسدود کنم!', 1, 'md');elseif is_admin2(result.sender_user_id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( ادمین ها , سازندگان ) ربات را مسدود کنید!', 1, 'md');elseif redis:sismember("gban:", result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص از قبل  جزو مسدودین همگانی بود.', 1, 'md');else;redis:sadd("gban:", result.sender_user_id_);blockUser(result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از همه گروه ‌ها مسدود شد.', 9, utf8.len(result.sender_user_id_));local ggps = redis:smembers('addbot:') or 0;for i=1, #ggps do;changeChatMemberStatus(ggps[i], result.sender_user_id_, 'Kicked');end;end;end;getMessage(chat_id,msg.reply_to_message_id_,gban_reply,nil);end
if txt:match("^سوپر بن @(.*)$") then;function sban_username(extra, result, success);if result.id_ then;if result.id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم رو از همه گروه مسدود کنم!', 1, 'md');elseif is_admin2(result.id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( ادمین ها , سازندگان ) ربات را مسدود کنید!', 1, 'md');elseif redis:sismember('gban:', result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص از قبل  جزو مسدودین همگانی بود.', 1, 'md');else;redis:sadd("gban:", result.id_);blockUser(result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از همه گروه ‌ها مسدود شد.', 9, utf8.len(result.id_));local ggps = redis:smembers('addbot:') or 0;for i=1, #ggps do;changeChatMemberStatus(ggps[i], result.id_, 'Kicked');end;end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد', 1, 'md');end;end;searchPublicChat(txt:match("^سوپر بن @(.*)$"),sban_username);end
if txt:match("^سوپر بن (%d+)$") then;local kc = tonumber(txt:match("^سوپر بن (%d+)$"));if kc == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم رو از همه گروه مسدود کنم!', 1, 'md');elseif is_admin2(kc, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( ادمین ها , سازندگان ) ربات را مسدود کنید!', 1, 'md');elseif redis:sismember('gban:', kc) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص از قبل  جزو مسدودین همگانی بود.', 1, 'md');else;redis:sadd('gban:', kc);blockUser(kc);SendMetion(chat_id, kc, msg.id_, '›› کاربر '..kc..' از همه گروه ‌ها مسدود شد.', 9, utf8.len(kc));local ggps = redis:smembers('addbot:') or 0;for i=1, #ggps do;changeChatMemberStatus(ggps[i], kc, 'Kicked');end;end;end
if txt:match("^لغو سوپر بن$") and tonumber(reply_id) > 0 then;function ungban_user(extra, result, success);if not redis:sismember('gban:', result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص از قبل  جزو مسدودین همگانی نبود!', 1, 'md');else;redis:srem('gban:', result.sender_user_id_);unblockUser(result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از مسدودیت همگانی خارج شد.', 9, utf8.len(result.sender_user_id_));local ggps = redis:smembers('addbot:') or 0;for i=1, #ggps do;changeChatMemberStatus(ggps[i], result.sender_user_id_, 'Left', dl_cb, nil);end;end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,ungban_user);end
if txt:match("^لغو سوپر بن @(.*)$") then;local secure = {string.match(txt, "^(لغو سوپر بن) @(.*)$")};function ungban_name(extra, result, success);if result.id_ then;if not redis:sismember('gban:', result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص از قبل  جزو مسدودین همگانی نبود!', 1, 'md');else;redis:srem('gban:', result.id_);unblockUser(result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از مسدودیت همگانی خارج شد.', 9, utf8.len(result.id_));local ggps = redis:smembers('addbot:') or 0;for i=1, #ggps do;changeChatMemberStatus(ggps[i], result.id_, 'Left', dl_cb, nil);end;end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],ungban_name);end
if txt:match("^لغو سوپر بن (%d+)$") then;local kc = tonumber(txt:match("^لغو سوپر بن (%d+)$"));if not redis:sismember('gban:', kc) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص از قبل  جزو مسدودین همگانی نبود!', 1, 'md');else;redis:srem('gban:', kc);unblockUser(kc);SendMetion(chat_id, kc, msg.id_, '›› کاربر '..kc..' از مسدودیت همگانی خارج شد.', 9, utf8.len(kc));local ggps = redis:smembers('addbot:') or 0;for i=1, #ggps do;changeChatMemberStatus(ggps[i], kc, 'Left', dl_cb, nil);end;end;end
if txt:match("^لیست سوپر بن$") then;local text = "لیست کاربرانی که از تمامی سیستم ربات مسدود شدند : \n====\n";for k,v in pairs(redis:smembers('gban:')) do;text = text..""..k.." - "..v.."\n";gbanmembers = k;end;writefile("ListSuperBan.txt", text);tdcli_function({ID = "SendMessage",chat_id_ = chat_id,reply_to_message_id_ = msg.id_,disable_notification_ = 1,from_background_ = 1,reply_markup_ = cmd,input_message_content_ = {ID = "InputMessageDocument",document_ = {ID = "InputFileLocal",path_ = "ListSuperBan.txt"},caption_ = "›› لیست کاربرانی که از تمام گروه های مدیریتی ربات مسدود هستند.\n\n■ تعداد : "..gbanmembers.." کاربر"}}, cb or dl_cb, cmd);end
if txt:match("^شارژ هدیه (%d+)$") then;local gp = txt:match('شارژ هدیه (%d+)$');for k,v in pairs(redis:smembers('addbot:')) do;local ex = redis:ttl("chargeg:"..v);if ex and ex >= 0 then;local b = math.floor(ex / day) + 1;local t = tonumber(gp);local time_ = b + t;local time = time_ * day;redis:setex("chargeg:"..v,time,true);end;XD = k;end;sendText(chat_id, msg.id_, 0, 1, nil, '›› تعداد `'..XD..'` گروه ربات به مدت `'..gp..'` روز با موفقیت شارژ شد.', 1, 'md');end;
end
if is_sudo(msg) then
if txt:match("^[lL][uU][aA] (.*)") then;local txt = txt:match("^[lL][uU][aA] (.*)");local output = loadstring(txt)();if output == nil then;output = "";elseif type(output) == "table" then;output = serpent.block(output, {comment = false});else;utput = "" .. tostring(output);end;sendText(chat_id, msg.id_, 0, 1, nil,output, 1, 'html');end
if txt:match("^افزودن ادمین$") and tonumber(reply_id) > 0 then;function setadmin_reply(extra, result, success);if redis:sismember("botadmin:", result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص ادمين بود!', 1, 'md');else;redis:sadd("botadmin:", result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' ادمين مدیریتی ربات شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(chat_id,msg.reply_to_message_id_,setadmin_reply,nil);end
if txt:match("^افزودن ادمین @(.*)$") then;function setadmin_username(extra, result, success);if result.id_ then;if redis:sismember('botadmin:', result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص ادمين بود!', 1, 'md');else;redis:sadd("botadmin:", result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' ادمين مدیریتی ربات شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^افزودن ادمین @(.*)$"),setadmin_username);end
if txt:match("^افزودن ادمین (%d+)$") then;if redis:sismember('botadmin:', txt:match("^افزودن ادمین (%d+)$")) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص ادمين بود!', 1, 'md');else;redis:sadd('botadmin:', txt:match("^افزودن ادمین (%d+)$"));SendMetion(chat_id, txt:match("^افزودن ادمین (%d+)$"), msg.id_, '›› کاربر '..txt:match("^افزودن ادمین (%d+)$")..' ادمين مدیریتی ربات شد.', 9, utf8.len(txt:match("^افزودن ادمین (%d+)$")));end;end
if txt:match("^حذف ادمین$") and tonumber(reply_id) > 0 then;function remadmin_reply(extra, result, success);if not redis:sismember("botadmin:", result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص ادمین نبود!', 1, 'md');else;redis:srem("botadmin:", result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از ادمینی برکنار شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(chat_id,msg.reply_to_message_id_,remadmin_reply,nil);end
if txt:match("^حذف ادمین @(.*)$") then;function remadmin_username(extra, result, success);if result.id_ then;if not redis:sismember('botadmin:', result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص ادمین نبود', 1, 'md');else;redis:srem('botadmin:', result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از ادمینی برکنار شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^حذف ادمین @(.*)$"),remadmin_username);end
if txt:match("^حذف ادمین (%d+)$") then;if not redis:sismember('botadmin:', txt:match("^حذف ادمین (%d+)$")) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص ادمین نبود!', 1, 'md');else;redis:srem('botadmin:', txt:match("^حذف ادمین (%d+)$"));SendMetion(chat_id, txt:match("^حذف ادمین (%d+)$"), msg.id_, '›› کاربر '..txt:match("^حذف ادمین (%d+)$")..' از ادمینی برکنار شد.', 9, utf8.len(txt:match("^حذف ادمین (%d+)$")));end;end
if txt:match("^لیست ادمین ها$") then;local text = "لیست ادمین های مدیریتی : \n====\n";for k,v in pairs(redis:smembers('botadmin:')) do;text = text.."*"..k.."* - `"..v.."`\n";end;sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md');end
if txt:match("^پاکسازی لیست ادمین ها$") then;redis:del('botadmin:');sendText(chat_id, msg.id_, 0, 1, nil, 'ليست ادمين ‌های ربات پاكسازی شد.', 1, 'md');end
if txt:match('^بازنشانی آمار$') then;redis:del("gps:");redis:del("pv:");redis:del("allmsg:");redis:del("sgps:");sendText(chat_id, msg.id_, 0, 1, nil, 'آمار ربات با موفقیت بازنشانی شد.', 1, 'md');end
if txt:match('^فوروارد به همه$') and msg.reply_to_message_id_ ~= 0 then;local k = 0;for k,v in pairs(redis:smembers('addbot:')) do;x = k ;end;local gp = redis:smembers('addbot:') or 0;for i=1, #gp do;tdcli.forwardMessages(gp[i], chat_id,{[0] = reply_id}, 0);end;sendText(chat_id, msg.id_, 0, 1, nil, 'پیام شما با موفقیت به '..x..' گروه فروارد شد.', 1, 'md');end
if txt:match("^پاکسازی لیست سوپر بن$") then;redis:del('gban:');sendText(chat_id, msg.id_, 0, 1, nil, 'لیست مسدودین همگانی  پاکسازی شد.', 1, 'md');return io.popen("rm -rf ListSuperBan.txt"):read("*all");end
if txt:match('^زمان سرور$') then;sendText(chat_id, msg.id_, 0, 1, nil, 'ساعت ثبت شده در سرور '..os.date("%H:%M:%S")..' میباشد.', 1, 'md');end
if txt:match("^عضویت اجباری (.*)$") then;local mat = {string.match(txt, "^(عضویت اجباری) (.*)$")};if mat[2] == "روشن" then;if not redis:get("join") then;redis:set("join", true);sendText(chat_id, msg.id_, 0, 1, nil,"*››* عضویت اجباری روشن شد.", 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil,"*››* عضویت اجباری روشن بود!", 1, 'md');end;end;if mat[2] == "خاموش" then;if redis:get("join") then;redis:del("join");sendText(chat_id, msg.id_, 0, 1, nil,"*››* عضویت اجباری روشن خاموش شد.", 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil,"*››* عضویت اجباری روشن خاموش بود!", 1, 'md');end;end;end
end
--------------------------
if redis:sismember("addbot:", chat_id) then
if is_gbanned(msg.sender_user_id_) or redis:get("lockcmd"..chat_id) and not is_mod(msg) then;return false;end
if is_mod(msg) then
if txt:match('^مدیریت$') then;function inline(arg,data);if data.inline_query_id_ then;tdcli_function({ID = "SendInlineQueryResultMessage",chat_id_ = msg.chat_id_,reply_to_message_id_ = msg.id_,disable_notification_ = 0,from_background_ = 1,query_id_ = data.inline_query_id_,result_id_ = data.results_[0].id_}, dl_cb, nil);else;sendText(chat_id, msg.id_, 0, 1, nil, 'خطا !\nنمیتوانم به ربات هلپر دسترسی پیدا کنم .', 1, 'md');end;end;tdcli_function({ID = "GetInlineQueryResults",bot_user_id_ = 431954803,chat_id_ = msg.chat_id_,user_location_ = {ID = "Location",latitude_ = 0,longitude_ = 0},query_ = tostring(msg.chat_id_)..',setting',offset_ = 0}, inline, nil);end
if txt:match('^تنظیمات$') then;if not redis:get("locklink"..chat_id) then;lock_link = 'غیرفعال';else;lock_link = 'فعال';end;if not redis:get("lockchat"..chat_id) then;lock_chat = 'غیرفعال';else;lock_chat = 'فعال';end;if not redis:get("lockflood"..chat_id) then;lock_flood = 'غیرفعال';else;lock_flood = 'فعال';end;if not redis:get('floodmax'..msg.chat_id_) then;flood_max = 5;else;flood_max = redis:get('floodmax'..msg.chat_id_);end;if not redis:get('cher'..msg.chat_id_) then;chers = 250;else;chers = redis:get('cher'..msg.chat_id_);end;if not redis:get("lockcontact"..chat_id) then;lock_contact = 'غیرفعال';else;lock_contact = 'فعال';end;if not redis:get("lockedit"..chat_id) then;lock_edit = 'غیرفعال';else;lock_edit = 'فعال';end;if not redis:get("lockinline"..chat_id) then;lock_inline = 'غیرفعال';else;lock_inline = 'فعال';end;if not redis:get("lockfarsi"..chat_id) then;lock_farsi = 'غیرفعال';else;lock_farsi = 'فعال';end;if not redis:get("lockselfvideo"..chat_id) then;lock_selfvideo = 'غیرفعال';else;lock_selfvideo = 'فعال';end;if not redis:get("locktext"..chat_id) then;lock_text = 'غیرفعال';else;lock_text = 'فعال';end;if not redis:get("locktgservice"..chat_id) then;lock_tgservice = 'غیرفعال';else;lock_tgservice = 'فعال';end;if not redis:get("lockvideo"..chat_id) then;lock_video = 'غیرفعال';else;lock_video = 'فعال';end;if not redis:get("lockcher"..chat_id) then;lock_cher = 'غیرفعال';else;lock_cher = 'فعال';end;if not redis:get("lockphoto"..chat_id) then;lock_photo = 'غیرفعال';else;lock_photo = 'فعال';end;if not redis:get("lockfwd"..chat_id) then;lock_fwd = 'غیرفعال';else;lock_fwd = 'فعال';end;if not redis:get("lockenglish"..chat_id) then;lock_english = 'غیرفعال';else;lock_english = 'فعال';end;if not redis:get("lockaudio"..chat_id) then;lock_audio = 'غیرفعال';else;lock_audio = 'فعال';end;if not redis:get("locksticker"..chat_id) then;lock_sticker = 'غیرفعال';else;lock_sticker = 'فعال';end;if not redis:get("lockcmd"..chat_id) then;lock_cmd = 'غیرفعال';else;lock_cmd = 'فعال';end;if not redis:get("lockpin"..chat_id) then;lock_pin = 'غیرفعال';else;lock_pin = 'فعال';end;if not redis:get("lockfile"..chat_id) then;lock_file = 'غیرفعال';else;lock_file = 'فعال';end;if not redis:get("locktag"..chat_id) then;lock_tag = 'غیرفعال';else;lock_tag = 'فعال';end;if not redis:get("lockbots"..chat_id) then;lock_bots = 'غیرفعال';else;lock_bots = 'فعال';end;if not redis:get("lockgif"..chat_id) then;lock_gif = 'غیرفعال';else;lock_gif = 'فعال';end;if not redis:get("wlc:"..chat_id) then;welcome = 'غیرفعال';else;welcome = 'فعال';end;if not redis:get("lc_ato:"..msg.chat_id_) then;auto_lock = 'غیرفعال';else;auto_lock = 'فعال';end;local start = redis:get("atolct1"..msg.chat_id_);if not redis:get("atolct1"..msg.chat_id_) then;auto_lock_start = 'ثبت نشده است ';else;auto_lock_start = 'از ساعت '..start;end;local stop = redis:get("atolct2"..msg.chat_id_);if not redis:get("atolct2"..msg.chat_id_) then;auto_lock_stop = '';else;auto_lock_stop = 'تا ساعت '..stop;end;local ex = redis:ttl("chargeg:"..msg.chat_id_);if ex == -1 then;charge = 'نامحدود';else;local expire = math.floor(ex/day) + 1;charge = ''..expire..' روز';end;sendText(chat_id, msg.id_, 0, 1, nil,'₪ تنظیمات گروه :\n\n-| قفل چت : '..lock_chat..'\n-| وضعیت قفل خودکار : '..auto_lock..'\n-| ساعات تعطیلی گروه : '..auto_lock_start..''..auto_lock_stop..'\n\n-| قفل رگبار : '..lock_flood..'\n-| حداکثر ارسال رگبار : '..flood_max..'\n-| قفل ربات : '..lock_bots..'\n\n-| قفل گیف : '..lock_gif..'\n-| قفل فیلم : '..lock_video..'\n-| قفل فیلم سلفی : '..lock_selfvideo..'\n\n-| قفل لینک : '..lock_link..'\n-| قفل فوروارد : '..lock_fwd..'\n-| قفل یوزرنیم : '..lock_tag..'\n\n-| قفل کاراکتر : '..lock_cher..'\n-| مقدار حساسيت كاراكتر : '..chers..'\n-| قفل متن : '..lock_text..'\n\n-| قفل عکس : '..lock_photo..'\n-| قفل صدا : '..lock_audio..'\n-| قفل استیکر : '..lock_sticker..'\n\n-| قفل دستورات : '..lock_cmd..'\n-| قفل مخاطب : '..lock_contact..'\n-| قفل اینلاین : '..lock_inline..'\n\n-| قفل ویرایش : '..lock_edit..'\n-| قفل فارسی : '..lock_farsi..'\n-| قفل انگلیسی : '..lock_english..'\n\n-| قفل پیام سرویسی : '..lock_tgservice..'\n-| قفل فایل : '..lock_file..'\n-| خوش آمدگویی : '..welcome..'\n\n-| قفل سنجاق : '..lock_pin..'\n-| تاریخ انقضا : '..charge..'\n-| آیدی گروه : '..chat_id..'', 1, 'md');end
if txt:match("^قفل (.*)$") then;local mat = {string.match(txt, "^(قفل) (.*)$")};if mat[2] == "لینک" then;if not redis:get("locklink"..chat_id) then;redis:set("locklink"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل لینک فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل لینک فعال بود!', 1, 'md');end;end;if mat[2] == "فوروارد" then;if not redis:get("lockfwd"..chat_id) then;redis:set("lockfwd"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فوروارد فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فوروارد فعال بود!', 1, 'md');end;end;if mat[2] == "دستورات" then;if not redis:get("lockcmd"..chat_id) then;redis:set("lockcmd"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل دستورات فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل دستورات فعال بود!', 1, 'md');end;end;if mat[2] == "چت" then;if not redis:get("lockchat"..chat_id) then;redis:set("lockchat"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل چت فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل چت فعال بود!', 1, 'md');end;end;if mat[2] == "مخاطب" then;if not redis:get("lockcontact"..chat_id) then;redis:set("lockcontact"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل مخاطب فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل مخاطب فعال بود!', 1, 'md');end;end;if mat[2] == "اینلاین" then;if not redis:get("lockinline"..chat_id) then;redis:set("lockinline"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل اینلاین فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل اینلاین فعال بود!', 1, 'md');end;end;if mat[2] == "فیلم سلفی" then;if not redis:get("lockselfvideo"..chat_id) then;redis:set("lockselfvideo"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم سلفی فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم سلفی فعال بود!', 1, 'md');end;end;if mat[2] == "پیام سرویسی" then;if not redis:get("locktgservice"..chat_id) then;redis:set("locktgservice"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل پیام سرویسی فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل پیام سرویسی فعال بود!', 1, 'md');end;end;if mat[2] == "گیف" then;if not redis:get("lockgif"..chat_id) then;redis:set("lockgif"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل گیف فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل گیف فعال بود!', 1, 'md');end;end;if mat[2] == "فیلم" then;if not redis:get("lockvideo"..chat_id) then;redis:set("lockvideo"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم فعال بود!', 1, 'md');end;end;if mat[2] == "عکس" then;if not redis:get("lockphoto"..chat_id) then;redis:set("lockphoto"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل عکس فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل عکس فعال بود!', 1, 'md');end;end;if mat[2] == "صدا" then;if not redis:get("lockaudio"..chat_id) then;redis:set("lockaudio"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل صدا فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل صدا فعال بود!', 1, 'md');end;end;if mat[2] == "استیکر" then;if not redis:get("locksticker"..chat_id) then;redis:set("locksticker"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل استیکر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل استیکر فعال بود!', 1, 'md');end;end;if mat[2] == "فایل" then;if not redis:get("lockfile"..chat_id) then;redis:set("lockfile"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فایل فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فایل فعال بود!', 1, 'md');end;end;if mat[2] == "ربات" then;if not redis:get("lockbots"..chat_id) then;redis:set("lockbots"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ربات فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ربات فعال بود!', 1, 'md');end;end;if mat[2] == "یوزرنیم" then;if not redis:get("locktag"..chat_id) then;redis:set("locktag"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل یوزرنیم فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل یوزرنیم فعال بود!', 1, 'md');end;end;if mat[2] == "ویرایش" then;if not redis:get("lockedit"..chat_id) then;redis:set("lockedit"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ویرایش پیام فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ویرایش پیام فعال بود!', 1, 'md');end;end;if mat[2] == "فارسی" then;if not redis:get("lockfarsi"..chat_id) then;redis:set("lockfarsi"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات عربی/فارسی فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات عربی/فارسی فعال بود!', 1, 'md');end;end;if mat[2] == "انگلیسی" then;if not redis:get("lockenglish"..chat_id) then;redis:set("lockenglish"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات انگلیسی فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات انگلیسی فعال بود!', 1, 'md');end;end;if mat[2] == "رگبار" then;if not redis:get("lockflood"..chat_id) then;redis:set("lockflood"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل رگبار فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل رگبار فعال بود!', 1, 'md');end;end;if mat[2] == "سنجاق" then;if is_owner(msg) then;if not redis:get("lockpin"..chat_id) then;redis:set("lockpin"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل سنجاق کردن پیام فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل سنجاق کردن پیام فعال بود!', 1, 'md');end;else;sendText(chat_id, msg.id_, 0, 1, nil,'شما دسترسی ندارید!', 1, 'md');end;end;if mat[2] == "کاراکتر" then;if not redis:get("lockcher"..chat_id) then;redis:set("lockcher"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کاراکتر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کاراکتر فعال بود!', 1, 'md');end;end;if mat[2] == "متن" then;if not redis:get("locktext"..chat_id) then;redis:set("locktext"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل متن فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل متن فعال بود!', 1, 'md');end;end;end
if txt:match("^بازکردن (.*)$") then;local unmat = {string.match(txt, "^(بازکردن) (.*)$")};if unmat[2] == "لینک" then;if redis:get("locklink"..chat_id) then;redis:del("locklink"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل لینک غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل لینک غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "فوروارد" then;if redis:get("lockfwd"..chat_id) then;redis:del("lockfwd"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فوروارد غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فوروارد غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "دستورات" then;if redis:get("lockcmd"..chat_id) then;redis:del("lockcmd"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل دستورات غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل دستورات غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "چت" then;if redis:get("lockchat"..chat_id) then;redis:del("lockchat"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل چت غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل چت غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "مخاطب" then;if redis:get("lockcontact"..chat_id) then;redis:del("lockcontact"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل مخاطب غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل مخاطب غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "اینلاین" then;if redis:get("lockinline"..chat_id) then;redis:del("lockinline"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل اینلاین غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل اینلاین غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "فیلم سلفی" then;if redis:get("lockselfvideo"..chat_id) then;redis:del("lockselfvideo"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم سلفی غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم سلفی غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "پیام سرویسی" then;if redis:get("locktgservice"..chat_id) then;redis:del("locktgservice"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل پیام سرویسی غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل پیام سرویسی غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "گیف" then;if redis:get("lockgif"..chat_id) then;redis:del("lockgif"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل گیف غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل گیف غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "فیلم" then;if redis:get("lockvideo"..chat_id) then;redis:del("lockvideo"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم غیر فعال شد!', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فیلم غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "عکس" then;if redis:get("lockphoto"..chat_id) then;redis:del("lockphoto"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل عکس غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل عکس غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "صدا" then;if redis:get("lockaudio"..chat_id) then;redis:del("lockaudio"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل صدا غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل صدا غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "استیکر" then;if redis:get("locksticker"..chat_id) then;redis:del("locksticker"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل استیکر غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل استیکر غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "فایل" then;if redis:get("lockfile"..chat_id) then;redis:del("lockfile"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فایل غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل فایل غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "ربات" then;if redis:get("lockbots"..chat_id) then;redis:del("lockbots"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ربات غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ربات غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "یوزرنیم" then;if redis:get("locktag"..chat_id) then;redis:del("locktag"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل یوزرنیم غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل یوزرنیم غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "ویرایش" then;if redis:get("lockedit"..chat_id) then;redis:del("lockedit"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ویرایش پیام غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل ویرایش پیام غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "فارسی" then;if redis:get("lockfarsi"..chat_id) then;redis:del("lockfarsi"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات عربی/فارسی غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات عربی/فارسی غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "انگلیسی" then;if redis:get("lockenglish"..chat_id) then;redis:del("lockenglish"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات انگلیسی غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کلمات انگلیسی غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "رگبار" then;if redis:get("lockflood"..chat_id) then;redis:del("lockflood"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل رگبار غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل رگبار غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "سنجاق" then;if is_owner(msg) then;if redis:get("lockpin"..chat_id) then;redis:del("lockpin"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل سنجاق کردن پیام غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل سنجاق کردن پیام غیر فعال بود!', 1, 'md');end;else;sendText(chat_id, msg.id_, 0, 1, nil,'شما دسترسی ندارید!', 1, 'md');end;end;if unmat[2] == "کاراکتر" then;if redis:get("lockcher"..chat_id) then;redis:del("lockcher"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کاراکتر غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل کاراکتر غیر فعال بود!', 1, 'md');end;end;if unmat[2] == "متن" then;if redis:get("locktext"..chat_id) then;redis:del("locktext"..chat_id, true);sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل متن غیر فعال شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* قفل متن غیر فعال بود!', 1, 'md');end;end;end
if txt:match("^قفل خودکار$") then;redis:setex("atolc"..msg.chat_id_..msg.sender_user_id_,45,true);if redis:get("atolct1"..msg.chat_id_) and redis:get("atolct2"..msg.chat_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, '*››* زمان بندی قبلی از سیستم حذف شد.\n\nلطفا زمان شروع قفل خودکار را وارد کنید :', 1, 'md');redis:del("atolct1"..msg.chat_id_);redis:del("atolct2"..msg.chat_id_);redis:del("lc_ato:"..msg.chat_id_);else;sendText(chat_id, msg.id_, 0, 1, nil, '*››* لطفا زمان شروع قفل خودکار را وارد کنید :', 1, 'md');end;elseif  txt:match("^بازکردن خودکار$") then;if redis:get("atolct1"..msg.chat_id_) and redis:get("atolct2"..msg.chat_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, '*››* زمانبدی ربات برای قفل کردن خودکار گروه حذف شد.', 1, 'md');redis:del("atolct1"..msg.chat_id_);redis:del("atolct2"..msg.chat_id_);redis:del("lc_ato:"..msg.chat_id_);else;sendText(chat_id, msg.id_, 0, 1, nil, 'قفل خودکار ثبت نشده است!', 1, 'md');end;elseif txt:match("^وضعیت قفل خودکار$") then;local t1 = redis:get("atolct1"..msg.chat_id_);local t2 = redis:get("atolct2"..msg.chat_id_);if t1 and t2 then;local lc = redis:get("lc_ato:"..msg.chat_id_);if lc then;stats = "قفل خودکار فعال است.";else;stats = "قفل خودکار غیرفعال است.";end;sendText(chat_id, msg.id_, 0, 1, nil, 'گروه شما در ساعات *'..t1..'* الی *'..t2..'* تعطیل خواهد شد.\n\nوضعیت فعلی گروه : '..stats, 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, 'هیچ زمانی برای تعطیلی گروه ثبت نشده است.', 1, 'md');end;elseif txt:match("^%d+%d+:%d+%d+$") and redis:get("atolc"..msg.chat_id_..msg.sender_user_id_) then;local ap = {string.match(txt, "^(%d+%d+:)(%d+%d+)$")};local h = txt:match("%d+%d+:");h = h:gsub(":", "");local m = txt:match(":%d+%d+");m = m:gsub(":", "");local hh = 23;local mm = 59;if hh >= tonumber(h) and mm >= tonumber(m) then;local hour = tonumber(h);local mine = tonumber(m);local noh = 9;if noh >= tonumber(h) then;hourr1 = '0'..hour;else;hourr1 = hour;end;if noh >= tonumber(m) then;minee1 = '0'..mine;else;minee1 = mine;end;sendText(chat_id, msg.id_, 0, 1, nil, 'زمان شروع قفل خودکار در سیستم ثبت شد.\n\nلطفا زمان پایان قفل خودکار را وارد کنید :', 1, 'md');redis:del("atolc"..msg.chat_id_..msg.sender_user_id_);redis:setex("atolct1"..msg.chat_id_,45,hourr1..':'..minee1);redis:setex("atolc2"..msg.chat_id_..msg.sender_user_id_,45,true);else;sendText(chat_id, msg.id_, 0, 1, nil, 'مشکلی در دریافت ساعت رخ داد', 1, 'md');end;elseif txt:match("^%d+%d+:%d+%d+$") and redis:get("atolc2"..msg.chat_id_..msg.sender_user_id_)  then;local time_1 = redis:get("atolct1"..msg.chat_id_);local ap = {string.match(txt, "^(%d+%d+):(%d+%d+)$")};local h = txt:match("%d+%d+:");h = h:gsub(":", "");local m = txt:match(":%d+%d+");m = m:gsub(":", "");local hh = 23;local mm = 59;if time_1 == tonumber(h)..':'..tonumber(m) then;sendText(chat_id, msg.id_, 0, 1, nil, 'آغاز قفل خودکار نمیتوانید با پایان آن یکی باشد.', 1, 'md');else;if hh >= tonumber(h) and mm >= tonumber(m) then;local hour = tonumber(h);local mine = tonumber(m);local noh = 9;if noh >= tonumber(h) then;hourr = '0'..hour;else;hourr = hour;end;if noh >= tonumber(m) then;minee = '0'..mine;else;minee = mine;end;sendText(chat_id, msg.id_, 0, 1, nil, 'با موفقیت انجام شد.\n\nگروه شما در ساعات *'..hourr1..':'..minee1..'* الی *'..hourr..':'..minee..'* بصورت خودکار تعطیل خواهد شد.', 1, 'md');redis:set("atolct1"..msg.chat_id_,redis:get("atolct1"..msg.chat_id_));redis:set("atolct2"..msg.chat_id_,hourr..':'..minee);redis:del("atolc2"..msg.chat_id_..msg.sender_user_id_);else;sendText(chat_id, msg.id_, 0, 1, nil, 'مشکلی در دریافت ساعت رخ داد', 1, 'md');end;end;end
if txt:match('^فیلتر کردن (.*)$') then;local w = txt:match('^فیلتر کردن (.*)$');redis:sadd('filters:'..msg.chat_id_,w);sendText(chat_id, msg.id_, 0, 1, nil,'<b>››</b> کلمه "<code>'..w..'</code>" به لیست کلمات فیلتر شده اضافه گردید.', 1, 'html');end
if txt:match('^حذف فیلتر (.*)$') then;local w = txt:match('^حذف فیلتر (.*)$');redis:srem('filters:'..msg.chat_id_,w);sendText(chat_id, msg.id_, 0, 1, nil,'<b>››</b> کلمه "<code>'..w..'</code>" از لیست کلمات فیلتر شده پاک شد.', 1, 'html');end
if txt:match('^پاکسازی لیست فیلتر$') then;redis:del('filters:'..msg.chat_id_);sendText(chat_id, msg.id_, 0, 1, nil,'لیست فیلتر گروه پاکسازی شد.', 1, 'md');end
if txt:match("^لیست فیلتر$") then;text = "لیست کلمات فیلتر شده در گروه : \n====\n";for k,v in pairs(redis:smembers('filters:'..chat_id)) do;text = text.."<b>"..k.."</b> - <code>"..v.."</code>\n";end;sendText(chat_id, msg.id_, 0, 1, nil,text, 1, 'html');end
if txt:match('^انقضا$') then;local ex = redis:ttl("chargeg:"..msg.chat_id_);if ex == -1 then;sendText(chat_id, msg.id_, 0, 1, nil, 'مدت زمان گروه شما نامحدود میباشد.', 1, 'md');else;local expire = math.floor(ex/day) + 1;sendText(chat_id, msg.id_, 0, 1, nil, '['..expire..'] روز تا پایان مدت زمان انقضا گروه باقی مانده است.', 1, 'md');end;end
if txt:match('^راهنما$') then;sendText(chat_id, msg.id_, 0, 1, nil, '*››* برای مشاهده راهنمای ربات به لینک پایینی مراجعه کنید \n\nhttps://t.me/SecureBotHelp/25', 1, 'md');end
if txt:match("^اطلاعات گروه$") then;local function gpinfo(extra, result, success);vardump(result);sendText(chat_id, msg.id_, 0, 1, nil, "₪ اطلاعات گروه : \n\n●| تعداد اعضا : *"..result.member_count_.."*\n●| تعداد مدیران : *"..result.administrator_count_.."*\n●| تعداد اعضای حذف شده : *"..result.kicked_count_.."*\n●| شناسه گروه : *-100"..result.channel_.id_.."*", 1, 'md');end;tdcli.getChannelFull(chat_id, gpinfo, {chat_id=chat_id,msg_id=msg.id_});end
if txt:match("^اخراج$") and tonumber(reply_id) > 0 then;function kick_reply(extra, result, success);if result.sender_user_id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم را از گروه اخراج کنم!', 1, 'md');elseif is_mod2(result.sender_user_id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را اخراج کنید!', 1, 'md');else;changeChatMemberStatus(chat_id, result.sender_user_id_, 'Kicked');SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' اخراج شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(chat_id,msg.reply_to_message_id_,kick_reply,nil);end
if txt:match("^اخراج @(.*)$") then;function kick_username(extra, result, success);if result.id_ then;if result.id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم را از گروه اخراج کنم!', 1, 'md');elseif is_mod2(result.id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را اخراج کنید!', 1, 'md');else;changeChatMemberStatus(chat_id, result.id_, 'Kicked');SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' اخراج شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^اخراج @(.*)$"),kick_username);end
if txt:match("^اخراج (%d+)$") then;local kc = tonumber(txt:match("^اخراج (%d+)$"));if kc == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم را از گروه اخراج کنم!', 1, 'md');elseif is_mod2(kc, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را اخراج کنید!', 1, 'md');else;changeChatMemberStatus(chat_id, txt:match("^اخراج (%d+)$"), 'Kicked');SendMetion(chat_id, txt:match("^اخراج (%d+)$"), msg.id_, 'کاربر '..txt:match("^اخراج (%d+)$")..' اخراج شد.', 9, utf8.len(txt:match("^اخراج (%d+)$")));end;end
if txt:match("^سکوت$") and tonumber(reply_id) > 0 then;function mute_user(extra, result, success);if result.sender_user_id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم را در حالت سكوت قرار دهم!', 1, 'md');elseif is_mod2(result.sender_user_id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را ساکت کنید!', 1, 'md');elseif redis:sismember('muted:'..msg.chat_id_, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص از قبل ساكت است.', 1, 'md');else;redis:sadd('muted:'..msg.chat_id_, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' در حالت سكوت قرار گرفت.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,mute_user);end
if txt:match("^سکوت @(.*)$") then;local secure = {string.match(txt, "^(سکوت) @(.*)$")};function mute_name(extra, result, success);if result.id_ then;if result.id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم را در حالت سكوت قرار دهم!', 1, 'md');elseif is_mod2(result.id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را ساکت کنید!', 1, 'md');elseif redis:sismember('muted:'..msg.chat_id_, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص از قبل ساكت است.', 1, 'md');else;redis:sadd('muted:'..msg.chat_id_, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' در حالت سكوت قرار گرفت.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],mute_name);end
if txt:match("^سکوت (%d+)$") then;local kc = tonumber(txt:match("^سکوت (%d+)$"));if kc == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم را در حالت سكوت قرار دهم!', 1, 'md');elseif is_mod2(kc, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را ساکت کنید!', 1, 'md');elseif redis:sismember('muted:'..msg.chat_id_, kc) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص از قبل ساكت است.', 1, 'md');else;redis:sadd('muted:'..msg.chat_id_, kc);SendMetion(chat_id, kc, msg.id_, '›› کاربر '..kc..' در حالت سكوت قرار گرفت.', 9, utf8.len(kc));end;end
if txt:match("^لغو سکوت$") and tonumber(reply_id) > 0 then;function unmute_user(extra, result, success);if not redis:sismember('muted:'..msg.chat_id_, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص در حالت سكوت نيست.', 1, 'md');else;redis:srem('muted:'..msg.chat_id_, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از حالت سكوت خارج شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,unmute_user);end
if txt:match("^لغو سکوت @(.*)$") then;local secure = {string.match(txt, "^(لغو سکوت) @(.*)$")};function unmute_name(extra, result, success);if result.id_ then;if not redis:sismember('muted:'..msg.chat_id_, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص در حالت سكوت نيست.', 1, 'md');else;redis:srem('muted:'..msg.chat_id_, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از حالت سكوت خارج شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],unmute_name);end
if txt:match("^لغو سکوت (%d+)$")  then;local kc = tonumber(txt:match("^لغو سکوت (%d+)$"));if not redis:sismember('muted:'..msg.chat_id_, kc) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص در حالت سكوت نيست.', 1, 'md');else;redis:srem('muted:'..msg.chat_id_, kc);SendMetion(chat_id, kc, msg.id_, '›› کاربر '..kc..' از حالت سكوت خارج شد.', 9, utf8.len(kc));end;end
if txt:match("^لیست سکوت$") then;local text = "لیست سکوت گروه : \n====\n";for k,v in pairs(redis:smembers('muted:'..chat_id)) do;text = text.."*"..k.."* - `"..v.."`\n";end;sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md');end
if txt:match("^پاکسازی لیست سکوت$") then;redis:del('muted:'..chat_id);sendText(chat_id, msg.id_, 0, 1, nil, 'ليست سکوت پاكسازی شد.', 1, 'md');end
if txt:match("^پاکسازی همه$") and tonumber(reply_id) > 0 then;function del_all(extra, result, success);if result.sender_user_id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم پیام های خودم را از گروه پاک کنم!', 1, 'md');elseif is_mod2(result.sender_user_id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید پیام های ( مدیران , سازندگان ) ربات را پاکسازی کنید!', 1, 'md');else;SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› پيام‌های کاربر '..result.sender_user_id_..' پاكسازی شد.', 18, utf8.len(result.sender_user_id_));tdcli.deleteMessagesFromUser(result.chat_id_, result.sender_user_id_);end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,del_all);end
if txt:match("^پاکسازی همه @(.*)$") then;local secure = {string.match(txt, "^(پاکسازی همه) @(.*)$")} ;function del_user(extra, result, success);if result.id_ then;if result.id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم پیام های خودم را از گروه پاک کنم!', 1, 'md');elseif is_mod2(result.id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید پیام های ( مدیران , سازندگان ) ربات را پاکسازی کنید!', 1, 'md');else;SendMetion(chat_id, result.id_, msg.id_, '›› پيام‌های کاربر '..result.id_..' پاكسازی شد.', 18, utf8.len(result.id_));tdcli.deleteMessagesFromUser(msg.chat_id_, result.id_);end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد', 1, 'md');end;end;searchPublicChat(secure[2],del_user);end
if txt:match("^پاکسازی همه (%d+)$") then;local kc = tonumber(txt:match("^پاکسازی همه (%d+)$"));if kc == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم پیام های خودم را از گروه پاک کنم!', 1, 'md');elseif is_mod2(kc, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید پیام های ( مدیران , سازندگان ) ربات را پاکسازی کنید!', 1, 'md');else;SendMetion(chat_id, kc, msg.id_, '›› پيام‌های کاربر '..kc..' پاكسازی شد.', 18, utf8.len(kc));tdcli.deleteMessagesFromUser(msg.chat_id_, kc);end;end
if txt:match("^مسدود$") and tonumber(reply_id) > 0 then;function ban_user(extra, result, success);if result.sender_user_id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم رو از گروه مسدود کنم!', 1, 'md');elseif is_mod2(result.sender_user_id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را مسدود کنید!', 1, 'md');elseif redis:sismember('ban:'..msg.chat_id_, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص از قبل مسدود است.', 1, 'md');else;redis:sadd('ban:'..msg.chat_id_, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از گروه مسدود شد.', 9, utf8.len(result.sender_user_id_));changeChatMemberStatus(chat_id, result.sender_user_id_, 'Kicked');end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,ban_user);end
if txt:match("^مسدود @(.*)$") then;local secure = {string.match(txt, "^(مسدود) @(.*)$")} ;function ban_name(extra, result, success);if result.id_ then;if result.id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم رو از گروه مسدود کنم!', 1, 'md');elseif is_mod2(result.id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را مسدود کنید!', 1, 'md');elseif redis:sismember('ban:'..msg.chat_id_, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص از قبل مسدود است.', 1, 'md');else;redis:sadd('ban:'..msg.chat_id_, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از گروه مسدود شد.', 9, utf8.len(result.id_));changeChatMemberStatus(chat_id, result.id_, 'Kicked');end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],ban_name);end
if txt:match("^مسدود (%d+)$") then;local kc = tonumber(txt:match("^مسدود (%d+)$"));if kc == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم خودم رو از گروه مسدود کنم!', 1, 'md');elseif is_mod2(kc, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید ( مدیران , سازندگان ) ربات را مسدود کنید!', 1, 'md');elseif redis:sismember('ban:'..msg.chat_id_, kc) then;sendText(chat_id, msg.id_, 0, 1, nil,'اين شخص از قبل مسدود است.', 1, 'md');else;redis:sadd('ban:'..msg.chat_id_, kc);SendMetion(chat_id, kc, msg.id_, '›› کاربر '..kc..' از گروه مسدود شد.', 9, utf8.len(kc));changeChatMemberStatus(chat_id, kc, 'Kicked');end;end
if txt:match("^لغو مسدودیت$") and tonumber(reply_id) > 0 then;function unban_user(extra, result, success);if not redis:sismember('ban:'..msg.chat_id_, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص مسدود نشده بود.', 1, 'md');else;redis:srem('ban:'..msg.chat_id_, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از مسدودیت خارج شد.', 9, utf8.len(result.sender_user_id_));changeChatMemberStatus(chat_id, result.sender_user_id_, 'Left', dl_cb, nil);end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,unban_user);end
if txt:match("^لغو مسدودیت @(.*)$") then;local secure = {string.match(txt, "^(لغو مسدودیت) @(.*)$")} ;function unban_name(extra, result, success);if result.id_ then;if not redis:sismember('ban:'..msg.chat_id_, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص مسدود نشده بود.', 1, 'md');else;redis:srem('ban:'..msg.chat_id_, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از مسدودیت خارج شد.', 9, utf8.len(result.id_));changeChatMemberStatus(chat_id, result.id_, 'Left', dl_cb, nil);end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],unban_name);end
if txt:match("^لغو مسدودیت (%d+)$") then;local kc = tonumber(txt:match("^لغو مسدودیت (%d+)$"));if not redis:sismember('ban:'..msg.chat_id_, kc) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص مسدود نشده بود.', 1, 'md');else;redis:srem('ban:'..msg.chat_id_, kc);SendMetion(chat_id, kc, msg.id_, '›› کاربر '..kc..' از مسدودیت خارج شد.', 9, utf8.len(kc));changeChatMemberStatus(chat_id, kc, 'Left', dl_cb, nil);end;end
if txt:match("^لیست مسدودین$") then;local text = "لیست مسدودین گروه : \n====\n";for k,v in pairs(redis:smembers('ban:'..chat_id)) do;text = text.."*"..k.."* - `"..v.."`\n";end;sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md');end
if txt:match("^اخطار$") and tonumber(reply_id) > 0 then;function warn_user(extra, result, success);if result.sender_user_id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم به خودم اخطار دهم!', 1, 'md');elseif is_mod2(result.sender_user_id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید به ( مدیران , سازندگان ) ربات اخطار دهید!', 1, 'md');elseif tonumber(redis:hget('warn:'..chat_id, result.sender_user_id_) or 1) == tonumber(redis:get('max_warn:'..chat_id) or 3) then;changeChatMemberStatus(chat_id, result.sender_user_id_, 'Kicked');redis:hdel('warn:'..chat_id, result.sender_user_id_, '0');SendMetion(chat_id, result.sender_user_id_, msg.id_, 'کاربر '..result.sender_user_id_..' از گروه اخراج شد\n\nتعداد اخطارهای کاربر مورد نظر از '..tonumber(redis:get('max_warn:'..chat_id) or 3)..' بیشتر شد', 6, utf8.len(result.sender_user_id_));else;redis:hset('warn:'..chat_id, result.sender_user_id_, tonumber(redis:hget('warn:'..chat_id, result.sender_user_id_) or 0) + 1);SendMetion(chat_id, result.sender_user_id_, msg.id_, 'کاربر '..result.sender_user_id_..' اخطار گرفت!\n\nتعداد اخطارهای کاربر : ('..tonumber(redis:hget('warn:'..chat_id, result.sender_user_id_))..'/'..tonumber(redis:get('max_warn:'..chat_id) or 3)..')', 6, utf8.len(result.sender_user_id_));end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,warn_user);end
if txt:match("^اخطار @(.*)$") then;local secure = {string.match(txt, "^(اخطار) @(.*)$")};function warn_name(extra, result, success);if result.id_ then;if result.id_ == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم به خودم اخطار دهم!', 1, 'md');elseif is_mod2(result.id_, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید به ( مدیران , سازندگان ) ربات اخطار دهید!', 1, 'md');elseif tonumber(redis:hget('warn:'..chat_id, result.id_) or 1) == tonumber(redis:get('max_warn:'..chat_id) or 3) then;changeChatMemberStatus(chat_id, result.id_, 'Kicked');redis:hdel('warn:'..chat_id, result.id_, '0');SendMetion(chat_id, result.id_, msg.id_, 'کاربر '..result.id_..' از گروه اخراج شد\n\nتعداد اخطارهای کاربر مورد نظر از '..tonumber(redis:get('max_warn:'..chat_id) or 3)..' بیشتر شد', 6, utf8.len(result.id_));else;redis:hset('warn:'..chat_id, result.id_, tonumber(redis:hget('warn:'..chat_id, result.id_) or 0) + 1);SendMetion(chat_id, result.id_, msg.id_, 'کاربر '..result.id_..' اخطار گرفت!\n\nتعداد اخطارهای کاربر : ('..tonumber(redis:hget('warn:'..chat_id, result.id_))..'/'..tonumber(redis:get('max_warn:'..chat_id) or 3)..')', 6, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],warn_name);end
if txt:match("^اخطار (%d+)$") then;local secure = tonumber(txt:match("^اخطار (%d+)$"));if secure == bot_id then;sendText(chat_id, msg.id_, 0, 1, nil, 'من نمیتوانم به خودم اخطار دهم!', 1, 'md');elseif is_mod2(secure, chat_id) then;sendText(chat_id, msg.id_, 0, 1, nil, 'شما نمیتوانید به ( مدیران , سازندگان ) ربات اخطار دهید!', 1, 'md');elseif tonumber(redis:hget('warn:'..chat_id, secure) or 1) == tonumber(redis:get('max_warn:'..chat_id) or 3) then;changeChatMemberStatus(chat_id, secure, 'Kicked');redis:hdel('warn:'..chat_id, secure, '0');SendMetion(chat_id, secure, msg.id_, 'کاربر '..secure..' از گروه اخراج شد\n\nتعداد اخطارهای کاربر مورد نظر از '..tonumber(redis:get('max_warn:'..chat_id) or 3)..' بیشتر شد', 6, utf8.len(secure));else;redis:hset('warn:'..chat_id, secure, tonumber(redis:hget('warn:'..chat_id, secure) or 0) + 1);SendMetion(chat_id, secure, msg.id_, 'کاربر '..secure..' اخطار گرفت!\n\nتعداد اخطارهای کاربر : ('..tonumber(redis:hget('warn:'..chat_id, secure))..'/'..tonumber(redis:get('max_warn:'..chat_id) or 3)..')', 6, utf8.len(secure));end;end
if txt:match("^حذف اخطار$") and tonumber(reply_id) > 0 then;function unwarn_user(extra, result, success);if not redis:hget('warn:'..chat_id, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص اخطاری دریافت نکرده است.', 1, 'md');else;redis:hdel('warn:'..chat_id, result.sender_user_id_, '0');SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› اخطار های کاربر '..result.sender_user_id_..' حذف شد.', 19, utf8.len(result.sender_user_id_));end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,unwarn_user);end
if txt:match("^حذف اخطار @(.*)$") then;local secure = {string.match(txt, "^(حذف اخطار) @(.*)$")};function unwarn_name(extra, result, success);if result.id_ then;if not redis:hget('warn:'..chat_id, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص اخطاری دریافت نکرده است.', 1, 'md');else;redis:hdel('warn:'..chat_id, result.id_, '0');SendMetion(chat_id, result.id_, msg.id_, '›› اخطار های کاربر '..result.id_..' حذف شد.', 19, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],unwarn_name);end
if txt:match("^حذف اخطار (%d+)$") then;local secure = tonumber(txt:match("^حذف اخطار (%d+)$"));if not redis:hget('warn:'..chat_id, secure) then;sendText(chat_id, msg.id_, 0, 1, nil,'این شخص اخطاری دریافت نکرده است.', 1, 'md');else;redis:hdel('warn:'..chat_id, secure, '0');SendMetion(chat_id, secure, msg.id_, '›› اخطار های کاربر '..secure..' حذف شد.', 19, utf8.len(secure));end;end
if txt:match("^وضعیت اخطار$") and tonumber(reply_id) > 0 then;function warnstats_user(extra, result, success);if not redis:hget('warn:'..chat_id, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این کاربر اخطاری دریافت نکرده است.', 1, 'md');else;SendMetion(chat_id, result.sender_user_id_, msg.id_, 'اخطار های کاربر '..result.sender_user_id_..' :\n\nتعداد اخطار : ('..tonumber(redis:hget('warn:'..chat_id, result.sender_user_id_))..'/'..tonumber(redis:get('max_warn:'..chat_id) or 3)..') ', 16, utf8.len(result.sender_user_id_));end;end;getMessage(msg.chat_id_, msg.reply_to_message_id_,warnstats_user);end
if txt:match("^وضعیت اخطار @(.*)$") then;local secure = {string.match(txt, "^(وضعیت اخطار) @(.*)$")};function unwarn_name(extra, result, success);if result.id_ then;if not redis:hget('warn:'..chat_id, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil,'این کاربر اخطاری دریافت نکرده است.', 1, 'md');else;SendMetion(chat_id, result.id_, msg.id_, 'اخطار های کاربر '..result.id_..' :\n\nتعداد اخطار : ('..tonumber(redis:hget('warn:'..chat_id, result.id_))..'/'..tonumber(redis:get('max_warn:'..chat_id) or 3)..') ', 16, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(secure[2],unwarn_name);end
if txt:match("^وضعیت اخطار (%d+)$") then;local secure = tonumber(txt:match("^وضعیت اخطار (%d+)$"));if not redis:hget('warn:'..chat_id, secure) then;sendText(chat_id, msg.id_, 0, 1, nil,'این کاربر اخطاری دریافت نکرده است.', 1, 'md');else;SendMetion(chat_id, secure, msg.id_, 'اخطار های کاربر '..secure..' :\n\nتعداد اخطار : ('..tonumber(redis:hget('warn:'..chat_id, secure))..'/'..tonumber(redis:get('max_warn:'..chat_id) or 3)..') ', 16, utf8.len(secure));end;end
if txt:match("^تنظیم اخطار (%d+)$") then;local maxwarn = {string.match(txt, "^(تنظیم اخطار) (%d+)$")};if tonumber(maxwarn[2]) < 1 or tonumber(maxwarn[2]) > 10 then;sendText(chat_id, msg.id_, 0, 1, nil, 'مقدار اخطار به کاربران باید بین (1-10) باشد!', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, 'حداکثر مقدار اخطار به کاربران تنظیم شد به : '..maxwarn[2]..'', 1, 'md');redis:set('max_warn:'..msg.chat_id_,maxwarn[2]);end;end
if txt:match("^پاکسازی لیست مسدودین$") then;redis:del('ban:'..chat_id);sendText(chat_id, msg.id_, 0, 1, nil, 'ليست مسدودین پاكسازی شد.', 1, 'md');end
if txt:match("^پاکسازی پیام ها$") then
if grouptype == "supergroup" then
tdcli.getChatHistory(chat_id, msg.id_,0 , 100, delmsg, {msgs=1})
local function delete_msgs_pro(arg,data)
local delall = data.members_
if not delall[0] then
return ''
else
for k, v in pairs(data.members_) do  
tdcli.deleteMessagesFromUser(msg.chat_id_, v.user_id_)
end
end
end
local function delete_msgs_proo(arg,data)
local delall = data.members_
if not delall[0] then
sendText(chat_id, msg.id_, 0, 1, nil, 'خطا !\n پیامی یافت نشد.', 1, 'md')
else
for k, v in pairs(data.members_) do  
tdcli.deleteMessagesFromUser(msg.chat_id_, v.user_id_)
end
sendText(chat_id, msg.id_, 0, 1, nil, 'تمام پیام های گروه با موفقیت پاک شدند.', 1, 'md')
end
end
tdcli_function ({
ID = "GetChannelMembers",
channel_id_ = getChatId(msg.chat_id_).ID,
filter_ = {
ID = "ChannelMembersRecent"
},
offset_ = 0,
limit_ = 10000
}, delete_msgs_pro, nil)
tdcli_function ({
ID = "GetChannelMembers",
channel_id_ = getChatId(msg.chat_id_).ID,
filter_ = {
ID = "ChannelMembersKicked"
},
offset_ = 0,
limit_ = 10000
}, delete_msgs_proo, nil)
tdcli.getChatHistory(chat_id, msg.id_,0 , 100, delmsg, {msgs=1})
else
sendText(chat_id, msg.id_, 0, 1, nil, 'خطا !\n فقط در سوپرگروه امکان پذیر است.', 1, 'md')
end
end
if txt:match("^حذف (%d+)$") then;local rm = tonumber(txt:match("^حذف (%d+)$"));if rm < 101 then;local function del_msg(extra, result, success);local message = result.messages_;for i=0 , #message do;tdcli.deleteMessages(msg.chat_id_,{[0] = message[i].id_});end;sendText(chat_id, msg.id_, 0, 1, nil, rm..' پیام اخیر گروه پاک شد !', 1, 'md');end;tdcli.getChatHistory(msg.chat_id_, 0, 0, tonumber(rm), del_msg, nil);else;sendText(chat_id, msg.id_, 0, 1, nil, 'عدد شما باید بین [*100-1*] باشد.', 1, 'md');end;end
if txt:match('^حذف$') then;if tonumber(msg.reply_to_message_id_) > 0 then;delete_msg(chat_id,{[0] = tonumber(msg.reply_to_message_id_),msg.id_});end;end
if txt:match("^تنظیم لینک ([https?://w]*.?telegram.me/joinchat/.*)$") or  txt:match("^تنظیم لینک ([https?://w]*.?t.me/joinchat/.*)$") then;local link = txt:match("^تنظیم لینک ([https?://w]*.?telegram.me/joinchat/.*)$") or  txt:match("^تنظیم لینک ([https?://w]*.?t.me/joinchat/.*)$");redis:set("link:"..chat_id, link);sendText(chat_id, msg.id_, 0, 1, nil, 'لینک گروه با موفقیت ثبت شد.', 1, 'md');end
if txt:match('^لینک$') then;local glink = redis:get("link:"..chat_id);if glink then;glinks = '\n\nلینک ورود به گروه :\n\n'..glink;else;glinks = '\n\nلینک گروه ثبت نشده است !\n\n شما میتوانید با دستور:\nتنظیم لینک x \nلینک گروه خود را تنظیم کنید.';end;function inline(arg,data);if data.inline_query_id_ then;tdcli_function({ID = "SendInlineQueryResultMessage",chat_id_ = msg.chat_id_,reply_to_message_id_ = msg.id_,disable_notification_ = 0,from_background_ = 1,query_id_ = data.inline_query_id_,result_id_ = data.results_[0].id_}, dl_cb, nil);else;sendText(chat_id, msg.id_, 0, 1, nil, 'خطا !\nنمیتوانم به ربات هلپر دسترسی پیدا کنم .'..glinks, 1, 'html');end;end;tdcli_function({ID = "GetInlineQueryResults",bot_user_id_ = 431954803,chat_id_ = msg.chat_id_,user_location_ = {ID = "Location",latitude_ = 0,longitude_ = 0},query_ = tostring(msg.chat_id_)..',link',offset_ = 0}, inline, nil);end
if txt:match("^پاکسازی لینک$") then;redis:del("link:"..chat_id);sendText(chat_id, msg.id_, 0, 1, nil, 'لینک گروه حذف شد.', 1, 'md');end
if txt:match("^تنظیم قوانین (.*)$") then;local rules = txt:match("^تنظیم قوانین (.*)$");redis:set("rules:"..chat_id, rules);sendText(chat_id, msg.id_, 0, 1, nil, 'قوانین گروه با موفقیت ثبت شد.', 1, 'md');end
if txt:match("^پاکسازی قوانین$") then;redis:del("rules:"..chat_id);sendText(chat_id, msg.id_, 0, 1, nil, 'قوانین گروه حذف شد.', 1, 'md');end
if txt:match("^تنظیم پیام ورودی (.*)$") then;local welcome = txt:match("^تنظیم پیام ورودی (.*)$");redis:set("wlc:"..chat_id, welcome);sendText(chat_id, msg.id_, 0, 1, nil, 'پیام ورودی ثبت شد.', 1, 'md');end
if txt:match("^حذف پیام ورودی$") then;redis:del("wlc:"..chat_id);sendText(chat_id, msg.id_, 0, 1, nil, 'پیام ورودی حذف شد.', 1, 'md');end
if txt:match("^تنظیم رگبار (%d+)$") then;local floodmax = {string.match(txt, "^(تنظیم رگبار) (%d+)$")};if tonumber(floodmax[2]) < 2 or tonumber(floodmax[2]) > 50 then;sendText(chat_id, msg.id_, 0, 1, nil, 'عددی بین 2-50 وارد کنید!', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, 'حساسیت تشخیص رگبار به '..floodmax[2]..' عدد تنظیم شد.', 1, 'md');redis:set('floodmax'..msg.chat_id_,floodmax[2]);end;end
if txt:match("^تنظیم کاراکتر (%d+)$") then;local sensspam = {string.match(txt, "^(تنظیم کاراکتر) (%d+)$")};if tonumber(sensspam[2]) < 40 or tonumber(sensspam[2]) > 4049 then;sendText(chat_id, msg.id_, 0, 1, nil, 'عددی بین 40-4049 وارد کنید!', 1, 'md');else;redis:set('cher'..msg.chat_id_,sensspam[2]);sendText(chat_id, msg.id_, 0, 1, nil, ' حساسیت پیام به '..sensspam[2]..' کاراکتر تنظیم شد !\nپیام هایی که بیش از '..sensspam[2]..' حرف داشته باشند ، حذف خواهند شد.', 1, 'md');end;end
if txt:match("^سنجاق کردن$") and msg.reply_to_message_id_ ~= 0 then;if not redis:get("lockpin"..chat_id) or redis:get("lockpin"..chat_id) and is_owner(msg) then;local id = msg.id_;local msgs = {[0] = id};tdcli.pinChannelMessage(msg.chat_id_,msg.reply_to_message_id_,0);sendText(chat_id, msg.reply_to_message_id_, 0, 1, nil,'اين پيام سنجاق شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil,'قفل سنجاق فعال است و شما اجازه دسترسی به سنجاق پیام را ندارید.', 1, 'md');end;end
if txt:match("^حذف سنجاق$") then;if not redis:get("lockpin"..chat_id) or redis:get("lockpin"..chat_id) and is_owner(msg) then;tdcli.unpinChannelMessage(msg.chat_id_);sendText(chat_id, msg.id_, 0, 1, nil,'پیام سنجاق شده پاک شد.', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil,'قفل سنجاق فعال است و شما اجازه دسترسی به حذف سنجاق پیام را ندارید.', 1, 'md');end;end
 end
if is_owner(msg) and not redis:get("gpname:"..chat_id) then;function gpn(extra, result, success);vardump(result);if result.title_ then;text = result.title_;redis:set("groupName:"..chat_id, text);end;end;getChat(chat_id, gpn);redis:setex("gpname:"..chat_id, 604800, true);end
if is_admin(msg) then
if txt:match("^تنظیم مالک$") and tonumber(reply_id) > 0 then;function setowner_reply(extra, result, success);if redis:sismember("owner:"..chat_id, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مالک بود.', 1, 'md');else;redis:sadd("owner:"..chat_id, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' مالک گروه شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(chat_id,msg.reply_to_message_id_,setowner_reply,nil);end
if txt:match("^تنظیم مالک @(.*)$") then;function setowner_username(extra, result, success);if result.id_ then;if redis:sismember('owner:'..chat_id, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مالک بود.', 1, 'md');else;redis:sadd("owner:"..chat_id, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' مالک گروه شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^تنظیم مالک @(.*)$"),setowner_username);end
if txt:match("^تنظیم مالک (%d+)$") then;if redis:sismember('owner:'..chat_id, txt:match("^تنظیم مالک (%d+)$")) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مالک بود.', 1, 'md');else;redis:sadd('owner:'..chat_id, txt:match("^تنظیم مالک (%d+)$"));SendMetion(chat_id, txt:match("^تنظیم مالک (%d+)$"), msg.id_, '›› کاربر '..txt:match("^تنظیم مالک (%d+)$")..' مالک گروه شد.', 9, utf8.len(txt:match("^تنظیم مالک (%d+)$")));end;end
if txt:match("^حذف مالک$") and tonumber(reply_id) > 0 then;function remowner_reply(extra, result, success);if not redis:sismember("owner:"..chat_id, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص مالک نبود.', 1, 'md');else;redis:srem("owner:"..chat_id, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از مالكيت گروه بركنار شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(chat_id,msg.reply_to_message_id_,remowner_reply,nil);end
if txt:match("^حذف مالک @(.*)$") then;function remowner_username(extra, result, success);if result.id_ then;if not redis:sismember('owner:'..chat_id, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص مالک نبود.', 1, 'md');else;redis:srem('owner:'..chat_id, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از مالكيت گروه بركنار شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^حذف مالک @(.*)$"),remowner_username);end
if txt:match("^حذف مالک (%d+)$") then;if not redis:sismember('owner:'..chat_id, txt:match("^حذف مالک (%d+)$")) then;sendText(chat_id, msg.id_, 0, 1, nil, 'این شخص مالک نبود.', 1, 'md');else;redis:srem('owner:'..chat_id, txt:match("^حذف مالک (%d+)$"));SendMetion(chat_id, txt:match("^حذف مالک (%d+)$"), msg.id_, '›› کاربر '..txt:match("^حذف مالک (%d+)$")..' از مالكيت گروه بركنار شد.', 9, utf8.len(txt:match("^حذف مالک (%d+)$")));end;end
if txt:match("^پاکسازی لیست مالکین$") then;redis:del('owner:'..chat_id);sendText(chat_id, msg.id_, 0, 1, nil, 'ليست مالکین گروه پاكسازی شد.', 1, 'md');end
end
if is_owner(msg) then
if txt:match("^ترفیع$") and tonumber(reply_id) > 0 then;function setmod_reply(extra, result, success);if redis:sismember("mod:"..chat_id, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مدير است.', 1, 'md');else;redis:sadd("mod:"..chat_id, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' مدیر شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(chat_id,msg.reply_to_message_id_,setmod_reply,nil);end
if txt:match("^ترفیع @(.*)$") then;function setmod_username(extra, result, success);if result.id_ then;if redis:sismember('mod:'..chat_id, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مدير است.', 1, 'md');else;redis:sadd("mod:"..chat_id, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' مدیر شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^ترفیع @(.*)$"),setmod_username);end
if txt:match("^ترفیع (%d+)$") then;if redis:sismember('mod:'..chat_id, txt:match("^ترفیع (%d+)$")) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مدير است.', 1, 'md');else;redis:sadd('mod:'..chat_id, txt:match("^ترفیع (%d+)$"));SendMetion(chat_id, txt:match("^ترفیع (%d+)$"), msg.id_, '›› کاربر '..txt:match("^ترفیع (%d+)$")..' مدیر شد.', 9, utf8.len(txt:match("^ترفیع (%d+)$")));end;end
if txt:match("^لیست مالکین$") then;local text = "لیست مالکین گروه : \n====\n";for k,v in pairs(redis:smembers('owner:'..chat_id)) do;text = text.."*"..k.."* - `"..v.."`\n";end;sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md');end
if txt:match("^عزل$") and tonumber(reply_id) > 0 then;function remmod_reply(extra, result, success);if not redis:sismember("mod:"..chat_id, result.sender_user_id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مدير نيست.', 1, 'md');else;redis:srem("mod:"..chat_id, result.sender_user_id_);SendMetion(chat_id, result.sender_user_id_, msg.id_, '›› کاربر '..result.sender_user_id_..' از مديريت بركنار شد.', 9, utf8.len(result.sender_user_id_));end;end;getMessage(chat_id,msg.reply_to_message_id_,remmod_reply,nil);end
if txt:match("^عزل @(.*)$") then;function remmod_username(extra, result, success);if result.id_ then;if not redis:sismember('mod:'..chat_id, result.id_) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مدير نيست.', 1, 'md');else;redis:srem('mod:'..chat_id, result.id_);SendMetion(chat_id, result.id_, msg.id_, '›› کاربر '..result.id_..' از مديريت بركنار شد.', 9, utf8.len(result.id_));end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^عزل @(.*)$"),remmod_username);end
if txt:match("^عزل (%d+)$") then;if not redis:sismember('mod:'..chat_id, txt:match("^عزل (%d+)$")) then;sendText(chat_id, msg.id_, 0, 1, nil, 'اين شخص مدير نيست.', 1, 'md');else;redis:srem('mod:'..chat_id, txt:match("^عزل (%d+)$"));SendMetion(chat_id, txt:match("^عزل (%d+)$"), msg.id_, '›› کاربر '..txt:match("^عزل (%d+)$")..' از مديريت بركنار شد.', 9, utf8.len(txt:match("^عزل (%d+)$")));end;end
if txt:match("^لیست مدیران$") then;local text = "لیست دستياران مالک گروه : \n====\n";for k,v in pairs(redis:smembers('mod:'..chat_id)) do;text = text.."*"..k.."* - `"..v.."`\n";end;sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md');end
if txt:match("^پاکسازی لیست مدیران$") then;redis:del('mod:'..chat_id);sendText(chat_id, msg.id_, 0, 1, nil, 'تمامی مديران از مقام مدیریت عزل شدند.', 1, 'md');end
if txt:match('^ترفیع کلی$') then;local function promote_admin(extra, result, success);local num = 0;local num2 = 0;local admins = result.members_;for i=0 , #admins do;num = num + 1;if redis:sismember("mod:"..chat_id, admins[i].user_id_) then;else;redis:sadd("mod:"..chat_id, admins[i].user_id_);num2 = num2 + 1;end;if result.members_[i].status_.ID == "ChatMemberStatusCreator" then;owner_id = admins[i].user_id_;if  redis:sismember('owner:'..chat_id, owner_id) then;else;redis:sadd('owner:'..chat_id, owner_id);end;end;end;sendText(chat_id, msg.id_, 0, 1, nil,'سازنده گروه به عنوان مالک ربات تنظیم شد.\n\n تعداد ادمین : '..num..'\n\nتعداد '..num2..' نفر مدیر شدند.\n\nتعداد '..num - num2..' نفر از ادمین ها، از قبل مدیر بودند.', 1, 'md');end;tdcli.getChannelMembers(chat_id, 'Administrators', 0, 100, promote_admin, nil);end
if txt:match('^پاکسازی ربات ها$') then;local function cb(extra,result,success);local bots = result.members_;if tonumber(result.total_count_) == 0 then ;sendText(chat_id, msg.id_, 0, 1, nil,'در گروه رباتی وجود ندارد!', 1, 'md');else;num=0;for i=0 ,#bots do;changeChatMemberStatus(chat_id, bots[i].user_id_, 'Kicked');num=num+1;end;sendText(chat_id, msg.id_, 0, 1, nil,num..' ربات از گروه اخراج شد.', 1, 'md');end;end;tdcli.getChannelMembers(chat_id, 'Bots', 0, 200, cb, nil);end
if txt:match('^پاکسازی لیست بلاک$') then;local function removeblocklist(extra, result);if tonumber(result.total_count_) == 0 then ;sendText(chat_id, msg.id_, 0, 1, nil,'لیست بلاک گروه شما خالی میباشد!', 1, 'md');else;local x = 0;local num = 0;for x,y in pairs(result.members_) do;x = x + 1;changeChatMemberStatus(msg.chat_id_, y.user_id_, 'Left', dl_cb, nil);num = num + 1;end;sendText(chat_id, msg.id_, 0, 1, nil,num..' کاربر از لیست بلاک آزاد شد.', 1, 'md');end;end;tdcli.getChannelMembers(chat_id, 'Kicked', 0, 200, removeblocklist, nil);end
if txt:match('^پاکسازی کاربران پاک شده$') then;local function deleteaccounts(extra, result);for k,v in pairs(result.members_) do ;local function cleanaccounts(extra, result);if not result.first_name_ then;changeChatMemberStatus(msg.chat_id_, result.id_, "Kicked");end;end;tdcli.getUser(v.user_id_, cleanaccounts, nil);end;sendText(chat_id, msg.id_, 0, 1, nil,'کاربران حذف اکانت شده اخراج شدند.', 1, 'md');end;tdcli_function ({ID = "GetChannelMembers",channel_id_ = getChatId(msg.chat_id_).ID,offset_ = 0,limit_ = 1000}, deleteaccounts, nil);end
end
if redis:get("lc_ato:"..msg.chat_id_) and not is_mod(msg) then;return false;end
if txt:match('^آیدی$') and reply_id == 0 then;local function profile(extra, result, success);if result.photos_[0] then;sendPhoto(chat_id, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_, '› آيدی گروه : '..chat_id..'\n› آیدی شما : '..user_id);else;sendText(chat_id, msg.id_, 0, 1, nil, '_‌‌شما عكس پروفايل نداريد _!\n\n*›* آيدی گروه : *'..chat_id..'*\n*›* آیدی شما : *'..user_id..'*', 1, 'md');end;end;getUserProfilePhotos(user_id, 0, 1, profile, nil);end
if txt:match('^آیدی$') and reply_id then;function id_reply(extra, result, success);if result.forward_info_ then;text = '› آیدی کاربر فوروارد شده : '..result.forward_info_.sender_user_id_..'';else;text = '';end;SendMetion(chat_id, result.sender_user_id_, msg.id_, '› آیدی کاربر : '..result.sender_user_id_..'\n› آیدی پیام : '..result.id_..'\n'..text, 15, utf8.len(result.sender_user_id_));end;getMessage(chat_id,msg.reply_to_message_id_,id_reply,nil);end
if txt:match("^آیدی @(.*)$")  then;function id_username(extra, result, success);if result.id_ then;sendText(chat_id, msg.id_, 0, 1, nil, '*›* آیدی کاربر : '..result.id_..'', 1, 'md');else;sendText(chat_id, msg.id_, 0, 1, nil, 'كاربر يافت نشد!', 1, 'md');end;end;searchPublicChat(txt:match("^آیدی @(.*)$"),id_username);end
if txt:match("^آیدی (.*)$") and msg.content_.entities_[0].user_id_ then;if not txt:find('@') and not txt:find('(%d+)$') then;function check_mention(extra, secure, success);vardump(secure);if secure.content_.entities_[0].user_id_ then;sendText(chat_id, msg.id_, 0, 1, nil, "<b>›</b> آیدی کاربر : "..secure.content_.entities_[0].user_id_.."", 1, 'html');end;end;getMessage(msg.chat_id_, msg.id_, check_mention);end;end
if txt:match('^ربات$') then;if redis:get("rank:"..user_id) then;r = redis:get("rank:"..user_id);else ;r = '';end;local ra = {"جونز "..r,"جانم "..r,"ژوون "..r," چیه همش صدام میکنی "..r.."😐","چه عجب "..r,"هان؟ "..r,"اذیتم نکن همش 🙁😭 "..r};sendText(chat_id, msg.id_, 0, 1, nil, ra[math.random(#ra)], 1, 'md');end  
if txt:match('^بای$')  then;if redis:get("rank:"..user_id) then;r = redis:get("rank:"..user_id);else ;r = '';end;sendText(chat_id, msg.id_, 0, 1, nil, '🍃فعلا '..r, 1, 'md');end
if txt:match('^مقام من$') then;if is_sudo(msg) then;sendText(chat_id, msg.id_, 0, 1, nil, '`سازنده ربات`', 1, 'md');tdcli.sendSticker(msg.chat_id_, msg.id_, 0, 1, nil, 'CAADBAADpwADlwAB1BESqbAlm5knngI');elseif is_admin(msg) then;sendText(chat_id, msg.id_, 0, 1, nil, '_ادمین مدیریتی ربات_', 1, 'md');tdcli.sendSticker(msg.chat_id_, msg.id_, 0, 1, nil, 'CAADBAADowADlwAB1BEy9Tt7Q7w-FQI');elseif is_owner(msg) then;sendText(chat_id, msg.id_, 0, 1, nil, '_مالک گروه_', 1, 'md');tdcli.sendSticker(msg.chat_id_, msg.id_, 0, 1, nil, 'CAADBAADpgADlwAB1BHNjO5S9JBJ2gI');elseif is_mod(msg) then;sendText(chat_id, msg.id_, 0, 1, nil, '_مدیر گروه_', 1, 'md');tdcli.sendSticker(msg.chat_id_, msg.id_, 0, 1, nil, 'CAADBAADpQADlwAB1BEaejoS2hlWZQI');else;sendText(chat_id, msg.id_, 0, 1, nil, '_فرد عادی_', 1, 'md');tdcli.sendSticker(msg.chat_id_, msg.id_, 0, 1, nil, 'CAADBAADpAADlwAB1BGixkKhl1LNvQI');end;end
if txt:match("^قوانین$")  then;local grules = redis:get("rules:"..chat_id);if grules then;sendText(chat_id, msg.id_, 0, 1, nil, 'قوانین گروه : \n'..grules, 1, 'html');else;sendText(chat_id, msg.id_, 0, 1, nil, 'قوانین گروه ثبت نشده', 1, 'md');end;end
if txt:match('^اطلاعات (%d+)') then;local id = tonumber(txt:match('اطلاعات (%d+)'));text = "برای مشاهده اطلاعات کاربر کلیک کنید.";local function whois(extra, result, success);if result.first_name_ then;tdcli_function ({ID="SendMessage", chat_id_=msg.chat_id_, reply_to_message_id_=msg.id_, disable_notification_=0, from_background_=1, reply_markup_=nil, input_message_content_={ID="InputMessageText", text_=text, disable_web_page_preview_=1, clear_draft_=0, entities_={[0] = {ID="MessageEntityMentionName", offset_=0, length_=36, user_id_=id}}}}, dl_cb, nil);else;sendText(chat_id, msg.id_, 0, 1, nil, 'اطلاعات این کاربر در سیستم ثبت نشده است.', 1, 'md');end;end;tdcli.getUser(id, whois, nil);end
if txt:match("^پروفایل من (%d+)") then;local pro = tonumber(txt:match("^پروفایل من (%d+)"));local function myprofile(extra, result, success);if result.total_count_ == 0 then;sendText(chat_id, msg.id_, 0, 1, nil,'شما هیچ عکس پروفایلی ندارید!', 1, 'md');else;if result.total_count_ >= pro then;if result.photos_[0] then;sendPhoto(chat_id, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_, 'عکس شماره : ['..pro..'/'..result.total_count_..']\n سایز تصویر : '..result.photos_[0].sizes_[1].photo_.size_..' پیکسل');end;else;sendText(chat_id, msg.id_, 0, 1, nil, 'شما `'..pro..'` عکس پروفایل ندارید !\n\n*›* تعداد عکس‌های شما : `'..result.total_count_..'`', 1, 'md');end;end;end;getUserProfilePhotos(user_id, pro-1, 1000, myprofile, nil);end
if txt:match('^شماره ربات$') then;tdcli.sendContact(chat_id, msg.id_, 0, 1, nil, 79772718830, 'Secure', 'TG', bot_id);end
if (txt:match("^(وضعیت)$") and not msg.forward_info_)then;return tdcli_function({ID = "ForwardMessages",chat_id_ = msg.chat_id_,from_chat_id_ = msg.chat_id_,message_ids_ = {[0] = msg.id_},disable_notification_ = 0,from_background_ = 1}, dl_cb, nil);end
if txt:match("^نرخ$") then;sendText(chat_id, msg.id_, 0, 1, nil, nerkh, 1, 'html');end
if txt:match("^[Ss][Ee][Cc][Uu][Rr][Ee]$") or txt:match("^سیکیور$") then;local SecureText = [[ربات آنتی اسپم <b>Secure</b> :

سورس این ربات بر پایه tdcli نوشته شده است

سورس این ربات تک فایل میباشد و دارای قدرت و سرعت بسیار بالا میباشد و یکی از بهترین ربات های ضد لینک به شمار میاید.

توسعه دهنده و صاحب امتیاز این ربات :
« @Secure_Dev »

کانال ارتباطی ما :
https://t.me/Secure_Tm
]];sendText(chat_id, msg.id_, 0, 1, nil, SecureText, 1, 'html');end
if txt:match("^ساپورت$") then;sendText(chat_id, msg.id_, 0, 1, nil, '<b>›</b> لینک ورود به گروه پشتیبانی :\n\nhttps://t.me/joinchat/DE6jKEHsNosxJU_lDjR_5w', 1, 'html');end
end
end
end
elseif (data.ID == "UpdateMessageEdited") then
local msg = data
local function edited_cb(extra,result,success)
local txt = (result.content_.text_ or result.content_.caption_)
if not is_mod2(result.sender_user_id_, result.chat_id_) then
local is_link_msg = txt:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") or txt:match("[Tt].[Mm][Ee]/") or result.content_.entities_ and result.content_.entities_[0] and result.content_.entities_[0].ID == "MessageEntityUrl" or result.content_.entities_ and result.content_.entities_[0] and result.content_.entities_[0].ID == "MessageEntityTextUrl"
if is_link_msg and redis:get("locklink"..result.chat_id_) then
local msgs = {[0] = data.message_id_}
delete_msg(data.chat_id_, msgs)
end
local is_tag = txt:match("#") or txt:match("@") or result.content_.entities_ and result.content_.entities_[0] and result.content_.entities_[0].ID == "MessageEntityMentionName"
if is_tag  and redis:get("locktag"..result.chat_id_) then
local msgs = {[0] = data.message_id_}
delete_msg(data.chat_id_, msgs)
end
if redis:get("lockedit"..result.chat_id_) then
local msgs = {[0] = data.message_id_}
delete_msg(data.chat_id_, msgs)
end
local is_farsi = txt:match("[\216-\219][\128-\191]")
if is_farsi and redis:get("lockfarsi"..result.chat_id_) then
local msgs = {[0] = data.message_id_}
delete_msg(data.chat_id_, msgs)
end
local is_eng = txt:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]")
if is_eng and redis:get("lockenglish"..result.chat_id_) then
local msgs = {[0] = data.message_id_}
delete_msg(data.chat_id_, msgs)
end
end
end
tdcli_function ({
ID = "GetMessage",
chat_id_ = data.chat_id_,
message_id_ = data.message_id_
}, edited_cb, nil)
elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
tdcli_function ({
ID="GetChats",
offset_order_="9223372036854775807",
offset_chat_id_=0,
limit_=20
}, dl_cb, nil)
end
end