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
SET ROOT_FOLDER=%CD%\..
REM папка с файлами баз данных
SET DB_FOLDER=C:\Apache24\sql
REM папка с HTML-файлом
SET HTML_FOLDER=%CD%\..\med
REM запуск Telegram Bot
perl "bot.p"
rem **************************************************************************
PAUSE