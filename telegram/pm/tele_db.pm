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
#	�������
use Utils();
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
#
#	������ ������
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	������ html-�����
my	%FORM_checkbox =
(
	rheumatology	=> '�������� �����������',
	comorbidity		=> '������������� �����������',
	status			=> '������������� ���������',
	manual			=> '������������ ����������',
	preparation		=> '���������',
);
#
#	������ ����� html-�����
my	%FORM_number =
(
	probe			=> '������������ ������������',
);
=pod
foreach (keys %FORM_checkbox)
{
	$FORM_checkbox{$_} = Encode::encode('UTF-8',
		Encode::decode('windows-1251',
			$FORM_checkbox{$_}));
}
=cut
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
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
	#
	#	������� ���� ������
	#
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die $DBI::errstr;
	#
	#	������ ������� (������, ������ �����)
	my	(@req_checkbox, @req_number);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� �� ������� ������� (checkbox)
	foreach my $name (keys %FORM_checkbox)
	{
		#	ID ������� html-�����
		my	$id = join(',', @{ $query->{$name} });
		#
		#	SQL-������
		my	$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$name"
			WHERE id IN ($id)
			ORDER BY "name_lc"
		@);
		$sth->execute;
		#
		#	��������� ������
		my	@data = ([map
			{
				Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
			}
			($FORM_checkbox{$name}, '����������')]);
		#
		#	���� �� ��������� �������
		while (my $row = $sth->fetchrow_hashref)
		{
			push @data, [$row->{name}, $row->{info} || ''];
		}
		#
		#	�������� ������ �������
		push @req_checkbox, \@data;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� �� ������� ����� ����� (input)
	foreach my $name ( keys %FORM_number )
	{
		#	��� ����� ����� (id, ��������)
		my	%value = map { $_->{id} => $_->{val} } @{ $query->{$name} };
		#
		#	ID ����� ����� html-�����
		my	$id = join(',', sort keys %value);
		#
		#	SQL-������
		my	$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$name"
			WHERE id IN ($id)
			ORDER BY "name_lc"
		@);
		$sth->execute;
		#
		#	��������� ������
		my	@data = ([map
			{
				Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
			}
			($FORM_checkbox{$name}, '���������', '����������')]);
		#
		#	���� �� ��������� �������
		while (my $row = $sth->fetchrow_hashref)
		{
			push @data, [$row->{name}, $value{$row->{id}}, $row->{info} || ''];
		}
		#
		#	�������� ������ �������
		push @req_number, \@data;	
	}
	#
	#	������� ���� ������
	$dbh->disconnect or warn $dbh->errstr;
#	pdf_table(\@preparation);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
	return
	{
		-checkbox	=> \@req_checkbox,
		-number		=> \@req_number,
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
sub report
{
	#	������ �� ���-������ �������
	my	$query = shift @_;
	#-------------------------------------------------------------------------
	#	CGI-������ (������ �� ���)
	my	$cgi_query = {};
	#
	#	���� �� ������� ������� (checkbox)
	foreach my $name ( keys %FORM_checkbox )
	{
		#	���� �� ID �������
		foreach my $id (@{ $query->{$name} })
		{
			$cgi_query->{"$name#$id"} = $id;
		}
	}
	#
	#	���� �� ������� ����� ����� (input)
	foreach my $name ( keys %FORM_number )
	{
		#	���� �� ������� �����
		foreach my $input (@{ $query->{$name} })
		{
			$cgi_query->{"$name#".$input->{id}} = $input->{val};
		}
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	������� ���� ������
	#
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die $DBI::errstr;
	#
	#	������ �� ������
	my	$report = Report->new( $dbh );
	#
	#	����������� ��������� (user.pl)
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
		return '��� �������� ������� ������ ��� ������������� ����������';
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
	my	$order = 1;
	my	$text = '';
	while (my $row = $sth->fetchrow_hashref)
	{
		#	������ ������ ������ �������
		if ($row->{num} == 1)
		{
			#	��������� ������ �������
			$text .= sprintf qq
			@
				***
				%d) ��������: %s
				����������: %s
				***
				����������� ���������: %s
				� �������������: %s
				---
			@,
			$order++,
			$row->{'preparation_name'},
			$row->{'preparation_info'},
			Utils::break_line($row->{'indication_info'}),
			Utils::break_line($row->{'indication_memo'});
		}
		#	������ ������ �������
		$text .= sprintf qq
		@
			������������ ������������: %s
			�������� ����������:
			��: %s
			����: %s
			��: %s
			������������ �� ����������: %s
		@,
		$row->{'probe_name'},
		$row->{'probe_min'},
		$row->{'probe_value'},
		$row->{'probe_max'},
		(
			defined $row->{'prescription_instruction'}
				? Utils::break_line($row->{'prescription_instruction'})
				: ''
		);
	}
	#
	#	������� ���� ������
	$dbh->disconnect or warn $dbh->errstr;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return
	{
		order => $order,
		cgi_query => $cgi_query,
		text => Encode::encode('windows-1251', Encode::decode('UTF-8', $text)),
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