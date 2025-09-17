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
#	Формирование ОТЧЕТОВ из базы данных
#
use Report();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Обработка SQL-запросов к базе данных SQLite
#
package tele_db {
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
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
	my	($dbh, $sth);
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
	#	"Основное заболевание"
	my	%rheumatology = map
		{
			sprintf('rheumatology#%d', $_) => $_
		}
		@{ $query->{rheumatology} };
	#
	#	"Сопутствующие заболевания"
	my	%comorbidity = map
		{
			sprintf('comorbidity#%d', $_) => $_
		}
		@{ $query->{comorbidity} };
	#
	#	"Сопутствующие состояния"
	my	%status = map
		{
			sprintf('status#%d', $_) => $_
		}
		@{ $query->{status} };
	#
	#	"Лабораторные показатели"
	my	%manual = map
		{
			sprintf('manual#%d', $_) => $_
		}
		@{ $query->{manual} };
	#
	#	"Препараты"
	my	%preparation = map
		{
			sprintf('preparation#%d', $_) => $_
		}
		@{ $query->{preparation} };
	#
	#	"Лабораторные исследования"
	my	%probe = map
		{
			sprintf('probe#%d', $_->{id}) => $_->{val}
		}
		@{ $query->{probe} };
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	CGI-запрос
	#
	my	$cgi_query =
		{
			%rheumatology,
			%comorbidity,
			%status,
			%manual,
			%preparation,
			%probe,
		};
	#
	#	открыть базу данных
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die "$DBI::errstr\n\n\t";
	#
	#	ссылка на объект
	my	$report = Report->new( $dbh );
	#
	#	Разрешенные препараты
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
		return "<tr><td colspan=7>Для заданных условий поиска нет рекомендуемых препаратов</td></tr>";
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
	my	$order = 0;
	while (my $row = $sth->fetchrow_hashref)
	{
		$order++;
	}
	#
	#	закрыть базу данных
	$dbh->disconnect
		or warn $dbh->errstr;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return {order => $order, cgi_query => $cgi_query};
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