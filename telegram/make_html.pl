#
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#
#	Альтернативный warn и die для модулей
#	https://perldoc.perl.org/Carp
use Carp();
#
#	Копирование файлов или файловых дескрипторов
#	https://metacpan.org/pod/File::Copy
use File::Copy();
#
#	папки библиотек (модулей)
#	'.' = текущая папка!
use lib ('C:\Apache24\web\cgi-bin\pm', 'D:\GIT-HUB\apache\web\cgi-bin\pm');
#
#	Утилиты
use Utils();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	БАЗА ДАННЫХ: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	Папка для сохранения HTML-файла
my	$html_folder = 'C:\Git-Hub\viacheslav-simakov.github.io\med';
#
#	Копирование файла базы данных
my	$db_file = db_copy('C:\Apache24\sql\med.db', $html_folder);
#
#	открыть базу данных
my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
		or Carp::confess "$DBI::errstr\n\n\t";
#	
#	указатель таблицы
my	$sth;
#
#	Хэш для замены
my	$hash;
#
#	Данные таблицы
my	$data;
##############################################################################
#
#	"Препараты"
#
$data = '';
#
#	SQL-запрос
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "preparation"
	WHERE id IN (
		SELECT preparation FROM "indication"
	)
	ORDER BY num
@);
$sth->execute();
#
#	цикл по выбранным записям
while (my $row = $sth->fetchrow_hashref)
{
#	информация
$row->{info} ||= 'нет информации';
#	строка таблицы
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="preparation#%1\$d" class="item-checkbox"
		id="preparation-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="preparation-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	Хэш для замены
$hash->{'--preparation--'} = $data;
##############################################################################
#
#	"Заболевания"
#
$data = '';
#
#	SQL-запрос
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "rheumatology"
	WHERE id IN (
		SELECT rheumatology FROM "indication"
	)
	ORDER BY num
@);
$sth->execute();
#
#	цикл по выбранным записям
while (my $row = $sth->fetchrow_hashref)
{
#	информация
$row->{info} ||= 'нет информации';
#	строка таблицы
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="rheumatology#%1\$d" class="item-checkbox"
		id="rheumatology-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="rheumatology-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	Хэш для замены
$hash->{'--rheumatology--'} = $data;
##############################################################################
#
#	"Сопутствующие заболевания"
#
$data = '';
#
#	SQL-запрос
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "comorbidity"
	WHERE id IN (
		SELECT comorbidity FROM "contra-indication-comorbidity"
	)
	ORDER BY num
@);
$sth->execute();
#
#	цикл по выбранным записям
while (my $row = $sth->fetchrow_hashref)
{
#	информация
$row->{info} ||= 'нет информации';
#	строка таблицы
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="comorbidity#%1\$d" class="item-checkbox"
		id="comorbidity-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="comorbidity-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	Хэш для замены
$hash->{'--comorbidity--'} = $data;
##############################################################################
#
#	"Сопутствующие состояния"
#
$data = '';
#
#	SQL-запрос
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "status"
	WHERE id IN (
		SELECT status FROM "contra-indication-status"
	)
	ORDER BY num
@);
$sth->execute();
#
#	цикл по выбранным записям
while (my $row = $sth->fetchrow_hashref)
{
#	информация
$row->{info} ||= 'нет информации';
#	строка таблицы
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="status#%1\$d" class="item-checkbox"
		id="status-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="status-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	Хэш для замены
$hash->{'--status--'} = $data;
##############################################################################
#
#	"Лабораторные показатели (выбор из списка)"
#
$data = '';
#
#	SQL-запрос
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "probe-manual"
	WHERE id IN (
		SELECT "probe-manual" FROM "contra-indication-probe-manual"
	)
	ORDER BY num
@);
$sth->execute();
#	тело таблицы
my	$probe_manual = '';
#	цикл по выбранным записям
while (my $row = $sth->fetchrow_hashref)
{
#	информация
$row->{info} ||= 'нет информации';
#	строка таблицы
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="manual#%1\$d" class="item-checkbox"
		id="manual-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="manual-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	Хэш для замены
$hash->{'--probe-manual--'} = $data;
##############################################################################
#
#	"Лабораторные исследования (численные значения)"
#
$data = '';
#
#	SQL-запрос
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "probe"
	WHERE id IN (
		SELECT probe FROM "prescription"
	)
	ORDER BY num
@);
$sth->execute();
#
#	цикл по выбранным записям
while (my $row = $sth->fetchrow_hashref)
{
#	информация
$row->{info} ||= 'нет информации';
#	строка таблицы
$data .= sprintf qq
@
<div class="flex-box">
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<input type="number" class="probe-number" name="probe#%1\$d"
			step="0.1" min="0" max="100"/>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	Хэш для замены
$hash->{'--probe--'} = $data;
#
#	Создать HTML-файл
#
#	make_pattern('med.txt', $hash, $html_folder);
	make_pattern(undef, $hash, $html_folder);
#exit;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=pod
	Копировать файл базы данных
	---
	$db_copy = db_copy($db_file, $target_folder)
	
		$db_file		- файл базы данных
		$target_folder	- папка для копирования
		$db_copy		- файл копии базы данных
=cut
sub db_copy
{
	#	имя файла, папка для копирования
	my	($db_file, $target_folder) = @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Преобразование слэшей
		$db_file =~ s/\\/\//g;
		$target_folder =~ s/\\/\//g;
	#	Проверки файла базы данных
    unless (-e $db_file)
	{
        Carp::confess "Bсходный файл '$db_file' не существует\n";
    }
    unless (-f $db_file)
	{
        Carp::confess "Исходный путь '$db_file' не является файлом\n";
    }
	unless (-d $target_folder)
	{
        Carp::confess "Папка для копирования '$target_folder' не существует\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	путь файла
	my	@path = split(/\//, $db_file);
	#	путь копии файла базы данных
	my	$db_copy = sprintf '%s/%s' , $target_folder, $path[$#path];
	#
	#	копирование файла
	File::Copy::copy($db_file, $db_copy) or Carp::confess "Copy failed: $!";
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	файл базы данных
	print STDERR "Скопирован файл базы данных '$db_copy'\n";
	return $db_copy;
}
=pod
	Шаблон HTML
	---
	make_pattern($file_name, \%subs, $output_folder)
		
		$file_name		- имя файла шаблона
		%subs			- хэш для замены в файле шаблона
		$output_folder	- папка для HTML-файла
=cut
sub make_pattern
{
	#	имя файла, ссылка хэш, папка для HTML-файла
	my	($file_name, $subs, $output_folder) = @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Содержимое шаблона
	my	$content;
	#
	#	Имя HTML-файла
	my	$html_file = 'med';
	#
	#	Источник данных шаблона
	if (defined $file_name)
	{
		#	Открыть файл шаблона
		open(my $fh, '<', $file_name) or die "Cannot open '$file_name': $!";
		#
		#	Читать содержимое шаблона
		$content = do { local $/; <$fh> };
		#
		#	Закрыть файл
		close $fh;
		#
		#	новое имя HTML-файла
		my	@path = split('/', $file_name);
		my	@file = split('\.', $path[$#path]);
			$html_file = $file[0];
	}
	else
	{
		#	раздел __DATA__
		$content = do { local $/; <DATA> };
	}
	#
	#	Модификация шаблона
	Utils::subs(\$content, $subs);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Путь HTML-файла
		$html_file = sprintf '%s/%s.html', $output_folder, $html_file;
		$html_file =~ s/\\/\//g;
	#
	#	Открыть файл
	open(my $fh, ">", $html_file) or die "Cannot open '$html_file': $!";
	#
	#	Печать в файл
	print $fh $content;
	#
	#	Закрыть файл
	close($fh);
	#
	#	Вывод на экран
	print STDERR "Создан HTML-файл '$html_file'\n";
}
__DATA__
<!DOCTYPE html>
<html lang="ru-RU">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Электронный ассистент</title>
<!--meta http-equiv="content-type" content="text/html; charset=utf-8"/-->
<!--
	Файл стилей
	https://developer.mozilla.org/en-US/docs/Web/CSS
-->
<link href="med.css" rel="stylesheet" type="text/css"/>
<!--
	Google font's
-->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Ubuntu:wght@300;400;500&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined" rel="stylesheet" />
<!--
	Telegram "mini App"
	https://core.telegram.org/bots/webapps#initializing-mini-apps
-->
<script src="https://telegram.org/js/telegram-web-app.js?59"></script>

<style>
/*	Скрыть вкладки, радиокнопки */
div.tab-content, input[type=radio]
{
	display:	none;
}
/*	Показать содержимое вкладок */
#radio-rheumatology:checked ~	#req-form #rheumatology,
#radio-preparation:checked ~	#req-form #preparation,
#radio-comorbidity:checked ~ 	#req-form #comorbidity,
#radio-status:checked ~ 		#req-form #status,
#radio-deviation:checked ~ 		#req-form #deviation,
#radio-probe:checked ~ 			#req-form #probe
{
	display:	block;
}
/*	Подсветка выбора пользователя */
#radio-rheumatology:checked ~	#userDialog #label-rheumatology,
#radio-preparation:checked ~	#userDialog #label-preparation,
#radio-comorbidity:checked ~ 	#userDialog #label-comorbidity,
#radio-status:checked ~ 		#userDialog #label-status,
#radio-deviation:checked ~ 		#userDialog #label-deviation,
#radio-probe:checked ~ 			#userDialog #label-probe
{
	color:				var(--tg-theme-button-text-color, yellow);
	background-color:	var(--tg-theme-button-color, green);
}
</style>
</head>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	ОСНОВНОЕ СОДЕРЖАНИЕ

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<body>
<!--
	Радиокнопки меню
-->
	<input type="radio" id="radio-rheumatology"	name="tab-group" checked>
	<input type="radio" id="radio-preparation"	name="tab-group">
	<input type="radio" id="radio-comorbidity"	name="tab-group">
	<input type="radio" id="radio-status"		name="tab-group">
	<input type="radio" id="radio-deviation"	name="tab-group">
	<input type="radio" id="radio-probe"		name="tab-group">
	<input type="radio" id="radio-prescription"	name="tab-group">
<!--
	Меню
-->
<div id="showMenu" class="header-fixed">
	<div class="title-icon">rheumatology</div>
	<div class="title-text">Основное заболевание</div>
</div>
<!--
	Диалоговое окно
-->
<dialog id="userDialog">
	<!-- :: ВЫБОР ОПЦИЙ :: -------------------------------------------------------->
	<div class="menu">
		<!-- Заболевания -->
		<label id="label-rheumatology" for="radio-rheumatology">
			<span>rheumatology</span><div>Основное заболевание</div></label>

		<!-- Сопутствующие заболевания -->
		<label id="label-comorbidity" for="radio-comorbidity">
			<span>person_cancel</span><div>Сопутствующие заболевания</div></label>
	
		<!-- Сопутствующие состояния -->
		<label id="label-status" for="radio-status">
			<span>person_alert</span><div>Сопутствующие состояния</div></label>

		<!-- Сопутствующие отклонения -->
		<label id="label-deviation" for="radio-deviation">
			<span>instant_mix</span><div>Лабораторные показатели</div></label>
		
		<!-- Лабораторные показатели -->
		<label id="label-probe" for="radio-probe">
			<span>biotech</span><div>Лабораторные исследования</div></label>

		<!-- Препараты -->
		<label id="label-preparation" for="radio-preparation">
			<span>pill</span><div>Препараты</div></label>
	</div>
</dialog>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	Основное заболевание

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<form id="req-form">
<div id="rheumatology" class="tab-content">
##--RHEUMATOLOGY--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	Сопутствующие заболевания

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="comorbidity" class="tab-content">
##--COMORBIDITY--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	Сопутствующие состояния

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="status" class="tab-content">
##--STATUS--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	Лабораторные показатели (выбор из списка)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="deviation" class="tab-content">
##--PROBE-MANUAL--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	Лабораторные исследования

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="probe" class="tab-content">
##--PROBE--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	Препараты

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="preparation" class="tab-content">
##--PREPARATION--##
</div>
</form>
<!--##########################################################################

	Telegram Web API
	https://core.telegram.org/bots/webapps#events-available-for-mini-apps

###########################################################################-->
<script>
	//	Web-API
	let tg = window.Telegram.WebApp;
	//	Инициализируем WebApp
		tg.ready();
	//	во весь экран
		tg.expand();
	//	Получаем информацию о пользователе
	const user = tg.initDataUnsafe.user;
	//	Наименования секций (разделов) HTML-страницы
	const section = ["rheumatology","preparation","comorbidity","status","manual"];
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//
	//	Главная кнопка
	//
	tg.MainButton.setText("Рекомендации").show();
	//	Add an event listener for when the SettingButton is clicked
	tg.onEvent('mainButtonClicked', () => {
		//
		//	Данные для отправки в Telegram Bot
		let dataToSend = {};
		//
		//	Цикл по названию секций, содержащих флажки (checkbox)
		for (let i = 0; i < section.length; i++) {
			//
			//	Селекторы: https://learn.javascript.ru/css-selectors
			//
			let elem = document.querySelectorAll("input[name^='" + section[i] + "#']");
			//
			//	Массив ID значений флажков (checkbox)
			let id = [];
			//
			//	цикл по всем элементам списка
			for (let j = 0; j < elem.length; j++) {
				//
				//	Пропустить оставшуюся часть тела цикла
				if (elem[j].checked === false) continue;
				//
				//	Добавить в массив
				id.push(elem[j].name.split("#")[1]);
			}
			//	Список ID флажков
			dataToSend[section[i]] = id;
		}
		//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		//	Коллекция полей ввода (input)
		//	Селекторы: https://learn.javascript.ru/css-selectors
		let elem = document.querySelectorAll("input[name^='probe#']");
		//
		//	Массив объектов (полей ввода)
		let probe = [];
		//
		//	цикл по всем элементам списка
		for (let j = 0; j < elem.length; j++) {
			//
			//	Пропустить оставшуюся часть тела цикла
			if (elem[j].value == "") continue;
			//
			//	Добавить в массив
			probe.push(
			{
				id:		elem[j].name.split("#")[1],
				val:	elem[j].value
			});
		}
		//	Список объектов
		dataToSend["probe"] = probe;
		//
		//	Преобразуем массив объектов в строку JSON
		const jsonString = JSON.stringify(dataToSend);
		
//		alert("Main button clicked!\nКоличество символов: " + jsonString.length);
		//
		// Send the data to the bot
		tg.sendData(jsonString);
		//
		// You can also send data back to the bot here
		// tg.sendData(JSON.stringify({ action: 'secondary_button_pressed' }));
	});
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//
	//	Вторичная кнопка
	//	https://www.google.com/search?q=telegram+WebApp+secondaryButton+example+js+code&oq=telegram+WebApp+secondaryButton+example+js+code
	//	tg.SecondaryButton.setText("Назад").show();
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//
	//	Кнопка "Установки"
	tg.SettingsButton.show();
	//	Add an event listener for when the SettingButton is clicked
	tg.onEvent('settingsButtonClicked', () => {
		alert('Setting button clicked!');
		// You can also send data back to the bot here
		// tg.sendData(JSON.stringify({ action: 'secondary_button_pressed' }));
	});	
</script>
<!--##########################################################################

	Хранилище устройства (DeviceStorage)
	https://core.telegram.org/bots/webapps#devicestorage

###########################################################################-->
<script>
	//	Локальное хранилище данных
	let ds = tg.DeviceStorage;
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//	Цикл по названию секций, содержащих checkbox
	for (let i = 0; i < section.length; i++) {
		//
		//	Коллекция флажков в секции:	https://learn.javascript.ru/css-selectors
		let elem = document.querySelectorAll("input[name^='" + section[i] + "#']");
		//
		//	Цикл по всем флажкам (checkbox) из секции
		for (let j = 0; j < elem.length; j++) {
			//
			//	Восстановить значение флажка
			ds.getItem(JSON.stringify(elem[j].name), (error, result) => {
				//
				//	Нет информации в хранилище?
				if (result !== null) {
					//
					//	Присвоить значение флажку
					elem[j].checked = JSON.parse(result);
				}
				else {
					elem[j].checked = false;
				}
			});
			//
			//	Обработчик событий для каждого флажка
			elem[j].addEventListener('click', function(event) {
				//
				//	Записать в хранилище устройства
				ds.setItem(
					JSON.stringify(elem[j].name),
					JSON.stringify(elem[j].checked));
			});
		}
	};
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//	Коллекция строк полей ввода (input)
	//	https://learn.javascript.ru/css-selectors
	let probe = document.querySelectorAll("input[name^='probe#']");
	//
	//	Цикл по всем полям ввода
	for (let j = 0; j < probe.length; j++) {
		//
		//	Восстановить значение поля ввода
		ds.getItem(JSON.stringify(probe[j].name), (error, result) => {
			//
			//	нет записи в хранилище?
			if (result !== null) {
				//
				//	Присвоить значение
				probe[j].value = JSON.parse(result);
			}
			else {
				probe[j].value = "";
			}
		});
		//
		//	Обработчик событий для каждого поля ввода
		probe[j].addEventListener('change', function(event) {
			//
			//	Записать в хранилище устройства
			ds.setItem(
				JSON.stringify(probe[j].name),
				JSON.stringify(probe[j].value));
		});
	};
</script>
<!--##########################################################################

	Окно диалога (меню выбора вкладки)
	https://developer.mozilla.org/ru/docs/Web/HTML/Reference/Elements/dialog

###########################################################################-->
<script>
	const showMenu = document.getElementById("showMenu");
	const userDialog = document.getElementById("userDialog");
	const itemMenu = userDialog.querySelectorAll("label");
	//
	// "Show the dialog" button opens the <dialog> modally
	showMenu.addEventListener("click", () => {
		//
		//	Показать окно
		userDialog.showModal();
		//
		//	Скрыть Главную кнопку
		tg.MainButton.hide();
	});
	//
	//	цикл по всем пунктам меню
	for (let i = 0; i < itemMenu.length; i++) {
		//
		// Добавляем прослушиватель для закрытия при клике
		itemMenu[i].addEventListener("click", () => {
			//
			//	Закрываем диалог
			userDialog.close();
			//
			//	Изменить значок
			showMenu.querySelector(".title-icon").textContent =
				itemMenu[i].querySelector("span").textContent;
			//
			//	Изменить название
			showMenu.querySelector(".title-text").textContent =
				itemMenu[i].querySelector("div").textContent;
			//
			//	Показать Главную кнопку
			tg.MainButton.show();
		});
	}
	// Добавляем прослушиватель для закрытия при клике вне диалога
	document.addEventListener('click', function(event) {
//		alert("Ok");
		console.log(userDialog.open);
		// Проверяем, кликнули ли по самому диалогу или его содержимому
		if (!userDialog.contains(event.target) && userDialog.open) {
//			userDialog.close(); // Закрываем диалог
		}
	});
</script>
</body>
</html>