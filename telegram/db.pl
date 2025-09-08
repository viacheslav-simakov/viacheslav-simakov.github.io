#! perl
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	localhost/cgi-bin/user.pl
#
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#
#	папки библиотек (модулей)
#	'.' = текущая папка!
use lib ('C:\Apache24\web\cgi-bin\pm', 'D:\GIT-HUB\apache\web\cgi-bin\pm');
#
#	Утилиты
use Utils();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	ссылка на хэш
my	$query = {};
#
#	БАЗА ДАННЫХ: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#	файл базы данных
#my	$db_file = 'C:/Apache24/sql/med.db';
my	$db_file = 'D:/GIT-HUB/apache/sql/med.db';
#	открыть базу данных
my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
		or die $DBI::errstr;
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
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	Создать HTML-файл
#
	make_pattern(
		'med.txt', $hash,
		'D:\GIT-HUB\viacheslav-simakov.github.io\med');
#		'C:\Git-Hub\viacheslav-simakov.github.io\med');
exit;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
	#	Открыть файл шаблона
	open(my $fh, '<', $file_name) or die "Cannot open '$file_name': $!";
	#
	#	Читать содержимое шаблона
	my $content = do { local $/; <$fh> };
	#
	#	Закрыть файл
	close $fh;
	#
	#	Модификация шаблона
	Utils::subs(\$content, $subs);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	имя HTML-файла
	$file_name = do
	{
		my	@path = split('/', $file_name);
		my	@file = split('\.', $path[$#path]);
		$file[0];
	};
	#	Путь HTML-файла
	my	$html_file = sprintf '%s/%s.html', $output_folder, $file_name;
	#
	#	Открыть файл
	open($fh, ">", $html_file) or die "Cannot open '$html_file': $!";
	#
	#	Печать в файл
	print $fh $content;
	#
	#	Закрыть файл
	close($fh);
	#
	#	Вывод на экран
	print STDERR "\n\n\tCreate HTML-file '$html_file'\n\n\n";
}
__DATA__
