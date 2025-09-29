=pod

	Работа с базой данных 'med' SQLite

=cut
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#	Альтернатива 'warn' и 'die' для модулей
#	https://perldoc.perl.org/Carp
use Carp();
#	JSON (JavaScript Object Notation) кодирование/декодирование
#	https://metacpan.org/pod/JSON
use	JSON;
#	Декодирование символов
#	https://perldoc.perl.org/Encode
use Encode qw(decode);
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	БАЗА ДАННЫХ: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	Файл базы данных
my	$db_file = 'C:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
	$db_file = 'D:\Git-Hub\viacheslav-simakov.github.io\med\med.db' unless (-f $db_file);
#
#	файл база данных не найден
	Carp::confess "Cannot find file database" unless (-f $db_file);
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
package Tele_DB {
#
#	Данные модуля
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#	псевдонимы таблиц базы данных
my	%TABLE =
(
	rheumatology	=> 'rheumatology',
	comorbidity		=> 'comorbidity',
	manual			=> 'probe-manual',
	status			=> 'status',
	preparation		=> 'preparation',
	probe			=> 'probe',
);
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
#
#	Заголовки строк
my	@row_title = map
	{
		Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
	}
	('Препарат', 'Информация', 'Клинические показания', 'С осторожностью');
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Удалить в строке ведущие и завершающие пробелы 
	---
	$trim_string = trim($string);
	
=cut
sub trim
{
    my	$string = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка строки
	return '' if !defined($string);
	#
	#	Удалить ведущие пробелы
    $string =~ s/^\s+//;
	#
	#	Удалить завершающие пробелы
    $string =~ s/\s+$//;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвратить строку
    return $string;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Декодировать значения хэш
	---
	$hash_ref = decode_utf8( \%hash );
	
		%hash	- хэш записи базы данных
=cut
sub decode_utf8
{
    my	$hash_ref = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	цикл по ключам хэша
	foreach (keys %{ $hash_ref })
	{
		#	декодировать строку из "UTF-8"
		$hash_ref->{$_} = decode('UTF-8', trim($hash_ref->{$_}));
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return $hash_ref;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Конструктор
	---
	$obj = Tele_DB->new( $query );

		%query	- данные запроса
=cut
sub new {
	#	название класса
	my	$class = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	открыть базу данных
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die $DBI::errstr;
	#
	#	вывод на экран
	printf "Connect to database '$db_file'\n";
	#
	#	ссылка на объект
	my	$self =
		{
			-dbh	=> $dbh,		# указатель базы данных
			-query	=> shift @_,	# запрос (ссылка на хэш)
		};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	привести ссылку к типу "class"
	return bless $self, $class;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Деструктор
	---
=cut
sub DESTROY
{
	#	ссылка на объект
	my	$self = shift @_;
	#-------------------------------------------------------------------------
	#	закрыть базу данных
	$self->{-dbh}->disconnect or warn $self->{-dbh}->errstr;
	#
	#	вывод на экран
	print STDERR "Disconnect from database\n";
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Обработчик запросов к базе данных
	---
	request(\%query);

		%query	- данные CGI-запроса

=cut
sub request {
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш-данные запроса
	my	$query = $self->{-query};
	#
	#	Данные запроса (флажки, строки ввода)
	my	$req;
	#
	#	Указатель базы данных/Открыть базу данных
	my	$dbh = $self->{-dbh};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	цикл по группам флажков (checkbox)
	foreach my $name (keys %FORM_checkbox)
	{
		#	ID флажков html-формы
		my	$id = join(',', @{ $query->{$name} });
		#
		#	Таблица базы данных
		my	$table = $TABLE{$name};
		#
		#	SQL-запрос
		my	$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$table"
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
			push @data, [$row->{name}, trim($row->{info})];
		}
		#
		#	добавить данные запроса
		$req->{$name} = \@data;
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
		#	Таблица базы данных
		my	$table = $TABLE{$name};
		#
		#	SQL-запрос
		my	$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$table"
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
			($FORM_number{$name}, 'Результат', 'Информация')]);
		#
		#	цикл по выбранным записям
		while (my $row = $sth->fetchrow_hashref)
		{
			push @data, [$row->{name}, $value{$row->{id}}, trim($row->{info})];
		}
		#
		#	добавить данные запроса
		$req->{$name} = \@data;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return $req;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
sub report
{
	#	ссылка на объект
	my	$self = shift @_;
	#-------------------------------------------------------------------------
	#	данные запроса
	my	$query = $self->{-query};
	#
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
	#	Указатель базы данных/Открыть базу данных
	#
	my	$dbh = $self->{-dbh};
	#
	#	Ссылка на объект (отчет)
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
		return Encode::encode('UTF-8', Encode::decode('windows-1251',
			'Для заданных условий поиска нет рекомендуемых препаратов'));
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Список препаратов
	#	https://www.sqlitetutorial.net/sqlite-count-function/
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
	#	данные препаратов
	my	@preparation = ();
	#
	#	данные лабораторных исследований
	my	@probe = ();
	#
	#	цикл по списку препаратов
	my	$order = 1;
	while (my $row = $sth->fetchrow_hashref)
	{
		#	первая строка группы записей
		if ($row->{num} == 1)
		{
			#	Препарат
			push @preparation,
			[
				[	
					sprintf('%d) %s', $order++, $row->{'preparation_name'}),
					$row->{'preparation_info'}
				],
				[$row_title[2], trim($row->{'indication_info'})],
				[$row_title[3], trim($row->{'indication_memo'})],
			];
		}
		#	нет данных лабораторных исследований
		next if
		(
			!defined($row->{'probe_name'})					&& 
			!defined($row->{'probe_min'})					&&
			!defined($row->{'probe_value'})					&&
			!defined($row->{'probe_max'})					&&
			!defined($row->{'prescription_instruction'})
		);
		#	данные группы записей
		push @{ $probe[$#preparation] },
		[
			trim($row->{'probe_name'}),
			trim($row->{'probe_min'}),
			trim($row->{'probe_value'}),
			trim($row->{'probe_max'}),
			trim($row->{'prescription_instruction'})
		];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return
	{
		cgi_query		=> $cgi_query,
		-preparation	=> \@preparation,	# препараты
		-probe			=> \@probe,			# лабораторные исследования
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