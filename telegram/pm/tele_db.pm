=pod

	������ � ����� ������ 'med' SQLite

=cut
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#	��������� ��������� ������ Perl, ���������� ��� ��� ������
#	https://metacpan.org/pod/Data::Dumper
use	Data::Dumper;
#	������������� ��������
#	https://perldoc.perl.org/Encode
use Encode;# qw(decode encode);
#	JSON (JavaScript Object Notation) �����������/�������������
#	https://metacpan.org/pod/JSON
use	JSON;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	���� ������: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	���� ���� ������
#my	$db_file = 'C:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
my	$db_file = 'D:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
#
#	������� ���� ������
my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
		or die "$DBI::errstr\n\n\t";
#	
#	��������� �������
my	$sth;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	��������� SQL-�������� � ���� ������ SQLite
#
package tele_db {
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod
	���������� �������� � ���� ������
	---
	db_request($dbh , \%query);

		$dbh	- ��������� ���� ������
		%query	- ������ CGI-�������

=cut
sub request {
	#	������ �� ���-������ �������
	my	$query = shift @_;
	#-------------------------------------------------------------------------
	#	"�������� �����������"
	my	$id_rheumatology = join(',', @{ $query->{rheumatology} });
	#
	#	SQL-������
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "rheumatology"
		WHERE id IN ($id_rheumatology)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	������
	my	@rheumatology = ('�������� �����������');
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @rheumatology,
			[$row->{name}, $row->{info} || '��� ����������'];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"������������� �����������"
	my	$id_comorbidity = join(',', @{ $query->{comorbidity} });
	#
	#	SQL-������
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "comorbidity"
		WHERE id IN ($id_comorbidity)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	������
	my	@comorbidity = ('������������� �����������');
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @comorbidity,
			[$row->{name}, $row->{info} || '��� ����������'];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"������������� ���������"
	my	$id_status = join(',', @{ $query->{status} });
	#
	#	SQL-������
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "status"
		WHERE id IN ($id_status)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	������
	my	@status = ('������������� ���������');
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @status,
			[$row->{name}, $row->{info} || '��� ����������'];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"������������ ����������"
	my	$id_manual = join(',', @{ $query->{manual} });
	#
	#	SQL-������
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "probe-manual"
		WHERE id IN ($id_manual)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	������
	my	@manual = ('������������ ����������');
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @manual,
			[$row->{name}, $row->{info} || '��� ����������'];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"���������"
	my	$id_preparation = join(',', @{ $query->{preparation} });
	#
	#	SQL-������
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "preparation"
		WHERE id IN ($id_preparation)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	������
	my	@preparation = ('���������');
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @preparation,
			[$row->{name}, $row->{info} || '��� ����������'];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	"������������ ������������"
	my	%probe = map { $_->{id} => $_->{val} } @{ $query->{probe} };
	#
	#	id ������� �������
	my	$id_probe = join(',', sort keys %probe);
	#
	#	SQL-������
	$sth = $dbh->prepare(qq
	@
		SELECT id,name,info FROM "probe"
		WHERE id IN ($id_probe)
		ORDER BY "name_lc"
	@);
	$sth->execute;
	#
	#	������
	my	@probe = ('������������ ������������');
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @probe,
		[$row->{name}, $probe{$row->{id}}, $row->{info} || '��� ����������'];
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
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