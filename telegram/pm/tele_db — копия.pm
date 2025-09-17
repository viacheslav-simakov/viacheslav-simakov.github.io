=pod

	Работа с базой данных 'med' SQLite

=cut
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#	JSON (JavaScript Object Notation) кодирование/декодирование
#	https://metacpan.org/pod/JSON
use	JSON;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	БАЗА ДАННЫХ: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	Файл базы данных
my	$db_file = 'C:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
#my	$db_file = 'D:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	папки библиотек (модулей)
#	'.' = текущая папка!
use lib ('C:\Apache24\web\cgi-bin\pm', 'D:\GIT-HUB\apache\web\cgi-bin\pm');
#
#	Утилиты
use Utils();
#
#	Формирование ОТЧЕТОВ из базы данных
#
use Report();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Обработка SQL-запросов к базе данных SQLite
#
package tele_db {
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Данные модуля
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	флажки html-формы
my	%FORM_checkbox =
(
	rheumatology	=> 'Основное заболевание',
	comorbidity		=> 'Сопутствующие заболевания',
	status			=> 'Сопутствующие состояния',
	manual			=> 'Лабораторные показатели',
	preparation		=> 'Препараты',
);
#
#	строки ввода html-формы
my	%FORM_number =
(
	probe			=> 'Лабораторные исследования',
);
=pod
foreach (keys %FORM_checkbox)
{
	$FORM_checkbox{$_} = Encode::encode('UTF-8',
		Encode::decode('windows-1251',
			$FORM_checkbox{$_}));
}
=cut
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Обработчик запросов к базе данных
	---
	request(\%query);

		%query	- данные CGI-запроса

=cut
sub request {
	#	ссылка на хэш-данные запроса
	my	$query = shift @_;
	#-------------------------------------------------------------------------
	#
	#	Открыть базу данных
	#
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die $DBI::errstr;
	#
	#	Данные запроса
	my	@request = ();
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	цикл по группам флажков (checkbox)
	foreach my $name (keys %FORM_checkbox)
	{
		#	ID флажков html-формы
		my	$id = join(',', @{ $query->{$name} });
		#
		#	SQL-запрос
		my	$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$name"
			WHERE id IN ($id)
			ORDER BY "name_lc"
		@);
		$sth->execute;
		#
		#	Заголовок данных
		my	@data = ([map
			{
				Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
			}
			($FORM_checkbox{$name}, 'Информация')]);
		#
		#	цикл по выбранным записям
		while (my $row = $sth->fetchrow_hashref)
		{
			push @data, [$row->{name}, $row->{info} || ''];
		}
		#
		#	добавить данные запроса
		push @request, \@data;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	цикл по группам строк ввода (input)
	foreach my $name ( keys %FORM_number )
	{
		#	хэш строк ввода (id, значение)
		my	%value = map { $_->{id} => $_->{val} } @{ $query->{$name} };
		#
		#	ID строк ввода html-формы
		my	$id = join(',', sort keys %value);
		#
		#	SQL-запрос
		$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$name"
			WHERE id IN ($id)
			ORDER BY "name_lc"
		@);
		$sth->execute;
		#
		#	Заголовок данных
		my	@data = ([map
			{
				Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
			}
			($FORM_checkbox{$name}, 'Результат', 'Информация')]);
		#
		#	цикл по выбранным записям
		while (my $row = $sth->fetchrow_hashref)
		{
			push @probe, [$row->{name}, $value{$row->{id}}, $row->{info} || ''];
		}
		#
		#	добавить данные запроса
		push @request, \@data;	
	}
	
	
=pod
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
			[$row->{name}, $row->{info} || ''];
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
=cut
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
		[$row->{name}, $probe{$row->{id}}, $row->{info} || ''];
	}
#	pdf_table(\@preparation);
	
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
sub report
{
	#	ссылка на хэш-данные запроса
	my	$query = shift @_;
	#-------------------------------------------------------------------------
	#	CGI-запрос (ссылка на хэш)
	my	$cgi_query = {};
	#
	#	цикл по группам флажков (checkbox)
	foreach my $name ( keys %FORM_checkbox )
	{
		#	цикл по ID флажков
		foreach my $id (@{ $query->{$name} })
		{
			$cgi_query->{"$name#$id"} = $id;
		}
	}
	#
	#	цикл по группам строк ввода (input)
	foreach my $name ( keys %FORM_number )
	{
		#	цикл по строкам ввода
		foreach my $input (@{ $query->{$name} })
		{
			$cgi_query->{"$name#".$input->{id}} = $input->{val};
		}
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	Открыть базу данных
	#
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die $DBI::errstr;
	#
	#	Ссылка на объект
	my	$report = Report->new( $dbh );
	#
	#	Разрешенные препараты (user.pl)
	my	$list_prescription = $report->approved_preparation( $cgi_query );
	#
	#	Количество рекомендаций
	my	$sth = $dbh->prepare(qq
		@
			SELECT count(*) AS rows FROM "$list_prescription"
		@);
		$sth->execute();
	#
	#	нет рекомендаций?
	if ( $sth->fetchrow_hashref()->{rows} == 0 )
	{
		return 'Для заданных условий поиска нет рекомендуемых препаратов';
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	Список препаратов
	#	https://www.sqlitetutorial.net/sqlite-count-function/
	#
	$sth = $dbh->prepare(qq
	@
		SELECT
			ROW_NUMBER() OVER (
				PARTITION BY "preparation_name"
				ORDER BY "preparation_name", "probe_name"
			) AS num,
			COUNT("preparation_name") OVER (
				PARTITION BY "preparation_name"
			) AS rowspan,
			"preparation_name",
			"preparation_info",
			"indication_info",
			"indication_memo",
			"probe_name",
			"probe_value",
			"probe_min",
			"probe_max",
			"prescription_instruction"
		FROM $list_prescription
	@);
	$sth->execute();
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	цикл по списку препаратов
	my	$order = 1;
	my	$text = '';
	while (my $row = $sth->fetchrow_hashref)
	{
		#	первая строка группы записей
		if ($row->{num} == 1)
		{
			#	заголовок группы записей
			$text .= sprintf qq
			@
				***
				%d) Препарат: %s
				Информация: %s
				***
				Клинические показания: %s
				С осторожностью: %s
				---
			@,
			$order++,
			$row->{'preparation_name'},
			$row->{'preparation_info'},
			Utils::break_line($row->{'indication_info'}),
			Utils::break_line($row->{'indication_memo'});
		}
		#	данные группы записей
		$text .= sprintf qq
		@
			Лабораторное исследование: %s
			Значение показателя:
			от: %s
			факт: %s
			до: %s
			Рекомендации по применению: %s
		@,
		$row->{'probe_name'},
		$row->{'probe_min'},
		$row->{'probe_value'},
		$row->{'probe_max'},
		(
			defined $row->{'prescription_instruction'}
				? Utils::break_line($row->{'prescription_instruction'})
				: ''
		);
	}
	#
	#	закрыть базу данных
	$dbh->disconnect
		or warn $dbh->errstr;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return
	{
		order => $order,
		cgi_query => $cgi_query,
		text => Encode::encode('windows-1251', Encode::decode('UTF-8', $text)),
	};
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__


$VAR1 = {
          'action' => 'report',
          'offset-comorbidity' => '0',
          'offset-deviation' => '0',
          'offset-preparation' => '0',
          'offset-report' => '0',
          'offset-rheumatology' => '0',
          'offset-status' => '0',
          'probe#1' => '',
          'probe#2' => '',
          'probe#39' => ''
          'probe#4' => '',
          'probe#40' => '',
          'probe#41' => '',
          'probe#42' => '',
          'probe#5' => '',
          'probe#6' => '',
          'probe#7' => '',
          'rheumatology#2' => '2',
          'rheumatology#5' => '5',
        };