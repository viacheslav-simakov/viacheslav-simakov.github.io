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
my	$html_folder = 'D:\Git-Hub\viacheslav-simakov.github.io\med';
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
	make_pattern('med.txt', $hash, $html_folder);
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
        Carp::confess "Bсходный файл '$db_file' не существует";
    }
    unless (-f $db_file)
	{
        Carp::confess "Исходный путь '$db_file' не является файлом";
    }
	unless (-d $target_folder)
	{
        Carp::confess "Папка для копирования '$target_folder' не существует";
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
	print ">>> $db_copy\n\n";
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
		$html_file =~ s/\\/\//g;
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
