REM ������ ������ CMD
REM https://ab57.ru/cmdlist.html
ECHO OFF
CLS
CHCP 1251
rem **************************************************************************
rem
rem	��������� ���������
rem
rem **************************************************************************
REM ������� �����
SET ROOT_FOLDER=%CD%\..
REM ����� � ������� ��� ������
SET DB_FOLDER=C:\Apache24\sql
REM ����� � HTML-������
SET HTML_FOLDER=%CD%\..\med
REM HTML-����
SET HTTP_URL=https://viacheslav-simakov.github.io/telegram/html/med.html
REM ������ Telegram Bot
perl "bot.p"
rem **************************************************************************
PAUSE