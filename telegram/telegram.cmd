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
REM ����� � ���������
SET TEMPLATE_FOLDER=%CD%\TeX-template
REM ����� � ���������
SET OUTPUT_FOLDER=%CD%\~TeX-output
REM ����� � ������� ��� ������
SET DB_FOLDER=%CD%\databases
REM ���������� ��������� ������� (required default 1)
SET MAKE_SAMPLES=1
REM ���������� ���������� pdf-����� (required default 2)
SET RUN_COMPILES=0

rem perl "www-example.p"
perl "telegram.p"
rem **************************************************************************
PAUSE