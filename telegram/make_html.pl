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
my	$html_folder = 'C:\Git-Hub\viacheslav-simakov.github.io\med';
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
#	make_pattern('med.txt', $hash, $html_folder);
	make_pattern(undef, $hash, $html_folder);
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
        Carp::confess "B������� ���� '$db_file' �� ����������\n";
    }
    unless (-f $db_file)
	{
        Carp::confess "�������� ���� '$db_file' �� �������� ������\n";
    }
	unless (-d $target_folder)
	{
        Carp::confess "����� ��� ����������� '$target_folder' �� ����������\n";
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
	print STDERR "���������� ���� ���� ������ '$db_copy'\n";
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
	#	���������� �������
	my	$content;
	#
	#	��� HTML-�����
	my	$html_file = 'med';
	#
	#	�������� ������ �������
	if (defined $file_name)
	{
		#	������� ���� �������
		open(my $fh, '<', $file_name) or die "Cannot open '$file_name': $!";
		#
		#	������ ���������� �������
		$content = do { local $/; <$fh> };
		#
		#	������� ����
		close $fh;
		#
		#	����� ��� HTML-�����
		my	@path = split('/', $file_name);
		my	@file = split('\.', $path[$#path]);
			$html_file = $file[0];
	}
	else
	{
		#	������ __DATA__
		$content = do { local $/; <DATA> };
	}
	#
	#	����������� �������
	Utils::subs(\$content, $subs);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� HTML-�����
		$html_file = sprintf '%s/%s.html', $output_folder, $html_file;
		$html_file =~ s/\\/\//g;
	#
	#	������� ����
	open(my $fh, ">", $html_file) or die "Cannot open '$html_file': $!";
	#
	#	������ � ����
	print $fh $content;
	#
	#	������� ����
	close($fh);
	#
	#	����� �� �����
	print STDERR "������ HTML-���� '$html_file'\n";
}
__DATA__
<!DOCTYPE html>
<html lang="ru-RU">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>����������� ���������</title>
<!--meta http-equiv="content-type" content="text/html; charset=utf-8"/-->
<!--
	���� ������
	https://developer.mozilla.org/en-US/docs/Web/CSS
-->
<link href="med.css" rel="stylesheet" type="text/css"/>
<!--
	Google font's
-->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Ubuntu:wght@300;400;500&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined" rel="stylesheet" />
<!--
	Telegram "mini App"
	https://core.telegram.org/bots/webapps#initializing-mini-apps
-->
<script src="https://telegram.org/js/telegram-web-app.js?59"></script>

<style>
/*	������ �������, ����������� */
div.tab-content, input[type=radio]
{
	display:	none;
}
/*	�������� ���������� ������� */
#radio-rheumatology:checked ~	#req-form #rheumatology,
#radio-preparation:checked ~	#req-form #preparation,
#radio-comorbidity:checked ~ 	#req-form #comorbidity,
#radio-status:checked ~ 		#req-form #status,
#radio-deviation:checked ~ 		#req-form #deviation,
#radio-probe:checked ~ 			#req-form #probe
{
	display:	block;
}
/*	��������� ������ ������������ */
#radio-rheumatology:checked ~	#userDialog #label-rheumatology,
#radio-preparation:checked ~	#userDialog #label-preparation,
#radio-comorbidity:checked ~ 	#userDialog #label-comorbidity,
#radio-status:checked ~ 		#userDialog #label-status,
#radio-deviation:checked ~ 		#userDialog #label-deviation,
#radio-probe:checked ~ 			#userDialog #label-probe
{
	color:				var(--tg-theme-button-text-color, yellow);
	background-color:	var(--tg-theme-button-color, green);
}
</style>
</head>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	�������� ����������

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<body>
<!--
	����������� ����
-->
	<input type="radio" id="radio-rheumatology"	name="tab-group" checked>
	<input type="radio" id="radio-preparation"	name="tab-group">
	<input type="radio" id="radio-comorbidity"	name="tab-group">
	<input type="radio" id="radio-status"		name="tab-group">
	<input type="radio" id="radio-deviation"	name="tab-group">
	<input type="radio" id="radio-probe"		name="tab-group">
	<input type="radio" id="radio-prescription"	name="tab-group">
<!--
	����
-->
<div id="showMenu" class="header-fixed">
	<div class="title-icon">rheumatology</div>
	<div class="title-text">�������� �����������</div>
</div>
<!--
	���������� ����
-->
<dialog id="userDialog">
	<!-- :: ����� ����� :: -------------------------------------------------------->
	<div class="menu">
		<!-- ����������� -->
		<label id="label-rheumatology" for="radio-rheumatology">
			<span>rheumatology</span><div>�������� �����������</div></label>

		<!-- ������������� ����������� -->
		<label id="label-comorbidity" for="radio-comorbidity">
			<span>person_cancel</span><div>������������� �����������</div></label>
	
		<!-- ������������� ��������� -->
		<label id="label-status" for="radio-status">
			<span>person_alert</span><div>������������� ���������</div></label>

		<!-- ������������� ���������� -->
		<label id="label-deviation" for="radio-deviation">
			<span>instant_mix</span><div>������������ ����������</div></label>
		
		<!-- ������������ ���������� -->
		<label id="label-probe" for="radio-probe">
			<span>biotech</span><div>������������ ������������</div></label>

		<!-- ��������� -->
		<label id="label-preparation" for="radio-preparation">
			<span>pill</span><div>���������</div></label>
	</div>
</dialog>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	�������� �����������

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<form id="req-form">
<div id="rheumatology" class="tab-content">
##--RHEUMATOLOGY--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	������������� �����������

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="comorbidity" class="tab-content">
##--COMORBIDITY--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	������������� ���������

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="status" class="tab-content">
##--STATUS--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	������������ ���������� (����� �� ������)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="deviation" class="tab-content">
##--PROBE-MANUAL--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	������������ ������������

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="probe" class="tab-content">
##--PROBE--##
</div>
<!--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

	���������

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-->
<div id="preparation" class="tab-content">
##--PREPARATION--##
</div>
</form>
<!--##########################################################################

	Telegram Web API
	https://core.telegram.org/bots/webapps#events-available-for-mini-apps

###########################################################################-->
<script>
	//	Web-API
	let tg = window.Telegram.WebApp;
	//	�������������� WebApp
		tg.ready();
	//	�� ���� �����
		tg.expand();
	//	�������� ���������� � ������������
	const user = tg.initDataUnsafe.user;
	//	������������ ������ (��������) HTML-��������
	const section = ["rheumatology","preparation","comorbidity","status","manual"];
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//
	//	������� ������
	//
	tg.MainButton.setText("������������").show();
	//	Add an event listener for when the SettingButton is clicked
	tg.onEvent('mainButtonClicked', () => {
		//
		//	������ ��� �������� � Telegram Bot
		let dataToSend = {};
		//
		//	���� �� �������� ������, ���������� ������ (checkbox)
		for (let i = 0; i < section.length; i++) {
			//
			//	���������: https://learn.javascript.ru/css-selectors
			//
			let elem = document.querySelectorAll("input[name^='" + section[i] + "#']");
			//
			//	������ ID �������� ������� (checkbox)
			let id = [];
			//
			//	���� �� ���� ��������� ������
			for (let j = 0; j < elem.length; j++) {
				//
				//	���������� ���������� ����� ���� �����
				if (elem[j].checked === false) continue;
				//
				//	�������� � ������
				id.push(elem[j].name.split("#")[1]);
			}
			//	������ ID �������
			dataToSend[section[i]] = id;
		}
		//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		//	��������� ����� ����� (input)
		//	���������: https://learn.javascript.ru/css-selectors
		let elem = document.querySelectorAll("input[name^='probe#']");
		//
		//	������ �������� (����� �����)
		let probe = [];
		//
		//	���� �� ���� ��������� ������
		for (let j = 0; j < elem.length; j++) {
			//
			//	���������� ���������� ����� ���� �����
			if (elem[j].value == "") continue;
			//
			//	�������� � ������
			probe.push(
			{
				id:		elem[j].name.split("#")[1],
				val:	elem[j].value
			});
		}
		//	������ ��������
		dataToSend["probe"] = probe;
		//
		//	����������� ������ �������� � ������ JSON
		const jsonString = JSON.stringify(dataToSend);
		
//		alert("Main button clicked!\n���������� ��������: " + jsonString.length);
		//
		// Send the data to the bot
		tg.sendData(jsonString);
		//
		// You can also send data back to the bot here
		// tg.sendData(JSON.stringify({ action: 'secondary_button_pressed' }));
	});
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//
	//	��������� ������
	//	https://www.google.com/search?q=telegram+WebApp+secondaryButton+example+js+code&oq=telegram+WebApp+secondaryButton+example+js+code
	//	tg.SecondaryButton.setText("�����").show();
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//
	//	������ "���������"
	tg.SettingsButton.show();
	//	Add an event listener for when the SettingButton is clicked
	tg.onEvent('settingsButtonClicked', () => {
		alert('Setting button clicked!');
		// You can also send data back to the bot here
		// tg.sendData(JSON.stringify({ action: 'secondary_button_pressed' }));
	});	
</script>
<!--##########################################################################

	��������� ���������� (DeviceStorage)
	https://core.telegram.org/bots/webapps#devicestorage

###########################################################################-->
<script>
	//	��������� ��������� ������
	let ds = tg.DeviceStorage;
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//	���� �� �������� ������, ���������� checkbox
	for (let i = 0; i < section.length; i++) {
		//
		//	��������� ������� � ������:	https://learn.javascript.ru/css-selectors
		let elem = document.querySelectorAll("input[name^='" + section[i] + "#']");
		//
		//	���� �� ���� ������� (checkbox) �� ������
		for (let j = 0; j < elem.length; j++) {
			//
			//	������������ �������� ������
			ds.getItem(JSON.stringify(elem[j].name), (error, result) => {
				//
				//	��� ���������� � ���������?
				if (result !== null) {
					//
					//	��������� �������� ������
					elem[j].checked = JSON.parse(result);
				}
				else {
					elem[j].checked = false;
				}
			});
			//
			//	���������� ������� ��� ������� ������
			elem[j].addEventListener('click', function(event) {
				//
				//	�������� � ��������� ����������
				ds.setItem(
					JSON.stringify(elem[j].name),
					JSON.stringify(elem[j].checked));
			});
		}
	};
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	//	��������� ����� ����� ����� (input)
	//	https://learn.javascript.ru/css-selectors
	let probe = document.querySelectorAll("input[name^='probe#']");
	//
	//	���� �� ���� ����� �����
	for (let j = 0; j < probe.length; j++) {
		//
		//	������������ �������� ���� �����
		ds.getItem(JSON.stringify(probe[j].name), (error, result) => {
			//
			//	��� ������ � ���������?
			if (result !== null) {
				//
				//	��������� ��������
				probe[j].value = JSON.parse(result);
			}
			else {
				probe[j].value = "";
			}
		});
		//
		//	���������� ������� ��� ������� ���� �����
		probe[j].addEventListener('change', function(event) {
			//
			//	�������� � ��������� ����������
			ds.setItem(
				JSON.stringify(probe[j].name),
				JSON.stringify(probe[j].value));
		});
	};
</script>
<!--##########################################################################

	���� ������� (���� ������ �������)
	https://developer.mozilla.org/ru/docs/Web/HTML/Reference/Elements/dialog

###########################################################################-->
<script>
	const showMenu = document.getElementById("showMenu");
	const userDialog = document.getElementById("userDialog");
	const itemMenu = userDialog.querySelectorAll("label");
	//
	// "Show the dialog" button opens the <dialog> modally
	showMenu.addEventListener("click", () => {
		//
		//	�������� ����
		userDialog.showModal();
		//
		//	������ ������� ������
		tg.MainButton.hide();
	});
	//
	//	���� �� ���� ������� ����
	for (let i = 0; i < itemMenu.length; i++) {
		//
		// ��������� �������������� ��� �������� ��� �����
		itemMenu[i].addEventListener("click", () => {
			//
			//	��������� ������
			userDialog.close();
			//
			//	�������� ������
			showMenu.querySelector(".title-icon").textContent =
				itemMenu[i].querySelector("span").textContent;
			//
			//	�������� ��������
			showMenu.querySelector(".title-text").textContent =
				itemMenu[i].querySelector("div").textContent;
			//
			//	�������� ������� ������
			tg.MainButton.show();
		});
	}
	// ��������� �������������� ��� �������� ��� ����� ��� �������
	document.addEventListener('click', function(event) {
//		alert("Ok");
		console.log(userDialog.open);
		// ���������, �������� �� �� ������ ������� ��� ��� �����������
		if (!userDialog.contains(event.target) && userDialog.open) {
//			userDialog.close(); // ��������� ������
		}
	});
</script>
</body>
</html>