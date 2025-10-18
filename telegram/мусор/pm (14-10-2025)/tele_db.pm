#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#	������������ 'warn' � 'die' ��� �������
#	https://perldoc.perl.org/Carp
use Carp();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod

	������ � ����� ������ 'med.db' SQLite

=cut
package Tele_DB {
#
#	���� ������: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	����� ��������� (�������)
#	'.' = ������� �����!
#use lib ('C:\Apache24\web\cgi-bin\pm', 'D:\GIT-HUB\apache\web\cgi-bin\pm');
use lib ('C:\Apache24\web\cgi-bin\pm');
#
#	������������ ������� �� ���� ������
#
use Report();
#
#	������� ��� ������
use Tele_Tools qw(decode_utf8 decode_win);
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	������ ������
#
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
#	������ HTML-�����
my	%FORM_checkbox =
(
	rheumatology	=> '�������� �����������',
	comorbidity		=> '������������� �����������',
	status			=> '������������� ���������',
	manual			=> '������������ ����������',
	preparation		=> '���������',
);
#
#	������ ����� HTML-�����
my	%FORM_number =
(
	probe			=> '������������ ������������',
);
=pod
#
#	��������� �����
my	@row_title = map { decode_win($_) } (
		'��������',
		'����������',
		'����������� ���������',
		'� �������������',
	);
=cut
#
#	��������� �����
my	@row_title = @{ decode_win([
		'��������',
		'����������',
		'����������� ���������',
		'� �������������',])
	};
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�����������
	---
	$obj = Tele_DB->new($query, $db_file);

		%query		- ������ �������
		$db_file	- ���� ����� ���� ������
=cut
sub new {
	#	�������� ������
	my	$class = shift @_;
	#	������ ������������
	my	$query = shift @_;
	#	���� ���� ������
	my	$db_file = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� �����
	unless (-f $db_file)
	{
		Carp::confess "���� ���� ������ '$db_file' �� ������\n";
	}
	#	������� ���� ������
	my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
			or Carp::confess $DBI::errstr;
	#
	#	����� �� �����
	printf STDERR "Connect to database '%s'\n", $dbh->sqlite_db_filename;
	#
	#	������ �� ������
	my	$self =
		{
			-dbh	=> $dbh,	# ��������� ���� ������
			-query	=> $query,	# ������ (������ �� ���)
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
	#	���� ���� ������
	my	$db_filename = $self->{-dbh}->sqlite_db_filename;
	#
	#	������� ���� ������
	$self->{-dbh}->disconnect or Carp::carp $DBI::errstr;
	#
	#	����� �� �����
	printf STDERR "Disconnect from database '%s'\n", $db_filename;
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
	#
	#	������ ������� (checkbox)
	#
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
=pod
		#
		#	��������� ������
		my	@data = ([map { decode_win($_) }
			($FORM_checkbox{$name}, '����������')]);
=cut
		#
		#	��������� ������
		my	@data =
			(
				decode_win([$FORM_checkbox{$name}, '����������'])
			);
		#
		#	���� �� ��������� �������
		while (my $row = $sth->fetchrow_hashref)
		{
			#	������������� �� "UTF-8"
			decode_utf8($row);
			#
			#	�������� � ����� ������
			push @data, [$row->{name}, $row->{info}];
		}
		#
		#	�������� ������ �������
		$req->{$name} = \@data;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	������ ����� ����� (input)
	#
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
=pod
		#
		#	��������� ������
		my	@data = ([map {	decode_win($_) }
			($FORM_number{$name}, '���������', '����������')]);
=cut
		#
		#	��������� ������
		my	@data =
			(
				decode_win([$FORM_number{$name}, '���������', '����������'])
			);
		#
		#	���� �� ��������� �������
		while (my $row = $sth->fetchrow_hashref)
		{
			#	������������� �� "UTF-8"
			decode_utf8($row);
			#
			#	�������� � ����� ������
			push @data, [$row->{name}, $value{$row->{id}}, $row->{info}];
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
	#
	return undef if $sth->fetchrow_hashref()->{rows} == 0;
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
	#	������ ������������ ������������
	my	@probe = ();
	#
	#	���� �� ������ ����������
	my	$order = 1;
	while (my $row = $sth->fetchrow_hashref)
	{
		#	������������� �� "UTF-8"
		decode_utf8($row);
		#
		#	������ ������ ������ �������
		if ($row->{num} == 1)
		{
			#	��������
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
		#	��� ������ ������������ ������������
		next if ($row->{'probe_name'} eq '');
		#
		#	������ ������������
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
	#	������ �� ���
	return
	{
		cgi_query		=> $cgi_query,
		-preparation	=> \@preparation,	# ���������
		-probe			=> \@probe,			# ������������ ������������
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