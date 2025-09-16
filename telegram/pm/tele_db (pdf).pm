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
#	JSON (JavaScript Object Notation) �����������/�������������
#	https://metacpan.org/pod/JSON
use	JSON;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	��������, ��������� � �������� PDF-������
#	https://metacpan.org/pod/PDF::API2
use PDF::API2;
#
#	��������� ����� ��� ���������� ������� ������
#	https://metacpan.org/pod/PDF::Table
use PDF::Table;
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
		[$row->{name}, $probe{$row->{id}}, $row->{info} || '��� ����������'];
	}
	pdf_table(\@preparation);
	
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
=pod

=cut
sub pdf_file
{
	#
	#	������
#	return ($pdf, $font);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����� �������
	---
	pdf_table($data)
		
=cut
sub pdf_table
{
	#	������ ������� (������ �� ������)
	my	$data = shift @_;
=pod
	#
	#	������������� ������
	foreach my $i (0 .. $#{ $data })
	{
		foreach my $j (0 .. $#{ $data->[$i] })
		{
			$data->[$i]->[$j] = Encode::decode('UTF-8', $data->[$i]->[$j]);
		}
	}
=cut
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	������� PDF
	my	$pdf = PDF::API2->new();
	#
	#	������������� ����� � ����������
	my	$font = $pdf->ttfont('Arial.ttf');
	#
	#	�������� ������ ��������
	my	$page = $pdf->page();
	#
	#	A4 (210mm x 297mm)
		$page->mediabox(595, 842);  # 595 x 842 points
	
	#	������� �������
	my	$table = PDF::Table->new();
	#
	#	����� �������
	#	https://metacpan.org/pod/PDF::Table#Table-settings
		$table->table(
			$pdf,
			$page,
			$data,
			header_props => {
				font 		=> $font,
				font_size	=> 14,
				bg_color	=> 'yellow',
				repeat		=> 1,    # 1/0 eq On/Off  if the header row should be repeated to every new page
			},
			font 		=> $font,
			font_size	=> 12,
			x         	=> 50,
			y			=> 842-50,
			w         	=> 500,
			h   		=> 500,
			padding   	=> 5,
			size		=> '5cm *',
			border_w	=> 1,
	#        background_color_odd  => "gray",
	#        background_color_even => "lightblue",
#			cell_props =>
#			[
#				[{colspan => 2}],#	��� ������ ������, ������ ������
#				[],
#				[{colspan => 4}],#	��� ������� ������, ������ ������
#			],
	);
	#
	#	��������� PDF
	#
	$pdf->saveas('russian_table2.pdf');
	
	print STDERR "Create file: 'russian_table2.pdf'\n";
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__