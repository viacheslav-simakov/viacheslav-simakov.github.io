REM ÑÏÈÑÎÊ ÊÎÌÀÍÄ CMD
REM https://ab57.ru/cmdlist.html
ECHO OFF
CLS
CHCP 1251
rem **************************************************************************
rem
rem	ÏÀÐÀÌÅÒÐÛ ÎÊÐÓÆÅÍÈß
rem
rem **************************************************************************
REM òåêóùàÿ ïàïêà
rem SET ROOT_FOLDER=%CD%\..
REM ïàïêà ñ ôàéëàìè áàç äàííûõ
SET DB_FOLDER=C:\Apache24\sql
REM HTML-ôàéë
SET HTTP_URL=https://viacheslav-simakov.github.io/telegram/html/med.html
REM çàïóñê Telegram Bot
perl "bot.p" 2> bot.log
rem **************************************************************************
PAUSE