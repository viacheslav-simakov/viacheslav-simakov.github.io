rem ������ ������ CMD
rem https://ab57.ru/cmdlist.html
@ECHO OFF
rem ������� ������
CLS
rem ������� ��������
CHCP 1251
rem
rem ���� ���� ������
rem SET DB_FILE=C:\Apache24\sql\med.db
rem
rem ��� ����� ���� ������
rem FOR %%I IN ("%DB_FILE%") DO SET "DB_FILE_NAME=%%~nxI"
rem
rem ����� ��� ���������� HTML-�����
rem SET HTML_FOLDER=C:\Git-Hub\viacheslav-simakov.github.io\med
rem SET HTML_FOLDER=D:/GIT-HUB/viacheslav-simakov.github.io/med
rem
rem SET "DB_TARGET=%HTML_FOLDER%\%DB_FILE_NAME%"
rem ECHO %DB_FILE%
rem ECHO %TARGET%
rem COPY /B /V "%DB_FILE%" "%DB_TARGET%"
rem
rem Telegram
perl "make_html.pl"
PAUSE