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
	$db_file = 'D:\Git-Hub\viacheslav-simakov.github.io\med\med.db' unless (-f $db_file);
#
#	���� ���� ������ �� ������
	die "Cannot find file data base" unless (-f $db_file);
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
#
#	������ ������
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#	���������� ������ ���� ������
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
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�����������
	---
	$report = tele_db->new( $query );

		%query	- ������ �������
=cut
sub new {
	#	�������� ������
	my	$class = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or die $DBI::errstr;
	#
	#	������ �� ������
	my	$self =
		{
			-dbh	=> $dbh,		# ��������� ���� ������
			-query	=> shift @_,	# ������ (������ �� ���)
		};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������ � ���� __PACKAGE__
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
	print STDERR "disconnect from data base\n";
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	���������� �������� � ���� ������
	---
	request(\%query);

		%query	- ������ CGI-�������

=cut
sub request {
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���-������ �������
	my	$query = $self->{-query};
	#
	#	������ ������� (������, ������ �����)
	my	$req;
	#
	#	��������� ���� ������/������� ���� ������
	my	$dbh = $self->{-dbh};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� �� ������� ������� (checkbox)
	foreach my $name (keys %FORM_checkbox)
	{
		#	ID ������� html-�����
		my	$id = join(',', @{ $query->{$name} });
		#
		#	������� ���� ������
		my	$table = $TABLE{$name};
		#
		#	SQL-������
		my	$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$table"
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
		$req->{$name} = \@data;
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
		#	������� ���� ������
		my	$table = $TABLE{$name};
		#
		#	SQL-������
		my	$sth = $dbh->prepare(qq
		@
			SELECT id,name,info FROM "$table"
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
			($FORM_number{$name}, '���������', '����������')]);
		#
		#	���� �� ��������� �������
		while (my $row = $sth->fetchrow_hashref)
		{
			push @data, [$row->{name}, $value{$row->{id}}, $row->{info} || ''];
		}
		#
		#	�������� ������ �������
		$req->{$name} = \@data;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
	return $req;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
sub report
{
	#	������ �� ������
	my	$self = shift @_;
	#-------------------------------------------------------------------------
	#	������ �������
	my	$query = $self->{-query};
	#
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
	#	��������� ���� ������/������� ���� ������
	#
	my	$dbh = $self->{-dbh};
	#
	#	������ �� ������ (�����)
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
%d) preparation-name: %s
	preparation-info: %s
***
indication_info: %s
indication_memo: %s
---
@,
			$order++,
			$row->{'preparation_name'},
			$row->{'preparation_info'},
			Utils::break_line($row->{'indication_info'} || ''),
			Utils::break_line($row->{'indication_memo'} || '');
		}
		next if
		(
			!defined($row->{'probe_name'})					&& 
			!defined($row->{'probe_min'})					&&
			!defined($row->{'probe_value'})					&&
			!defined($row->{'probe_max'})					&&
			!defined($row->{'prescription_instruction'})
		);
		#	������ ������ �������
		$text .= sprintf qq
@
	probe_name: %s
	min: %s
	value: %s
	max: %s
	prescription_instruction: %s
@,
		$row->{'probe_name'} 	|| '',
		$row->{'probe_min'}		|| '',
		$row->{'probe_value'}	|| '',
		$row->{'probe_max'}		|| '',
		Utils::break_line($row->{'prescription_instruction'} || '');
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
	return
	{
		order => $order,
		cgi_query => $cgi_query,
		text => $text,
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