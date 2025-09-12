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
#	Декодирование символов
#	https://perldoc.perl.org/Encode
use Encode;# qw(decode encode);
#	JSON (JavaScript Object Notation) кодирование/декодирование
#	https://metacpan.org/pod/JSON
use	JSON;
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
	my	@rheumatology = ('Основное заболевание');
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
	my	@comorbidity = ('Сопутствующие заболевания');
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @comorbidity,
			[$row->{name}, $row->{info} || 'нет информации'];
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
	my	@status = ('Сопутствующие состояния');
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @status,
			[$row->{name}, $row->{info} || 'нет информации'];
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
	my	@manual = ('Лабораторные показатели');
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @manual,
			[$row->{name}, $row->{info} || 'нет информации'];
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
	my	@preparation = ('Препараты');
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @preparation,
			[$row->{name}, $row->{info} || 'нет информации'];
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
	my	@probe = ('Лабораторные исследования');
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		push @probe,
		[$row->{name}, $probe{$row->{id}}, $row->{info} || 'нет информации'];
	}
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

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__