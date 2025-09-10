rem СПИСОК КОМАНД CMD
rem https://ab57.ru/cmdlist.html
ECHO OFF
rem Очистка экрана
CLS
rem Кодовая страница
CHCP 1251
rem
rem Файл базы данных
SET DB_FILE=C:/Apache24/sql/med.db
rem
rem Папка для сохранения HTML-файла
SET HTML_FOLDER=C:/Git-Hub/viacheslav-simakov.github.io/med
rem SET HTML_FOLDER=D:/GIT-HUB/viacheslav-simakov.github.io/med
rem
rem Telegram
rem
perl "db.pl"
PAUSE
