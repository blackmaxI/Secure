local URL = require "socket.url"
local https = require "ssl.https"
local serpent = require "serpent"
local json = (loadfile "/home/Secure/secure/libs/JSON.lua")()
local token = '431954803:AAFEgCMHYieLQD3VoPKA0J28Z_cjVVhbTR0' 
local url = 'https://api.telegram.org/bot' .. token
local offset = 0
local redis = require('redis')
local redis = redis.connect('127.0.0.1', 6379)
local SUDO = 206480168
function is_mod(chat,user)
sudo = {206480168}
  local var = false
  for v,_user in pairs(sudo) do
    if _user == user then
      var = true
    end
  end
 local hash = redis:sismember('botadmin:',user)
 if hash then
 var = true
 end
 local hash2 = redis:sismember('owner:'..chat,user)
 if hash2 then
 var = true
 end
 local hash3 = redis:sismember('mod:'..chat,user)
 if hash3 then
 var = true
 end
 return var
 end
 function is_owner(chat,user)
sudo = {206480168}
  local var = false
  for v,_user in pairs(sudo) do
    if _user == user then
      var = true
    end
  end
 local hash = redis:sismember('botadmin:',user)
 if hash then
 var = true
 end
 local hash2 = redis:sismember('owner:'..chat,user)
 if hash2 then
 var = true
 end
 return var
 end
local function getUpdates()
  local response = {}
  local success, code, headers, status  = https.request{
    url = url .. '/getUpdates?timeout=20&limit=1&offset=' .. offset,
    method = "POST",
    sink = ltn12.sink.table(response),
  }

  local body = table.concat(response or {"no response"})
  if (success == 1) then
    return json:decode(body)
  else
    return nil, "Request Error"
  end
end

function vardump(value)
  print(serpent.block(value, {comment=false}))
end

function sendmsg(chat,text,keyboard)
if keyboard then
urlk = url .. '/sendMessage?chat_id=' ..chat.. '&text='..URL.escape(text)..'&parse_mode=html&reply_markup='..URL.escape(json:encode(keyboard))
else
urlk = url .. '/sendMessage?chat_id=' ..chat.. '&text=' ..URL.escape(text)..'&parse_mode=html'
end
https.request(urlk)
end
 function edit( message_id, text, keyboard, hm)
  local urlk = url .. '/editMessageText?&inline_message_id='..message_id..'&text=' .. URL.escape(text)
    urlk = urlk .. '&parse_mode='..hm
  if keyboard then
    urlk = urlk..'&reply_markup='..URL.escape(json:encode(keyboard))
  end
    return https.request(urlk)
  end
function Canswer(callback_query_id, text, show_alert)
	local urlk = url .. '/answerCallbackQuery?callback_query_id=' .. callback_query_id .. '&text=' .. URL.escape(text)
	if show_alert then
		urlk = urlk..'&show_alert=true'
	end
  https.request(urlk)
	end
  function answer(inline_query_id, query_id , title , description , text , keyboard)
  local results = {{}}
         results[1].id = query_id
         results[1].type = 'article'
         results[1].description = description
         results[1].title = title
         results[1].message_text = text
  urlk = url .. '/answerInlineQuery?inline_query_id=' .. inline_query_id ..'&results=' .. URL.escape(json:encode(results))..'&parse_mode=Markdown&cache_time=' .. 1
  if keyboard then
   results[1].reply_markup = keyboard
  urlk = url .. '/answerInlineQuery?inline_query_id=' .. inline_query_id ..'&results=' .. URL.escape(json:encode(results))..'&parse_mode=Markdown&cache_time=' .. 1
  end
    https.request(urlk)
  end
function fwd(chat_id, from_chat_id, message_id)
  local urlk = url.. '/forwardMessage?chat_id=' .. chat_id .. '&from_chat_id=' .. from_chat_id .. '&message_id=' .. message_id
  local res, code, desc = https.request(urlk)
  if not res and code then 
  end
  return res, code
end
function sleep(n) 
os.execute("sleep " .. tonumber(n)) 
end
local day = 86400
local function run()
  while true do
    local updates = getUpdates()
    vardump(updates)
    if(updates) then
      if (updates.result) then
        for i=1, #updates.result do
          local msg = updates.result[i]
          offset = msg.update_id + 1
          if msg.inline_query then
            local q = msg.inline_query
						if q.from.id == 493766156 or q.from.id == 206480168 then
            if q.query:match("^-(%d+,setting)") then
						local chat = "-" .. q.query:match("(%d+)")
              local keyboard = {}
							keyboard.inline_keyboard = {
							{
							{text = '≡ تنظیمات ≡', callback_data = 'Setting'..chat}
							},{
							{text = '≡ عملیات مدیریتی ≡', callback_data = 'GPinfo'..chat}
							},{
							{text = '≡ پشتیبانی ≡', callback_data = 'Support'..chat}
							},{
				{text = '● بستن پنل مدیریتی', callback_data = 'Exit'..chat}
}
}
            answer(q.id,'secure','ارسال پنل مدیریتی گروه :',chat,'به پنل مديريتی ربات Secure خوش آمديد!\nاز منو زیر انتخاب کنید:\nکانال ما : @Secure_Tm',keyboard)
            end
			if q.query:match("^-(%d+,link)") then
						local chat = "-" .. q.query:match("(%d+)")
				 local keyboard = {}
							keyboard.inline_keyboard = {
							{
							{text = '● دریافت لینک', callback_data = 'Gplink'..chat}
							}
							}
						answer(q.id,'secure','ارسال لینک :',chat,"برای دریافت لینک گروه بر روی گزینه 'دریافت لینک' کلیک کنید",keyboard)
						end
            end
						end
          if msg.callback_query then
            local q = msg.callback_query
			local chat = ('-'..q.data:match('(%d+)') or '')
						if is_mod(chat,q.from.id) then
						if q.data:match('Gplink') then
						local chat = '-'..q.data:match('(%d+)$')
								local linkss = redis:get('link:'..chat) 
						if linkss then
          linkGroup = "لینک ورود به گروه :\n\n[برای ورود به گروه روی متن  کلیک کنید]("..linkss..")"
		  else
		  linkGroup = 'لینک گروه ثبت نشده است !\n\n شما میتوانید با دستور:\nتنظیم لینک x \nلینک گروه خود را تنظیم کنید.'
          end
		  edit(q.inline_message_id, linkGroup, nil, 'Markdown')
						end
													if q.data:match('Firstmenu') then
							local chat = '-'..q.data:match('(%d+)$')
              local keyboard = {}
							keyboard.inline_keyboard = {
									{
							{text = '≡ تنظیمات ≡', callback_data = 'Setting'..chat}
							},{
							{text = '≡ عملیات مدیریتی ≡', callback_data = 'GPinfo'..chat}
							},{
							{text = ' ≡پشتیبانی ≡', callback_data = 'Support'..chat}
							},{
				{text = '● بستن پنل مدیریتی', callback_data = 'Exit'..chat}
}
							}
            edit(q.inline_message_id,'به پنل مديريتی ربات Secure خوش آمديد!\nاز منو زیر انتخاب کنید:',keyboard, 'html')
            end
            if q.data:match('Exit') then
		local keyboard = {}
		 edit(q.inline_message_id, "-| پنل مدیریتی با موفقیت بسته شد.", nil, 'html')
		 Canswer(q.id,'پنل مدیریتی درخواست شده توسط شما با موفقیت بسته شد .',true)
			end
		if q.data:match('Support') then
		local chat = '-'..q.data:match('(%d+)$')
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
		{text = 'گروه پشتیبانی', url = 'https://t.me/joinchat/DE6jKEHsNosxJU_lDjR_5w'}
		},{
		{text = 'ربات ارتباطی', url = 'https://telegram.me/SecureSupportBot'}
		},{
		{text = 'کانال رسمی ما', url = 'https://telegram.me/Secure_Tm'}
		},{
                   {text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "به بخش پشتیبانی ربات Secure خوش امدید.\n\nاز منوی زیر انتخاب کنید :", keyboard, 'html')
			end
			if q.data:match('GPinfo') then
			local chat = '-'..q.data:match('(%d+)$')
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
		{text = 'لینک', callback_data = 'Link'..chat}
		},{
		{text = 'لیست مدیران', callback_data = 'Modlist'..chat},{text = 'لیست مسدودین', callback_data = 'Banlist'..chat}
		},{
		{text = 'لیست سکوت', callback_data = 'Silentlist'..chat},{text = 'لیست فیلتر', callback_data = 'Filterlist'..chat}
		},{
		{text = 'پیام ورودی', callback_data = 'Welcome'..chat},{text = 'قوانین', callback_data = 'Rules'..chat}
		},{
		{text = 'اعتبار گروه', callback_data = 'Expire'..chat}
		},{
                   {text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "به بخش عملیات مدیریتی خوش امدید.\n\nاز منوی زیر انتخاب کنید :", keyboard, 'html')
			end
			if q.data:match('Link') then
			local chat = '-'..q.data:match('(%d+)$')
			local link = redis:get('link:'..chat) 
			if link then
			links = "لینک ورود به گروه :\n\n"..link..""
			else
		  links = 'لینک گروه ثبت نشده است !\n\n شما میتوانید با دستور:\nتنظیم لینک x \nلینک گروه خود را تنظیم کنید.'
          end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
										{text = 'پاکسازی لینک', callback_data = 'Dellink'..chat}
				   },{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, links, keyboard, 'html')
			end
			if q.data:match('Dellink') then
			 local chat = '-'..q.data:match('(%d+)$')
			 redis:del('link:'..chat)
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
                   {text = '«', callback_data = 'Link'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "لینک گروه با موفقیت پاکسازی شد.", keyboard, 'html')
		 Canswer(q.id,'درخواست شما انجام شد\nلینک گروه با موفقیت بازنشانی شد.',true)
			end
			if q.data:match('Rules') then
			local chat = '-'..q.data:match('(%d+)$')
			local rs = redis:get('rules:'..chat) 
			if rs then
          Rules = "قوانین گروه عبارتند از :\n"..rs
		  else
		  Rules = 'قوانین گروه ثبت نشده است !\n\n شما میتوانید با دستور:\nتنظیم قوانین x \nقوانین گروه خود را تنظیم کنید.'
          end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
										{text = 'پاکسازی قوانین', callback_data = 'Delrules'..chat}
				   },{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, Rules, keyboard, 'html')
			end
			if q.data:match('Delrules') then
			 local chat = '-'..q.data:match('(%d+)$')
			 redis:del('rules:'..chat)
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
                   {text = '«', callback_data = 'Rules'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "قوانین گروه با موفقیت پاکسازی شد.", keyboard, 'html')
		 Canswer(q.id,'درخواست شما انجام شد\n قوانین گروه با موفقیت بازنشانی شد.',true)
			end
			if q.data:match('Welcome') then
			local chat = '-'..q.data:match('(%d+)$')
			local rs = redis:get('wlc:'..chat) 
			if rs then
          welcome = "پیام ورودی گروه عبارتند از :\n"..rs
		  else
		  welcome = 'پیام ورودی گروه ثبت نشده است !\n\n شما میتوانید با دستور:\nتنظیم پیام ورودی x \nپیام ورودی گروه خود را تنظیم کنید.'
          end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
										{text = 'پاکسازی پیام ورودی', callback_data = 'Delwelcome'..chat}
				   },{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, welcome, keyboard, 'html')
			end
			if q.data:match('Delwelcome') then
			 local chat = '-'..q.data:match('(%d+)$')
			 redis:del('wlc:'..chat)
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
                   {text = '«', callback_data = 'Welcome'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "پیام ورودی گروه با موفقیت پاکسازی شد.", keyboard, 'html')
		 Canswer(q.id,'درخواست شما انجام شد\n پیام ورودی گروه با موفقیت بازنشانی شد.',true)
			end
			if q.data:match('Modlist') then
			local chat = '-'..q.data:match('(%d+)$')
			local mod = redis:smembers('mod:'..chat) 

			local mods = "لیست دستياران مالک گروه : \n\n"
for k,v in pairs(mod) do
mods = mods..""..k.." - "..v.."\n"
end
if #mod == 0 then
		  mods = 'لیست مدیران گروه خالی میباشد!\n\nمدیری برای گروه انتخاب نشده است.'
          end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
										{text = 'پاکسازی لیست مدیران', callback_data = 'Delmods'..chat}
				   },{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, mods, keyboard, 'html')
			end
			if q.data:match('Delmods') then
			 local chat = '-'..q.data:match('(%d+)$')
			 if is_owner(chat,q.from.id) then
			 redis:del('mod:'..chat)
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
                   {text = '«', callback_data = 'Modlist'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "لیست مدیران گروه با موفقیت پاکسازی شد.", keyboard, 'html')
		 Canswer(q.id,'درخواست شما انجام شد\n لیست مدیران گروه با موفقیت بازنشانی شد.',true)
		 	else Canswer(q.id,'شما دسترسی ندارید',true)
						end
			end
			if q.data:match('Banlist') then
			local chat = '-'..q.data:match('(%d+)$')
			local ban = redis:smembers('ban:'..chat) 

			local bans = "لیست مسدودین گروه : \n\n"
for k,v in pairs(ban) do
bans = bans..""..k.." - "..v.."\n"
end
if #ban == 0 then
		  bans = 'لیست مسدودین گروه خالی میباشد!\n\nکاربری از گروه محروم نشده است.'
          end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
										{text = 'پاکسازی لیست مسدودین', callback_data = 'Delbans'..chat}
				   },{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, bans, keyboard, 'html')
			end
			if q.data:match('Delbans') then
			 local chat = '-'..q.data:match('(%d+)$')
			 redis:del('ban:'..chat)
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
                   {text = '«', callback_data = 'Banlist'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "لیست مسدودین گروه با موفقیت پاکسازی شد.", keyboard, 'html')
		 Canswer(q.id,'درخواست شما انجام شد\n لیست مسدودین گروه با موفقیت بازنشانی شد.',true)
			end
			if q.data:match('Silentlist') then
			local chat = '-'..q.data:match('(%d+)$')
			local muted = redis:smembers('muted:'..chat) 

			local mutes = "لیست سکوت گروه : \n\n"
for k,v in pairs(muted) do
mutes = mutes..""..k.." - "..v.."\n"
end
if #muted == 0 then
		  mutes = 'لیست سکوت گروه خالی میباشد!\n\nکاربری در گروه ساکت نشده است.'
          end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
										{text = 'پاکسازی لیست سکوت', callback_data = 'Delmute'..chat}
				   },{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, mutes, keyboard, 'html')
			end
			if q.data:match('Delmute') then
			 local chat = '-'..q.data:match('(%d+)$')
			 redis:del('muted:'..chat)
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
                   {text = '«', callback_data = 'Silentlist'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "لیست سکوت گروه با موفقیت پاکسازی شد.", keyboard, 'html')
		 Canswer(q.id,'درخواست شما انجام شد\n لیست سکوت گروه با موفقیت بازنشانی شد.',true)
			end
			if q.data:match('Filterlist') then
			local chat = '-'..q.data:match('(%d+)$')
			local filters = redis:smembers('filters:'..chat) 

			local filter = "لیست کلمات فیلتر شده در گروه : \n\n"
for k,v in pairs(filters) do
filter = filter..""..k.." - "..v.."\n"
end
if #filters == 0 then
		  filter = 'لیست فیلتر گروه خالی میباشد!\n\n کلمه ای در گروه فیلتر نشده است.'
          end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
										{text = 'پاکسازی لیست فیلتر', callback_data = 'Delfilter'..chat}
				   },{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, filter, keyboard, 'html')
			end
			if q.data:match('Delfilter') then
			 local chat = '-'..q.data:match('(%d+)$')
			 redis:del('filters:'..chat)
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
                   {text = '«', callback_data = 'Filterlist'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "لیست فیلتر گروه با موفقیت پاکسازی شد.", keyboard, 'html')
		 Canswer(q.id,'درخواست شما انجام شد\n لیست فیلتر گروه با موفقیت بازنشانی شد.',true)
			end
			if q.data:match('Expire') then
			local chat = '-'..q.data:match('(%d+)$')
	local ex = redis:ttl("chargeg:"..chat)
	       if ex == -1 then
		 expire = 'مدت زمان گروه شما نامحدود میباشد.'
       else
	   local expir = math.floor(ex/86400) + 1
			expire = '['..expir..'] روز تا پایان مدت زمان انقضا گروه باقی مانده است.'
       end
		local keyboard = {}
		keyboard.inline_keyboard = {
{
                   {text = '«', callback_data = 'GPinfo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, expire, keyboard, 'html')
			end
			if q.data:match('TGSecure') then
		 Canswer(q.id,'این دکمه جنبه نمایشی دارد !')
			end
					if q.data:match('Locklink') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("locklink"..chat) then
			redis:del("locklink"..chat)
			result = 'قفل لینک غیرفعال شد.'
			else
			  redis:set("locklink"..chat, true)
			result = 'قفل لینک فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Lockchat') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockchat"..chat) then
			redis:del("lockchat"..chat)
			result = 'قفل چت غیرفعال شد.'
			else
			  redis:set("lockchat"..chat, true)
			result = 'قفل چت فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Lockfwd') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockfwd"..chat) then
			redis:del("lockfwd"..chat)
			result = 'قفل فوروارد غیرفعال شد.'
			else
			  redis:set("lockfwd"..chat, true)
			result = 'قفل فوروارد فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Lockbots') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockbots"..chat) then
			redis:del("lockbots"..chat)
			result = 'قفل ربات غیرفعال شد.'
			else
			  redis:set("lockbots"..chat, true)
			result = 'قفل ربات فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Lockcmd') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockcmd"..chat) then
			redis:del("lockcmd"..chat)
			result = 'قفل دستورات غیرفعال شد.'
			else
			  redis:set("lockcmd"..chat, true)
			result = 'قفل دستورات فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Locktag') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("locktag"..chat) then
			redis:del("locktag"..chat)
			result = 'قفل یوزرنیم غیرفعال شد.'
			else
			  redis:set("locktag"..chat, true)
			result = 'قفل یوزرنیم فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Lockcontact') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockcontact"..chat) then
			redis:del("lockcontact"..chat)
			result = 'قفل مخاطب غیرفعال شد.'
			else
			  redis:set("lockcontact"..chat, true)
			result = 'قفل مخاطب فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Locktext') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("locktext"..chat) then
			redis:del("locktext"..chat)
			result = 'قفل متن غیرفعال شد.'
			else
			  redis:set("locktext"..chat, true)
			result = 'قفل متن فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Lockpin') then
			local chat = '-'..q.data:match('(%d+)$')
			if is_owner(chat,q.from.id) then
			if redis:get("lockpin"..chat) then
			redis:del("lockpin"..chat)
			result = 'قفل سنجاق غیرفعال شد.'
			else
			  redis:set("lockpin"..chat, true)
			result = 'قفل سنجاق فعال شد.'
			end
			else Canswer(q.id,'■ این قفل مختص مالک گروه می باشد.',true)
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
			if q.data:match('Lockedit') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockedit"..chat) then
			redis:del("lockedit"..chat)
			result = 'قفل ویرایش غیرفعال شد.'
			else
			  redis:set("lockedit"..chat, true)
			result = 'قفل ویرایش فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'Setting'..chat
			end
						 if q.data:match('Setting') then
			 local chat = '-'..q.data:match('(%d+)$')
			 local lock1 = redis:get("locklink"..chat)
			 local lock2 = redis:get("lockchat"..chat)
			 local lock3 = redis:get("lockfwd"..chat)
			 local lock4 = redis:get("lockbots"..chat)
			 local lock5 = redis:get("lockcmd"..chat)
			 local lock6 = redis:get("locktag"..chat)
			 local lock7 = redis:get("lockcontact"..chat)
			 local lock8 = redis:get("locktext"..chat)
			 local lock9 = redis:get("lockpin"..chat)
			 local lock10 = redis:get("lockedit"..chat)
			  if lock1 then
                link = "【فعال | 🔐】"
              else
                link = "【غیرفعال | 🔓】"
              end
              if lock2 then
                chats = "【فعال | 🔐】"
              else
                chats = "【غیرفعال | 🔓】"
              end
              if lock3 then
                fwd = "【فعال | 🔐】"
              else
                fwd = "【غیرفعال | 🔓】"
              end
              if lock4 then
                bots = "【فعال | 🔐】"
              else
                bots = "【غیرفعال | 🔓】"
              end
              if lock5 then
                cmd = "【فعال | 🔐】"
              else
                cmd = "【غیرفعال | 🔓】"
              end
              if lock6 then
                tag = "【فعال | 🔐】"
              else
                tag = "【غیرفعال | 🔓】"
              end
			  if lock7 then
                cont = "【فعال | 🔐】"
              else
                cont = "【غیرفعال | 🔓】"
              end
			  if lock8 then
                txt = "【فعال | 🔐】"
              else
                txt = "【غیرفعال | 🔓】"
              end
			  if lock9 then
                pin = "【فعال | 🔐】"
              else
                pin = "【غیرفعال | 🔓】"
              end
			  if lock10 then
                ed = "【فعال | 🔐】"
              else
                ed = "【غیرفعال | 🔓】"
              end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
		  {text = link, callback_data = 'Locklink'..chat},{text = 'قفل لینک ', callback_data = 'TGSecure'..chat}
		},{
		{text = chats, callback_data = 'Lockchat'..chat},{text = 'قفل چت ', callback_data = 'TGSecure'..chat}
		},{
		{text = fwd, callback_data = 'Lockfwd'..chat},{text = 'قفل فوروارد ', callback_data = 'TGSecure'..chat}
		},{
		{text = bots, callback_data = 'Lockbots'..chat},{text = 'قفل ربات ', callback_data = 'TGSecure'..chat}
		},{
		{text = cmd, callback_data = 'Lockcmd'..chat},{text = 'قفل دستورات ', callback_data = 'TGSecure'..chat}
		},{
		{text = tag, callback_data = 'Locktag'..chat},{text = 'قفل یوزرنیم ', callback_data = 'TGSecure'..chat}
		},{
		{text = cont, callback_data = 'Lockcontact'..chat},{text = 'قفل مخاطب ', callback_data = 'TGSecure'..chat}
		},{
		{text = txt, callback_data = 'Locktext'..chat},{text = 'قفل متن ', callback_data = 'TGSecure'..chat}
		},{
		{text = pin, callback_data = 'Lockpin'..chat},{text = 'قفل سنجاق ', callback_data = 'TGSecure'..chat}
		},{
		{text = ed, callback_data = 'Lockedit'..chat},{text = 'قفل ویرایش ', callback_data = 'TGSecure'..chat}
		},{
                   {text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat},{text = '»', callback_data = 'pagetwo'..chat}
				}
		}
		 edit(q.inline_message_id, "به صفحه اول تنظیمات گروه خوش امدید.\n\nتنظیمات گروه خود را انتخاب کنید:", keyboard, 'html')
			end
			if q.data:match('LockTgservice') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("locktgservice"..chat) then
			redis:del("locktgservice"..chat)
			result = 'قفل پیام سرویسی غیرفعال شد.'
			else
			  redis:set("locktgservice"..chat, true)
			result = 'قفل پیام سرویسی فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockfile') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockfile"..chat) then
			redis:del("lockfile"..chat)
			result = 'قفل فایل غیرفعال شد.'
			else
			  redis:set("lockfile"..chat, true)
			result = 'قفل فایل فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockenglish') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockenglish"..chat) then
			redis:del("lockenglish"..chat)
			result = 'قفل کلمات انگلیسی غیرفعال شد.'
			else
			  redis:set("lockenglish"..chat, true)
			result = 'قفل کلمات انگلیسی فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockfarsi') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockfarsi"..chat) then
			redis:del("lockfarsi"..chat)
			result = 'قفل کلمات عربی/فارسی غیرفعال شد.'
			else
			  redis:set("lockfarsi"..chat, true)
			result = 'قفل کلمات عربی/فارسی فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockinline') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockinline"..chat) then
			redis:del("lockinline"..chat)
			result = 'قفل اینلاین غیرفعال شد.'
			else
			  redis:set("lockinline"..chat, true)
			result = 'قفل اینلاین فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Locksticker') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("locksticker"..chat) then
			redis:del("locksticker"..chat)
			result = 'قفل استیکر غیرفعال شد.'
			else
			  redis:set("locksticker"..chat, true)
			result = 'قفل استیکر فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockphoto') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockphoto"..chat) then
			redis:del("lockphoto"..chat)
			result = 'قفل عکس غیرفعال شد.'
			else
			  redis:set("lockphoto"..chat, true)
			result = 'قفل عکس فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockgif') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockgif"..chat) then
			redis:del("lockgif"..chat)
			result = 'قفل گیف غیرفعال شد.'
			else
			  redis:set("lockgif"..chat, true)
			result = 'قفل گیف فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockvideo') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockvideo"..chat) then
			redis:del("lockvideo"..chat)
			result = 'قفل فیلم غیرفعال شد.'
			else
			  redis:set("lockvideo"..chat, true)
			result = 'قفل فیلم فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockselfvideo') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockselfvideo"..chat) then
			redis:del("lockselfvideo"..chat)
			result = 'قفل فیلم سلفی غیرفعال شد.'
			else
			  redis:set("lockselfvideo"..chat, true)
			result = 'قفل فیلم سلفی فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
			if q.data:match('Lockaudio') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockaudio"..chat) then
			redis:del("lockaudio"..chat)
			result = 'قفل صدا غیرفعال شد.'
			else
			  redis:set("lockaudio"..chat, true)
			result = 'قفل صدا فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagetwo'..chat
			end
	if q.data:match('pagetwo') then
			 local chat = '-'..q.data:match('(%d+)$')
			 local lock1 = redis:get("locktgservice"..chat)
			 local lock2 = redis:get("lockfile"..chat)
			 local lock3 = redis:get("lockenglish"..chat)
			 local lock4 = redis:get("lockfarsi"..chat)
			 local lock5 = redis:get("lockinline"..chat)
			 local lock6 = redis:get("locksticker"..chat)
			 local lock7 = redis:get("lockphoto"..chat)
			 local lock8 = redis:get("lockgif"..chat)
			 local lock9 = redis:get("lockvideo"..chat)
			 local lock10 = redis:get("lockselfvideo"..chat)
			 local lock11 = redis:get("lockaudio"..chat)
			  if lock1 then
                tg = "【فعال | 🔐】"
              else
                tg = "【غیرفعال | 🔓】"
              end
              if lock2 then
                fils = "【فعال | 🔐】"
              else
                fils = "【غیرفعال | 🔓】"
              end
              if lock3 then
                en = "【فعال | 🔐】"
              else
                en = "【غیرفعال | 🔓】"
              end
              if lock4 then
                fa = "【فعال | 🔐】"
              else
                fa = "【غیرفعال | 🔓】"
              end
              if lock5 then
                inline = "【فعال | 🔐】"
              else
                inline = "【غیرفعال | 🔓】"
              end
              if lock6 then
                stick = "【فعال | 🔐】"
              else
                stick = "【غیرفعال | 🔓】"
              end
			  if lock7 then
                photo = "【فعال | 🔐】"
              else
                photo = "【غیرفعال | 🔓】"
              end
			  if lock8 then
                gif = "【فعال | 🔐】"
              else
                gif = "【غیرفعال | 🔓】"
              end
			  if lock9 then
                film = "【فعال | 🔐】"
              else
                film = "【غیرفعال | 🔓】"
              end
			  if lock10 then
                self = "【فعال | 🔐】"
              else
                self = "【غیرفعال | 🔓】"
              end
			  if lock11 then
                audio = "【فعال | 🔐】"
              else
                audio = "【غیرفعال | 🔓】"
              end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
		  {text = tg, callback_data = 'LockTgservice'..chat},{text = 'قفل پیام سرویسی ', callback_data = 'TGSecure'..chat}
		},{
		{text = fils, callback_data = 'Lockfile'..chat},{text = 'قفل فایل ', callback_data = 'TGSecure'..chat}
		},{
		{text = en, callback_data = 'Lockenglish'..chat},{text = 'قفل انگلیسی ', callback_data = 'TGSecure'..chat}
		},{
		{text = fa, callback_data = 'Lockfarsi'..chat},{text = 'قفل فارسی ', callback_data = 'TGSecure'..chat}
		},{
		{text = inline, callback_data = 'Lockinline'..chat},{text = 'قفل اینلاین ', callback_data = 'TGSecure'..chat}
		},{
		{text = stick, callback_data = 'Locksticker'..chat},{text = 'قفل استیکر ', callback_data = 'TGSecure'..chat}
		},{
		{text = photo, callback_data = 'Lockphoto'..chat},{text = 'قفل عکس ', callback_data = 'TGSecure'..chat}
		},{
		{text = gif, callback_data = 'Lockgif'..chat},{text = 'قفل گیف ', callback_data = 'TGSecure'..chat}
		},{
		{text = film, callback_data = 'Lockvideo'..chat},{text = 'قفل فیلم ', callback_data = 'TGSecure'..chat}
		},{
		{text = self, callback_data = 'Lockselfvideo'..chat},{text = 'قفل فیلم سلفی ', callback_data = 'TGSecure'..chat}
		},{
		{text = audio, callback_data = 'Lockaudio'..chat},{text = 'قفل صدا ', callback_data = 'TGSecure'..chat}
		},{
                   {text = '«', callback_data = 'Setting'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat},{text = '»', callback_data = 'pagethree'..chat}
				}
		}
		 edit(q.inline_message_id, "به صفحه دوم تنظیمات گروه خوش امدید.\n\nتنظیمات گروه خود را انتخاب کنید:", keyboard, 'html')
			end
			if q.data:match('Lockflood') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockflood"..chat) then
			redis:del("lockflood"..chat)
			result = 'قفل رگبار غیرفعال شد.'
			else
			  redis:set("lockflood"..chat, true)
			result = 'قفل رگبار فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagethree'..chat
			end
			if q.data:match('Lockcher') then
			local chat = '-'..q.data:match('(%d+)$')
			if redis:get("lockcher"..chat) then
			redis:del("lockcher"..chat)
			result = 'قفل کاراکتر غیرفعال شد.'
			else
			  redis:set("lockcher"..chat, true)
			result = 'قفل کاراکتر فعال شد.'
			end
			Canswer(q.id,result)
			q.data = 'pagethree'..chat
			end
			if q.data:match('Floodmaxup') then
			local chat = '-'..q.data:match('(%d+)$')
			if not redis:get("floodmax" .. chat) then
                flood_max = 5
              else
                flood_max = tonumber(redis:get("floodmax" .. chat))
              end
			  local res = flood_max + 1
			  if not (res > 50) then
			  redis:set('floodmax'..chat,res)
			  Canswer(q.id,'حساسیت تشخیص رگبار به '..res..' عدد تنظیم شد.')
			  q.data = 'pagethree'..chat
			  else
			  Canswer(q.id,'حداکثر حساسیت رگبار 50 عدد میباشد !')
			  end
			end
			if q.data:match('Floodmaxdown') then
			local chat = '-'..q.data:match('(%d+)$')
			if not redis:get("floodmax" .. chat) then
                flood_max = 5
              else
                flood_max = tonumber(redis:get("floodmax" .. chat))
              end
			  local res = flood_max - 1
			  if not (res < 2) then
			  redis:set('floodmax'..chat,res)
			  Canswer(q.id,'حساسیت تشخیص رگبار به '..res..' عدد تنظیم شد.')
			  q.data = 'pagethree'..chat
			  else
			  Canswer(q.id,'حداقل حساسیت رگبار 2 عدد میباشد !')
			  end
			end
			if q.data:match('Cherup') then
			local chat = '-'..q.data:match('(%d+)$')
			if not redis:get("cher" .. chat) then
                char_max = 250
              else
                char_max = tonumber(redis:get("cher" .. chat))
              end
			  local res = char_max + 50
			  if not (res > 4049) then
			  redis:set('cher'..chat,res)
			  Canswer(q.id,'حساسیت پیام به '..res..' کاراکتر تنظیم شد.')
			  q.data = 'pagethree'..chat
			  else
			  Canswer(q.id,'حداکثر حساسیت کاراکتر 4049 عدد میباشد !')
			  end
			end
			if q.data:match('Cherdown') then
			local chat = '-'..q.data:match('(%d+)$')
			if not redis:get("cher" .. chat) then
                char_max = 250
              else
                char_max = tonumber(redis:get("cher" .. chat))
              end
			  local res = char_max - 50
			  if not (res < 40) then
			  redis:set('cher'..chat,res)
			  Canswer(q.id,'حساسیت پیام به '..res..' کاراکتر تنظیم شد.')
			  q.data = 'pagethree'..chat
			  else
			  Canswer(q.id,'حداقل حساسیت کاراکتر 40 عدد میباشد !')
			  end
			end
			if q.data:match('Warnup') then
			local chat = '-'..q.data:match('(%d+)$')
			if not redis:get("max_warn:" .. chat) then
                char_max = 3
              else
                char_max = tonumber(redis:get("max_warn:" .. chat))
              end
			  local res = char_max + 1
			  if not (res > 10) then
			  redis:set('max_warn:'..chat,res)
			  Canswer(q.id,'حداکثر مقدار اخطار به کاربران تنظیم شد به '..res..' عدد.')
			  q.data = 'pagethree'..chat
			  else
			  Canswer(q.id,'حداکثر مقدار اخطار به کاربران 10 عدد میباشد !')
			  end
			end
			if q.data:match('Warndown') then
			local chat = '-'..q.data:match('(%d+)$')
			if not redis:get("max_warn:" .. chat) then
                char_max = 3
              else
                char_max = tonumber(redis:get("max_warn:" .. chat))
              end
			  local res = char_max - 1
			  if not (res < 1) then
			  redis:set('max_warn:'..chat,res)
			  Canswer(q.id,'حداکثر مقدار اخطار به کاربران تنظیم شد به '..res..' عدد.')
			  q.data = 'pagethree'..chat
			  else
			  Canswer(q.id,'حداقل مقدار اخطار به کاربران 1 عدد میباشد !')
			  end
			end
			if q.data:match('pagethree') then
			 local chat = '-'..q.data:match('(%d+)$')
			 local lock1 = redis:get("lc_ato:"..chat)
			 local lock2 = redis:get("atolct1"..chat)
			 local lock3 = redis:get("atolct2"..chat)
			 local lock4 = redis:get("lockflood"..chat)
			 local lock5 = redis:get("floodmax"..chat)
			 local lock6 = redis:get("lockcher"..chat)
			 local lock7 = redis:get("cher"..chat)
			 local lock8 = redis:get("max_warn:"..chat)
			 
			  if lock1 then
                auto = "【فعال | 🔐】"
              else
                auto = "【غیرفعال | 🔓】"
              end
              if lock2 then
                auto_start = 'از ساعت '..lock2
              else
                auto_start = 'ثبت نشده است '
              end
              if lock3 then
                auto_stop = ' تا ساعت '..lock3
              else
                auto_stop = ""
              end
              if lock4 then
                flood = "【فعال | 🔐】"
              else
                flood = "【غیرفعال | 🔓】"
              end
              if lock5 then
                floodmax = lock5
              else
                floodmax = "5"
              end
              if lock6 then
                cher = "【فعال | 🔐】"
              else
                cher = "【غیرفعال | 🔓】"
              end
			  if lock7 then
                chers = lock7
              else
                chers = "250"
              end
			  if lock8 then
                warn = lock8
              else
                warn = "3"
              end
		local keyboard = {}
		keyboard.inline_keyboard = {
		{
		  {text = 'قفل خودکار', callback_data = 'TGSecure'..chat}
		},{
		{text = 'وضعیت قفل خودکار '..auto, callback_data = 'TGSecure'..chat}
		},{
		{text = 'ساعات تعطیلی گروه  '..auto_start..auto_stop, callback_data = 'TGSecure'..chat}
		},{
		{text = flood, callback_data = 'Lockflood'..chat},{text = 'قفل رگبار ', callback_data = 'TGSecure'..chat}
		},{
		{text = 'تنظیم رگبار', callback_data = 'TGSecure'..chat}
		},{
		{text = '<', callback_data = 'Floodmaxdown'..chat},{text = floodmax, callback_data = 'TGSecure'..chat},{text = '>', callback_data = 'Floodmaxup'..chat}
		},{
		{text = cher, callback_data = 'Lockcher'..chat},{text = 'قفل کاراکتر ', callback_data = 'TGSecure'..chat}
		},{
		{text = 'تنظیم کاراکتر', callback_data = 'TGSecure'..chat}
		},{
		{text = '<', callback_data = 'Cherdown'..chat},{text = chers, callback_data = 'TGSecure'..chat},{text = '>', callback_data = 'Cherup'..chat}
		},{
		{text = 'تنظیم اخطار', callback_data = 'TGSecure'..chat}
		},{
		{text = '<', callback_data = 'Warndown'..chat},{text = warn, callback_data = 'TGSecure'..chat},{text = '>', callback_data = 'Warnup'..chat}
		},{
                   {text = '«', callback_data = 'pagetwo'..chat},{text = '■ منوی اصلی ■', callback_data = 'Firstmenu'..chat}
				}
		}
		 edit(q.inline_message_id, "به صفحه سوم تنظیمات گروه خوش امدید.\n\nتنظیمات گروه خود را انتخاب کنید:", keyboard, 'html')
			end

            else Canswer(q.id,'■ شما مدیر نیستید و اجازه استفاده از پنل مدیریتی را ندارید.',true)
						end
						end
          if msg.message and msg.message.date > (os.time() - 5) and msg.message.text then
     end
      end
    end
  end
    end
end

return run()
