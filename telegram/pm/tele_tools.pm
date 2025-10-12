#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod

	����������� ��� ������ � Telegram Bot

=cut
package Tele_Tools {
#
#	������������� ��������
#	https://perldoc.perl.org/Encode
use Encode qw(decode);
#
#	JSON (JavaScript Object Notation) �����������/�������������
#	https://metacpan.org/pod/JSON
use	JSON qw(encode_json);
#
#	��������� ����� ������� �� ��������� ��� �������
#	https://perldoc.perl.org/Exporter
use Exporter 'import';
#
#	������ �������� ��� ��������
our	@EXPORT_OK = qw(trim decode_utf8 decode_win time_stamp);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#	������ �������������
my	$user;
#
#	���� ������
my	$dbh;
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Logger
	---
	logger($message, $result);
	
		%message	- ��������� (���)
		%result		- ��������� ��������� ��������� (���)
=cut
sub logger
{
	#	��������� (������ �� ���)
	my	$message = shift @_;
	#	��������� ��������� ���������
	my	$result = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	telegram_id ������������
	my	$telegram_id = $message->{chat}->{id};
	#
	#	������ � ���� ������
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
	������� � ������ ������� � ����������� ������� 
	---
	$trim_string = trim($string);
	
=cut
sub trim
{
    my	$string = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������
	return '' if !defined($string);
	#
	#	������� ������� �������
    $string =~ s/^\s+//;
	#
	#	������� ����������� �������
    $string =~ s/\s+$//;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� ������
    return $string;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������������ �������� ���
	---
	$hash_ref = decode_utf8( \%hash );
	
		%hash	- ��� ������ ���� ������
=cut
sub decode_utf8
{
    my	$hash_ref = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� �� ������ ����
	foreach (keys %{ $hash_ref })
	{
		#	������������ ������ �� "UTF-8"
		$hash_ref->{$_} = Encode::decode('UTF-8', trim($hash_ref->{$_}));
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
	return $hash_ref;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������������ ������
	---
	$decode_string = decode_windows($string);
	
		$string	- ������
=cut
sub decode_win
{
    my	$string = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������������� ������
	return Encode::decode('windows-1251', trim($string));
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����� �������: https://perldoc.perl.org/functions/localtime
	---
	"DD-MM-YYYY hh:mm:ss" = time_stamp();
	
=cut
sub time_stamp
{
	#	������� �����
	my	($sec, $min, $hour, $mday, $mon, $year) = localtime;
	#
	#	����� ������� (DD-MM-YYYY hh:mm:ss)
	#
	return sprintf("%02d-%02d-%04d %02d:%02d:%02d",
			$mday, $mon+1, $year+1900, $hour, $min, $sec);
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
