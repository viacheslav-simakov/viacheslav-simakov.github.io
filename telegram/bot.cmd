REM СПИСОК КОМАНД CMD
REM https://ab57.ru/cmdlist.html
ECHO OFF
CLS
CHCP 1251
rem **************************************************************************
rem
rem	ПАРАМЕТРЫ ОКРУЖЕНИЯ
rem
rem **************************************************************************
REM текущая папка
rem SET ROOT_FOLDER=%CD%\..
REM папка с файлами баз данных
SET DB_FOLDER=C:\Apache24\sql
REM HTML-файл
SET HTTP_URL=https://viacheslav-simakov.github.io/telegram/html/med.html
REM запуск Telegram Bot
perl "bot.p"
rem **************************************************************************
PAUSE