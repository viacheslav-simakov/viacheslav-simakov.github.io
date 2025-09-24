=pod

	Работа с базой данных 'med' SQLite

=cut
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#	Строковые структуры данных Perl, подходящие как для печати
#	https://metacpan.org/pod/Data::Dumper
use	Data::Dumper;
#	JSON (JavaScript Object Notation) кодирование/декодирование
#	https://metacpan.org/pod/JSON
use	JSON;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Создание, изменение и проверка PDF-файлов
#	https://metacpan.org/pod/PDF::API2
use PDF::API2;
#
#	Служебный класс для построения макетов таблиц
#	https://metacpan.org/pod/PDF::Table
use PDF::Table;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	БАЗА ДАННЫХ: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	Файл базы данных
#my	$db_file = 'C:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
my	$db_file = 'D:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
#
#	открыть базу данных
my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
		or die "$DBI::errstr\n\n\t";
#	
#	указатель таблицы
my	$sth;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Обработка SQL-запросов к базе данных SQLite
#
package tele_db {
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod
	Обработчик запросов к базе данных
	---
	db_request($dbh , \%query);

		$dbh	- указатель базы данных
		%query	- данные CGI-запроса

=cut
sub request {
	#	ссылка на хэш-данные запроса
	my	$query = shift @_;
	#-------------------------------------------------------------------------
	#	"Основное заболевание"
	my	$id_rheumatology = join(',', @{ $query->{rheumatology} });
	#
	#	SQL-запрос
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "rheumatology"
		WHERE id IN ($id_rheumatology)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	Данные
	my	@rheumatology = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('Основное заболевание', 'Информация')]);
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @rheumatology,
			[$row->{name}, $row->{info} || 'нет информации'];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"Сопутствующие заболевания"
	my	$id_comorbidity = join(',', @{ $query->{comorbidity} });
	#
	#	SQL-запрос
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "comorbidity"
		WHERE id IN ($id_comorbidity)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	Данные
	my	@comorbidity = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('Сопутствующие заболевания', 'Информация')]);
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @comorbidity,
			[$row->{name}, '', $row->{info} || ''];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"Сопутствующие состояния"
	my	$id_status = join(',', @{ $query->{status} });
	#
	#	SQL-запрос
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "status"
		WHERE id IN ($id_status)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	Данные
	my	@status = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('Сопутствующие состояния', 'Информация')]);
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @status,
			[$row->{name}, '', $row->{info} || ''];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"Лабораторные показатели"
	my	$id_manual = join(',', @{ $query->{manual} });
	#
	#	SQL-запрос
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "probe-manual"
		WHERE id IN ($id_manual)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	Данные
	my	@manual = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('Лабораторные показатели', 'Информация')]);
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @manual,
			[$row->{name}, '', $row->{info} || ''];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"Препараты"
	my	$id_preparation = join(',', @{ $query->{preparation} });
	#
	#	SQL-запрос
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "preparation"
		WHERE id IN ($id_preparation)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	Данные
	my	@preparation = ([ map {Encode::decode('windows-1251', $_)}
		('Препараты', 'Информация')] );
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @preparation, [ map {Encode::decode('UTF-8', $_)}
			($row->{name}, $row->{info} || '') ];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"Лабораторные исследования"
	my	%probe = map { $_->{id} => $_->{val} } @{ $query->{probe} };
	#
	#	id записей таблицы
	my	$id_probe = join(',', sort keys %probe);
	#
	#	SQL-запрос
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "probe"
		WHERE id IN ($id_probe)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	Данные
	my	@probe = ([Encode::decode('UTF-8', 'Лабораторные исследования'),'','']);
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @probe,
		[$row->{name}, $probe{$row->{id}}, $row->{info} || 'нет информации'];
	}
	pdf_table(\@preparation);
	
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return
	[
		\@rheumatology,
		\@comorbidity,
		\@status,
		\@manual,
		\@probe,
		\@preparation,
	]
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod

=cut
sub pdf_file
{
	#
	#	ссылки
#	return ($pdf, $font);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Новая таблица
	---
	pdf_table($data)
		
=cut
sub pdf_table
{
	#	Данные таблицы (ссылка на список)
	my	$data = shift @_;
=pod
	#
	#	Декодирование данных
	foreach my $i (0 .. $#{ $data })
	{
		foreach my $j (0 .. $#{ $data->[$i] })
		{
			$data->[$i]->[$j] = Encode::decode('UTF-8', $data->[$i]->[$j]);
		}
	}
=cut
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	Создаем PDF
	my	$pdf = PDF::API2->new();
	#
	#	Устанавливаем шрифт с кириллицей
	my	$font = $pdf->ttfont('Arial.ttf');
	#
	#	Добавить пустую страницу
	my	$page = $pdf->page();
	#
	#	A4 (210mm x 297mm)
		$page->mediabox(595, 842);  # 595 x 842 points
	
	#	Создаем таблицу
	my	$table = PDF::Table->new();
	#
	#	Опции таблицы
	#	https://metacpan.org/pod/PDF::Table#Table-settings
		$table->table(
			$pdf,
			$page,
			$data,
			header_props => {
				font 		=> $font,
				font_size	=> 14,
				bg_color	=> 'yellow',
				repeat		=> 1,    # 1/0 eq On/Off  if the header row should be repeated to every new page
			},
			font 		=> $font,
			font_size	=> 12,
			x         	=> 50,
			y			=> 842-50,
			w         	=> 500,
			h   		=> 500,
			padding   	=> 5,
			size		=> '5cm *',
			border_w	=> 1,
	#        background_color_odd  => "gray",
	#        background_color_even => "lightblue",
#			cell_props =>
#			[
#				[{colspan => 2}],#	Для первой строки, первой ячейки
#				[],
#				[{colspan => 4}],#	Для третьей строки, первой ячейки
#			],
	);
	#
	#	Сохраняем PDF
	#
	$pdf->saveas('russian_table2.pdf');
	
	print STDERR "Create file: 'russian_table2.pdf'\n";
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__