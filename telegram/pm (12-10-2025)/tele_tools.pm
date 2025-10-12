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
use Encode ('decode');
#
#	Реализует метод импорта по умолчанию для модулей
#	https://perldoc.perl.org/Exporter
use Exporter 'import';
#
#	Список символов для экспорта
our	@EXPORT_OK = qw(trim decode_utf8 decode_win time_stamp);
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
	Декодировать строку
	---
	$decode_string = decode_windows($string);
	
		$string	- строка
=cut
sub decode_win
{
    my	$string = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	декодированная строка
	return Encode::decode('windows-1251', trim($string));
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
			$mday, $mon+1, $year+1900,
			$hour, $min, $sec);
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
