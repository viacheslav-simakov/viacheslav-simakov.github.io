=pod

	Работа с базой данных 'bot' SQLite

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
#	Декодирование символов
#	https://perldoc.perl.org/Encode
use Encode;
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
#	Обработка SQL-запросов к базе данных SQLite
#
package Tele_User {
#
#	Данные модуля
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
		$hash_ref->{$_} = Encode::decode('UTF-8', trim($hash_ref->{$_}));
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return $hash_ref;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Конструктор
	---
	$obj = Tele_User->new( $user_id );

		$user_id	- ID пользователя Бота
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
			-dbh		=> $dbh,		# указатель базы данных
			-user_id	=> shift @_,	# ID пользователя Бота
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
	print STDERR "Disconnect from database of user's\n";
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Обработчик запросов к базе данных
	---
	user();

		%query	- данные CGI-запроса

=cut
sub user {
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	Указатель базы данных/Открыть базу данных
	#
	my	$dbh = $self->{-dbh};
	#
	#	Количество рекомендаций
	my	$sth = $dbh->prepare(qq
		@
			SELECT count(*) AS rows FROM "user"
		@);
		$sth->execute();
	#
	#	нет рекомендаций?
	if ( $sth->fetchrow_hashref()->{rows} == 0 )
	{
		return Encode::decode('windows-1251',
			'Для заданных условий поиска нет рекомендуемых препаратов');
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
	#	цикл по списку препаратов
	my	$order = 1;
	while (my $row = $sth->fetchrow_hashref)
	{
		#	Декодирование из "UTF-8"
		decode_utf8($row);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return
	{
		cgi_query		=> $cgi_query,
	};
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__