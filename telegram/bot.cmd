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
REM папка с шаблонами
SET TEMPLATE_FOLDER=%CD%\TeX-template
REM папка с заданиями
SET OUTPUT_FOLDER=%CD%\~TeX-output
REM папка с файлами баз данных
SET DB_FOLDER=%CD%\databases
REM количество вариантов заданий (required default 1)
SET MAKE_SAMPLES=1
REM количество компиляций pdf-файла (required default 2)
SET RUN_COMPILES=0

rem perl "www-example.p"
perl "telegram.p"
rem **************************************************************************
PAUSE