#!/bin/bash
COUNTER=1
while(true) do
./launch.sh
curl "https://api.telegram.org/bot374355200:AAGBAyVbnTm17Hb4N8AZy2fxTTQUPXrkcY0/sendmessage" -F "chat_id=-263678237" -F "text=ربات @@UltraSecure کرش شد و برای -${COUNTER}- بار  مجدد روشن شد🍃"
curl "https://api.telegram.org/bot374355200:AAGBAyVbnTm17Hb4N8AZy2fxTTQUPXrkcY0/sendmessage" -F "chat_id=-263678237" -F "text=بروز"
let COUNTER=COUNTER+1 
done
