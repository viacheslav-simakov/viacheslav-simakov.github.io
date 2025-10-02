=pod

	������ � ����� ������ 'bot' SQLite

=cut
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#	������������ 'warn' � 'die' ��� �������
#	https://perldoc.perl.org/Carp
use Carp();
#	������������� ��������
#	https://perldoc.perl.org/Encode
use Encode;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	���� ������: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	���� ���� ������
my	$db_file = 'C:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
	$db_file = 'D:\Git-Hub\viacheslav-simakov.github.io\med\med.db' unless (-f $db_file);
#
#	���� ���� ������ �� ������
	Carp::confess "Cannot find file database" unless (-f $db_file);
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	��������� SQL-�������� � ���� ������ SQLite
#
package Tele_User {
#
#	������ ������
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
	�����������
	---
	$obj = Tele_User->new( $user_id );

		$user_id	- ID ������������ ����
=cut
sub new {
	#	�������� ������
	my	$class = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� ���� ������
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die $DBI::errstr;
	#
	#	����� �� �����
	printf "Connect to database '$db_file'\n";
	#
	#	������ �� ������
	my	$self =
		{
			-dbh		=> $dbh,		# ��������� ���� ������
			-user_id	=> shift @_,	# ID ������������ ����
		};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������ � ���� "class"
	return bless $self, $class;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����������
	---
=cut
sub DESTROY
{
	#	������ �� ������
	my	$self = shift @_;
	#-------------------------------------------------------------------------
	#	������� ���� ������
	$self->{-dbh}->disconnect or warn $self->{-dbh}->errstr;
	#
	#	����� �� �����
	print STDERR "Disconnect from database of user's\n";
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	���������� �������� � ���� ������
	---
	user();

		%query	- ������ CGI-�������

=cut
sub user {
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	��������� ���� ������/������� ���� ������
	#
	my	$dbh = $self->{-dbh};
	#
	#	���������� ������������
	my	$sth = $dbh->prepare(qq
		@
			SELECT count(*) AS rows FROM "user"
		@);
		$sth->execute();
	#
	#	��� ������������?
	if ( $sth->fetchrow_hashref()->{rows} == 0 )
	{
		return Encode::decode('windows-1251',
			'��� �������� ������� ������ ��� ������������� ����������');
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ ����������
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
	#	������ ����������
	my	@preparation = ();
	#
	#	���� �� ������ ����������
	my	$order = 1;
	while (my $row = $sth->fetchrow_hashref)
	{
		#	������������� �� "UTF-8"
		decode_utf8($row);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
	return
	{
		cgi_query		=> $cgi_query,
	};
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__