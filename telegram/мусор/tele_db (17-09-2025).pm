=pod

	������ � ����� ������ 'med' SQLite

=cut
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#	JSON (JavaScript Object Notation) �����������/�������������
#	https://metacpan.org/pod/JSON
use	JSON;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	���� ������: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	���� ���� ������
my	$db_file = 'C:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
#my	$db_file = 'D:\Git-Hub\viacheslav-simakov.github.io\med\med.db';
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	����� ��������� (�������)
#	'.' = ������� �����!
use lib ('C:\Apache24\web\cgi-bin\pm', 'D:\GIT-HUB\apache\web\cgi-bin\pm');
#
#	������������ ������� �� ���� ������
#
use Report();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	��������� SQL-�������� � ���� ������ SQLite
#
package tele_db {
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod
	���������� �������� � ���� ������
	---
	request(\%query);

		%query	- ������ CGI-�������

=cut
sub request {
	#	������ �� ���-������ �������
	my	$query = shift @_;
	#-------------------------------------------------------------------------
	my	($dbh, $sth);
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
	my	@rheumatology = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('�������� �����������', '����������')]);
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
	my	@comorbidity = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('������������� �����������', '����������')]);
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @comorbidity,
			[$row->{name}, '', $row->{info} || ''];
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
	my	@status = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('������������� ���������', '����������')]);
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @status,
			[$row->{name}, '', $row->{info} || ''];
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
	my	@manual = ([map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('������������ ����������', '����������')]);
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @manual,
			[$row->{name}, '', $row->{info} || ''];
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
	my	@preparation = ([ map {Encode::decode('windows-1251', $_)}
		('���������', '����������')] );
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @preparation, [ map {Encode::decode('UTF-8', $_)}
			($row->{name}, $row->{info} || '') ];
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
	my	@probe = ([Encode::decode('UTF-8', '������������ ������������'),'','']);
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		push @probe,
		[$row->{name}, $probe{$row->{id}}, $row->{info} || ''];
	}
#	pdf_table(\@preparation);
	
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
sub report
{
	#	������ �� ���-������ �������
	my	$query = shift @_;
	#-------------------------------------------------------------------------
	#	"�������� �����������"
	my	%rheumatology = map
		{
			sprintf('rheumatology#%d', $_) => $_
		}
		@{ $query->{rheumatology} };
	#
	#	"������������� �����������"
	my	%comorbidity = map
		{
			sprintf('comorbidity#%d', $_) => $_
		}
		@{ $query->{comorbidity} };
	#
	#	"������������� ���������"
	my	%status = map
		{
			sprintf('status#%d', $_) => $_
		}
		@{ $query->{status} };
	#
	#	"������������ ����������"
	my	%manual = map
		{
			sprintf('manual#%d', $_) => $_
		}
		@{ $query->{manual} };
	#
	#	"���������"
	my	%preparation = map
		{
			sprintf('preparation#%d', $_) => $_
		}
		@{ $query->{preparation} };
	#
	#	"������������ ������������"
	my	%probe = map
		{
			sprintf('probe#%d', $_->{id}) => $_->{val}
		}
		@{ $query->{probe} };
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	CGI-������
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
	#	������� ���� ������
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die "$DBI::errstr\n\n\t";
	#
	#	������ �� ������
	my	$report = Report->new( $dbh );
	#
	#	����������� ���������
	my	$list_prescription = $report->approved_preparation( $cgi_query );
	#
	#	���������� ������������
	my	$sth = $dbh->prepare(qq
		@
			SELECT count(*) AS rows FROM "$list_prescription"
		@);
		$sth->execute();
	#
	#	��� ������������?
	if ( $sth->fetchrow_hashref()->{rows} == 0 )
	{
		return "<tr><td colspan=7>��� �������� ������� ������ ��� ������������� ����������</td></tr>";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	������ ����������
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
	#	���� �� ������ ����������
	my	$order = 0;
	while (my $row = $sth->fetchrow_hashref)
	{
		$order++;
	}
	#
	#	������� ���� ������
	$dbh->disconnect
		or warn $dbh->errstr;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
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