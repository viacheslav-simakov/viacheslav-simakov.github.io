#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#	Альтернатива 'warn' и 'die' для модулей
#	https://perldoc.perl.org/Carp
use Carp();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod

	Работа с базой данных 'med.db' SQLite

=cut
package Tele_DB {
#
#	БАЗА ДАННЫХ: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	папки библиотек (модулей)
#	'.' = текущая папка!
#use lib ('C:\Apache24\web\cgi-bin\pm', 'D:\GIT-HUB\apache\web\cgi-bin\pm');
use lib ('C:\Apache24\web\cgi-bin\pm');
#
#	Формирование ОТЧЕТОВ из базы данных
#
use Report();
#
#	Утилиты для работы
use Tele_Tools qw(decode_utf8 decode_win);
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	ДАННЫЕ МОДУЛЯ
#
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
#	флажки HTML-формы
my	%FORM_checkbox =
(
	rheumatology	=> 'Основное заболевание',
	comorbidity		=> 'Сопутствующие заболевания',
	status			=> 'Сопутствующие состояния',
	manual			=> 'Лабораторные показатели',
	preparation		=> 'Препараты',
);
#
#	строки ввода HTML-формы
my	%FORM_number =
(
	probe			=> 'Лабораторные исследования',
);
=pod
#
#	Заголовки строк
my	@row_title = map { decode_win($_) } (
		'Препарат',
		'Информация',
		'Клинические показания',
		'С осторожностью',
	);
=cut
#
#	Заголовки строк
my	@row_title = @{ decode_win([
		'Препарат',
		'Информация',
		'Клинические показания',
		'С осторожностью',])
	};
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Конструктор
	---
	$obj = Tele_DB->new($query, $db_file);

		%query		- данные запроса
		$db_file	- путь файла базы данных
=cut
sub new {
	#	название класса
	my	$class = shift @_;
	#	запрос пользователя
	my	$query = shift @_;
	#	файл базы данных
	my	$db_file = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка файла
	unless (-f $db_file)
	{
		Carp::confess "Файл базы данных '$db_file' не найден\n";
	}
	#	открыть базу данных
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or Carp::confess $DBI::errstr;
	#
	#	вывод на экран
	printf STDERR "Connect to database '%s'\n", $dbh->sqlite_db_filename;
	#
	#	ссылка на объект
	my	$self =
		{
			-dbh	=> $dbh,	# указатель базы данных
			-query	=> $query,	# запрос (ссылка на хэш)
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
	#	Файл базы данных
	my	$db_filename = $self->{-dbh}->sqlite_db_filename;
	#
	#	закрыть базу данных
	$self->{-dbh}->disconnect or Carp::carp $DBI::errstr;
	#
	#	вывод на экран
	printf STDERR "Disconnect from database '%s'\n", $db_filename;
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
	#
	#	Группы флажков (checkbox)
	#
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
=pod
		#
		#	Заголовок данных
		my	@data = ([map { decode_win($_) }
			($FORM_checkbox{$name}, 'Информация')]);
=cut
		#
		#	Заголовок данных
		my	@data =
			(
				decode_win([$FORM_checkbox{$name}, 'Информация'])
			);
		#
		#	цикл по выбранным записям
		while (my $row = $sth->fetchrow_hashref)
		{
			#	Декодирование из "UTF-8"
			decode_utf8($row);
			#
			#	Добавить в конец списка
			push @data, [$row->{name}, $row->{info}];
		}
		#
		#	добавить данные запроса
		$req->{$name} = \@data;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	Группы строк ввода (input)
	#
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
=pod
		#
		#	Заголовок данных
		my	@data = ([map {	decode_win($_) }
			($FORM_number{$name}, 'Результат', 'Информация')]);
=cut
		#
		#	Заголовок данных
		my	@data =
			(
				decode_win([$FORM_number{$name}, 'Результат', 'Информация'])
			);
		#
		#	цикл по выбранным записям
		while (my $row = $sth->fetchrow_hashref)
		{
			#	Декодирование из "UTF-8"
			decode_utf8($row);
			#
			#	Добавить в конец списка
			push @data, [$row->{name}, $value{$row->{id}}, $row->{info}];
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
	#
	return undef if $sth->fetchrow_hashref()->{rows} == 0;
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
		#	Декодирование из "UTF-8"
		decode_utf8($row);
		#
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
				[$row_title[2], $row->{'indication_info'}],
				[$row_title[3], $row->{'indication_memo'}],
			];
		}
		#	нет данных лабораторных исследований
		next if ($row->{'probe_name'} eq '');
		#
		#	Данные исследований
		push @{ $probe[$#preparation] },
		[
			$row->{'probe_name'},
			$row->{'probe_min'},
			$row->{'probe_value'},
			$row->{'probe_max'},
			$row->{'prescription_instruction'},
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