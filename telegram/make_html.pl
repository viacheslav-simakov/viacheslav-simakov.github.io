#
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#
#	�������������� warn � die ��� �������
#	https://perldoc.perl.org/Carp
use Carp();
#
#	����������� ������ ��� �������� ������������
#	https://metacpan.org/pod/File::Copy
use File::Copy();
#
#	����� ��������� (�������)
#	'.' = ������� �����!
use lib ('C:\Apache24\web\cgi-bin\pm', 'D:\GIT-HUB\apache\web\cgi-bin\pm');
#
#	�������
use Utils();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#	���� ������: https://metacpan.org/pod/DBI
#	SQLite:	https://www.techonthenet.com/sqlite/index.php
use DBI;
#
#	����� ��� ���������� HTML-�����
my	$html_folder = 'D:\Git-Hub\viacheslav-simakov.github.io\med';
#
#	����������� ����� ���� ������
my	$db_file = db_copy('C:\Apache24\sql\med.db', $html_folder);
#
#	������� ���� ������
my	$dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","")
		or Carp::confess "$DBI::errstr\n\n\t";
#	
#	��������� �������
my	$sth;
#
#	��� ��� ������
my	$hash;
#
#	������ �������
my	$data;
##############################################################################
#
#	"���������"
#
$data = '';
#
#	SQL-������
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "preparation"
	WHERE id IN (
		SELECT preparation FROM "indication"
	)
	ORDER BY num
@);
$sth->execute();
#
#	���� �� ��������� �������
while (my $row = $sth->fetchrow_hashref)
{
#	����������
$row->{info} ||= '��� ����������';
#	������ �������
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="preparation#%1\$d" class="item-checkbox"
		id="preparation-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="preparation-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	��� ��� ������
$hash->{'--preparation--'} = $data;
##############################################################################
#
#	"�����������"
#
$data = '';
#
#	SQL-������
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "rheumatology"
	WHERE id IN (
		SELECT rheumatology FROM "indication"
	)
	ORDER BY num
@);
$sth->execute();
#
#	���� �� ��������� �������
while (my $row = $sth->fetchrow_hashref)
{
#	����������
$row->{info} ||= '��� ����������';
#	������ �������
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="rheumatology#%1\$d" class="item-checkbox"
		id="rheumatology-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="rheumatology-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	��� ��� ������
$hash->{'--rheumatology--'} = $data;
##############################################################################
#
#	"������������� �����������"
#
$data = '';
#
#	SQL-������
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "comorbidity"
	WHERE id IN (
		SELECT comorbidity FROM "contra-indication-comorbidity"
	)
	ORDER BY num
@);
$sth->execute();
#
#	���� �� ��������� �������
while (my $row = $sth->fetchrow_hashref)
{
#	����������
$row->{info} ||= '��� ����������';
#	������ �������
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="comorbidity#%1\$d" class="item-checkbox"
		id="comorbidity-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="comorbidity-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	��� ��� ������
$hash->{'--comorbidity--'} = $data;
##############################################################################
#
#	"������������� ���������"
#
$data = '';
#
#	SQL-������
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "status"
	WHERE id IN (
		SELECT status FROM "contra-indication-status"
	)
	ORDER BY num
@);
$sth->execute();
#
#	���� �� ��������� �������
while (my $row = $sth->fetchrow_hashref)
{
#	����������
$row->{info} ||= '��� ����������';
#	������ �������
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="status#%1\$d" class="item-checkbox"
		id="status-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="status-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	��� ��� ������
$hash->{'--status--'} = $data;
##############################################################################
#
#	"������������ ���������� (����� �� ������)"
#
$data = '';
#
#	SQL-������
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "probe-manual"
	WHERE id IN (
		SELECT "probe-manual" FROM "contra-indication-probe-manual"
	)
	ORDER BY num
@);
$sth->execute();
#	���� �������
my	$probe_manual = '';
#	���� �� ��������� �������
while (my $row = $sth->fetchrow_hashref)
{
#	����������
$row->{info} ||= '��� ����������';
#	������ �������
$data .= sprintf qq
@
<div class="flex-box">
	<input type="checkbox" name="manual#%1\$d" class="item-checkbox"
		id="manual-label-%1\$d"/>
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<label for="manual-label-%1\$d" class="item-label"></label>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	��� ��� ������
$hash->{'--probe-manual--'} = $data;
##############################################################################
#
#	"������������ ������������ (��������� ��������)"
#
$data = '';
#
#	SQL-������
$sth = $dbh->prepare(qq
@
	SELECT id,name,info,ROW_NUMBER() OVER(ORDER BY "name_lc") AS num
	FROM "probe"
	WHERE id IN (
		SELECT probe FROM "prescription"
	)
	ORDER BY num
@);
$sth->execute();
#
#	���� �� ��������� �������
while (my $row = $sth->fetchrow_hashref)
{
#	����������
$row->{info} ||= '��� ����������';
#	������ �������
$data .= sprintf qq
@
<div class="flex-box">
	<div class="item-order">
		%2\$d
	</div>
	<div class="item-content">
		<details>
			<summary>%3\$s</summary>
			<p>%4\$s</p>
		</details>
	</div>
	<div class="item-input">
		<input type="number" class="probe-number" name="probe#%1\$d"
			step="0.1" min="0" max="100"/>
	</div>
</div>
@,
$row->{id}, $row->{num}, $row->{name}, Utils::break_line($row->{info});
}
#	��� ��� ������
$hash->{'--probe--'} = $data;
#
#	������� HTML-����
#
	make_pattern('med.txt', $hash, $html_folder);
#exit;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=pod
	���������� ���� ���� ������
	---
	$db_copy = db_copy($db_file, $target_folder)
	
		$db_file		- ���� ���� ������
		$target_folder	- ����� ��� �����������
		$db_copy		- ���� ����� ���� ������
=cut
sub db_copy
{
	#	��� �����, ����� ��� �����������
	my	($db_file, $target_folder) = @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������������� ������
		$db_file =~ s/\\/\//g;
		$target_folder =~ s/\\/\//g;
	#	�������� ����� ���� ������
    unless (-e $db_file)
	{
        Carp::confess "B������� ���� '$db_file' �� ����������";
    }
    unless (-f $db_file)
	{
        Carp::confess "�������� ���� '$db_file' �� �������� ������";
    }
	unless (-d $target_folder)
	{
        Carp::confess "����� ��� ����������� '$target_folder' �� ����������";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� �����
	my	@path = split(/\//, $db_file);
	#	���� ����� ����� ���� ������
	my	$db_copy = sprintf '%s/%s' , $target_folder, $path[$#path];
	#
	#	����������� �����
	File::Copy::copy($db_file, $db_copy) or Carp::confess "Copy failed: $!";
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� ���� ������
	print ">>> $db_copy\n\n";
	return $db_copy;
}
=pod
	������ HTML
	---
	make_pattern($file_name, \%subs, $output_folder)
		
		$file_name		- ��� ����� �������
		%subs			- ��� ��� ������ � ����� �������
		$output_folder	- ����� ��� HTML-�����
=cut
sub make_pattern
{
	#	��� �����, ������ ���, ����� ��� HTML-�����
	my	($file_name, $subs, $output_folder) = @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� ���� �������
	open(my $fh, '<', $file_name) or die "Cannot open '$file_name': $!";
	#
	#	������ ���������� �������
	my $content = do { local $/; <$fh> };
	#
	#	������� ����
	close $fh;
	#
	#	����������� �������
	Utils::subs(\$content, $subs);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��� HTML-�����
	$file_name = do
	{
		my	@path = split('/', $file_name);
		my	@file = split('\.', $path[$#path]);
		$file[0];
	};
	#	���� HTML-�����
	my	$html_file = sprintf '%s/%s.html', $output_folder, $file_name;
		$html_file =~ s/\\/\//g;
	#
	#	������� ����
	open($fh, ">", $html_file) or die "Cannot open '$html_file': $!";
	#
	#	������ � ����
	print $fh $content;
	#
	#	������� ����
	close($fh);
	#
	#	����� �� �����
	print STDERR "\n\n\tCreate HTML-file '$html_file'\n\n\n";
}
__DATA__
