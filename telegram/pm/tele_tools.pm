#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod

	Инструменты для работы с Telegram Bot

=cut
package Tele_Tools {
#
#	Декодирование символов
#	https://perldoc.perl.org/Encode
use Encode qw(decode);
#
#	JSON (JavaScript Object Notation) кодирование/декодирование
#	https://metacpan.org/pod/JSON
use	JSON qw(encode_json);
#
#	Реализует метод импорта по умолчанию для модулей
#	https://perldoc.perl.org/Exporter
use Exporter 'import';
#
#	Список символов для экспорта
our	@EXPORT_OK = qw(trim decode_utf8 decode_win time_stamp break_line);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#	Список пользователей
my	$user;
#
#	База данных
my	$dbh;
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Logger
	---
	logger($message, $result);
	
		%message	- сообщение (хэш)
		%result		- результат обработки сообщения (хэш)
=cut
sub logger
{
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#	результат обработки сообщения
	my	$result = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	telegram_id пользователя
	my	$telegram_id = $message->{chat}->{id};
	#
	#	Запись в базу данных
	my	$sth = $dbh->prepare(qq
		@
			INSERT INTO "logger" (telegram_id, message, result)
			VALUES (?, ?, ?)
		@);
		$sth->execute(
			$telegram_id,
			encode_json($message),
			encode_json($result)
		)
		or Carp::carp $DBI::errstr;
}
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
		$hash_ref->{$_} = Encode::decode('UTF-8', trim($hash_ref->{$_}));
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return $hash_ref;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Декодировать 'windows-1251'
	---
	$decode_data = decode_win($data);
	
		$data	- данные для декодирования
=cut
sub decode_win
{
	#	данные для декодирования
    my	$data = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	тип данных: https://perldoc.perl.org/functions/ref
	if (ref($data) eq '')
	{
		#	строка
		return Encode::decode('windows-1251', trim($data));
	}
	elsif (ref($data) eq 'ARRAY')
	{
		#	ссылка на массив
		return
		[
			map { Encode::decode('windows-1251', trim($_)) } @{ $data }
		];
	}
	else
	{
		Carp::carp "Неверный параметр функции decode_win('$data')";
	}
	#	декодированная строка
#	return Encode::decode('windows-1251', trim($string));
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Метка времени: https://perldoc.perl.org/functions/localtime
	---
	"DD-MM-YYYY hh:mm:ss" = time_stamp();
	
=cut
sub time_stamp
{
	#	Местное время
	my	($sec, $min, $hour, $mday, $mon, $year) = localtime;
	#
	#	Метка времени (DD-MM-YYYY hh:mm:ss)
	#
	return sprintf("%02d-%02d-%04d %02d:%02d:%02d",
			$mday, $mon+1, $year+1900, $hour, $min, $sec);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Переводы строк в HTML
	---
	break_line($string);
	
		$string	- строка (SCALAR)

=cut
sub break_line {
	#	передаваемая строка
	my	$s = shift @_;
	#	перевод строк в HTML
		$s =~ s/(\n)+/<br>/g;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	текст с переводом строк
	return $s;
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
