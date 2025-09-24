#
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#
#	������������ 'warn' � 'die' ��� �������
#	https://perldoc.perl.org/Carp
use Carp();
#
#	��������� ��������� ������ Perl, ���������� ��� ��� ������
#	https://metacpan.org/pod/Data::Dumper
use	Data::Dumper;
#
#	������������� ��������
#	https://perldoc.perl.org/Encode
use Encode;# qw(decode encode);
#
#	JSON (JavaScript Object Notation) �����������/�������������
#	https://metacpan.org/pod/JSON
use	JSON;
#
#	�������� � ��������� PDF-������
#	https://metacpan.org/pod/PDF::Builder
#use PDF::Builder;
#
#	��������-���
#	https://metacpan.org/pod/WWW::Telegram::BotAPI
use WWW::Telegram::BotAPI;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	����� ��������� (�������)
#	'.' = ������� �����!
use lib ('pm');
#
#	���� ������
use tele_db();
#
#	pdf-���������
use tele_pdf();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	��� @tele_rheumatology_bot
#	����� (�������� � @BotFather)
#
my	$token = '8278981933:AAGOZMWywJZxlR-Vj5kwh4HeISQhwPpXuwE';
#
#	������� ������ API
my	$api = WWW::Telegram::BotAPI->new(token => $token);
#
#	�������� ��������� ����������
my	$offset = 0;
#
#	������� ���� ��������� ������� ����
printf STDERR
	"Telegram Bot \@tele_rheumatology_bot is started at %3\$02d:%2\$02d:%1\$02d\n\n",
	(localtime)[0 ... 2];
while (1) {
	#	�������� 1 �������
#	sleep(1);
	#
    #	�������� ����������
	#
    my	$updates = $api->getUpdates(
		{
			offset => $offset,	# ��������
			timeout => 30,		# Determines the timeout in seconds for long polling
		}
	) or die "������ ��� ��������� ����������: $!";
    #
    #	������������ ������ ����������
	#
    foreach my $update (@{ $updates->{result} })
	{
		#	����������� ��������
        $offset = $update->{update_id} + 1 if $update->{update_id} >= $offset;
		#
		#	������
			_logger($update);
        #
		#	���������
        my	$message = $update->{message} or next;
        #
		#	ID ����
		my	$chat_id = $message->{chat}->{id} or next;
		#
		#	����� ���������
        my	$msg_text = $message->{text} or undef;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #	��������� ������
		if ($message->{web_app_data}->{data})
		{
			#	������ Web App
			web_app_data($message);
			#
			#	��������� �������� �����
			next;
		}
        elsif ($msg_text and $msg_text =~ m{^/start}i)
		{
			#	����������
			web_app_keyboard($message);
        }
        else
		{
            $api->sendMessage(
			{
                chat_id => $message->{chat}->{id},
				parse_mode => 'Markdown',
                text => decode('windows-1251', sprintf(
					"������ *%s*!\n� ��� \"����������� ��������� �����-�����������\".\n����������� /start ��� ������ ������.",
					encode('windows-1251', ($message->{from}->{first_name} || 'unknow')))
				),
            });
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����� �� �����
	---
	_logger($update)
		
		$update	- ������ �� ���������� (���)
=cut
sub _logger
{
	#	������ �� ����������
	my	$update = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������
	printf STDERR "update at %3\$02d:%2\$02d:%1\$02d\n", (localtime)[0 ... 2];
	printf STDERR "from_id='%s'\ttext='%s'\tweb_app_data='%s'\n%s%s\n",
		$update->{message}->{from}->{id},
		encode('windows-1251', $update->{message}->{text} || ''),
		encode('windows-1251', $update->{message}->{web_app_data}->{data} || ''),
		Dumper($update),
		('~' x 79);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������
	---
	_button($text, $page, $emoji)
	
		$text	- ������� �� ������
		$page	- ��������
		$emoji	- ������
=cut
sub _button
{
	#	�������� ������, html-��������
	my	($text, $page, $emoji) = @_;
	#	������
		$emoji = defined $emoji ? $emoji . ' ' : '';
	#
	#	������ �� ���
	return
	{
		text => $emoji . decode('windows-1251', $text),
		web_app => {url => 'https://viacheslav-simakov.github.io/med/' . $page},
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����� ���������� �� �����
	---
	web_app_keyboard($message)
		
		$message	- ������ �� ��������� (���)
=cut
sub web_app_keyboard
{
	#	������ �� ���������
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ID ����
    my	$chat_id = $message->{chat}->{id} || undef;
	#
	#	�������� ID ����
	unless (defined $chat_id)
	{
		printf STDERR "\n\t%s: ������! �������� 'chat id'\n", (caller(0))[3];
		#
		#	������� �� �������
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������
	my	$keyboard = [
		[
			{
				text	=> "\x{1F48A}" . decode('windows-1251',
							'����������� ��������� �����-�����������'),
				web_app	=> {
					url	=> 'https://viacheslav-simakov.github.io/med/med.html'
				},
			}
#		_button('����������� ��������� �����-�����������', 'med.html', "\x{1F48A}")
		],
	];
	#-----------------------------------------------------------------
	#	���������
	$api->api_request('sendMessage',
	{
		chat_id => $chat_id,
		parse_mode => 'Markdown',
		text => decode('windows-1251',
			"*����������� ��������� �����-�����������*\n(���� ����� �.�. ������������)"),
		reply_markup =>
		{
			keyboard => $keyboard,
			resize_keyboard => \1,
			one_time_keyboard => \1,
		},
	});
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ������ HTML-����� ���������� �� Web App
	---
	web_app_data($message)
	
		$message	- ������ �� ��������� (���)

=cut
sub web_app_data
{
	#	������ �� ���������
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ID ����
    my	$chat_id = $message->{chat}->{id};
	#
	#	�������� ID ����
	unless (defined $chat_id)
	{
		printf STDERR "\n\t%s: ������! �������� 'chat id'\n", (caller(0))[3];
		#
		#	������� �� �������
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� PDF-����
		make_pdf($message);
	#
	#	��������� ������������ PDF-����
		send_pdf($message);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�������� PDF-�����
	---
	send_pdf( $message )
	
		$message	- ������ �� ��������� (���)
=cut
sub send_pdf
{
	#	������ �� ���������
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ID ����
    my	$chat_id = $message->{chat}->{id};
	#
	#	PDF-����
	my	$pdf_file = sprintf '%s.pdf', $chat_id;
	#
	#	��������� ������������� �����
	unless (-e $pdf_file)
	{
		#	��������������!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"PDF-file '%s' file is not exist!\n",
			(caller(0))[0,1,3], $pdf_file;
		#
		#	������� �� �������
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	���������� PDF ����
		my $result = $api->api_request('sendDocument',
		{
			chat_id		=> $chat_id,
			caption		=> decode('windows-1251','���� ����� �.�. ������������'),
			document	=>
			{
				file		=> $pdf_file,
#				filename	=> decode('windows-1251', '������������.pdf'),
				filename	=> $pdf_file,
			},
		});
		#	����� �� �����
		printf STDERR
			"PDF ���� '%s' ������� ���������!\nmessage ID: %s\n",
			$pdf_file, $result->{result}->{message_id};
#		print STDERR Dumper($result);
	};
	#	�������� ������
	Carp::carp "\n������ ��� �������� �����: $@\n" if ($@);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������� PDF-�����
	---
	make_pdf( $message )
	
		$message	- ������ �� ��������� (���)

=cut
sub make_pdf
{
	#	������ �� ���������
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ HTML-�����
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
    #	������������� JSON ������ HTML-����� ���������� �� Web App
	my	$data = decode_json($web_app_data);
	#
	#	������ �� ������
	my	$req = Tele_DB->new($data);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ ������������
	my	$data_query = $req->request();
	#
	#	����� �� ������� ������������
	my	$data_report = $req->report();
	#
	#	PDF-��������
	my	$pdf = Tele_PDF->new( $message->{from} );
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������ ��������
		$pdf->add_page();
	#
	#	��������� ������ �� �������� ���� ��������	
		$pdf->{-current_y} -= 12;
	#
	#	������ ������� ������������
	#
		$pdf->add_text(decode('windows-1251',
			'������ ������� ������������'),
			font => $pdf->{-font_bold}, font_size => 14);
	#
	#	���� �� ������� �������
	foreach my $name ('rheumatology', 'comorbidity', 'status', 'manual', 'probe', 'preparation')
	{
		#	��� ��������� ������
		next if scalar @{ $data_query->{$name} } < 2;
		#
		#	�������� �������
		if ($name eq 'probe')
		{
			$pdf->add_table($data_query->{$name}, size => '8cm 3cm 1*');
		}
		else
		{
			$pdf->add_table($data_query->{$name}, size => '8cm 1*');
		}
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������ ��������
		$pdf->add_page();
	#
	#	��������� ������ �� �������� ���� ��������	
		$pdf->{-current_y} -= 12;
	#
	#	������ ���������� ������������� � ����������
	#
	$pdf->add_text(decode('windows-1251',
			'������ ���������� ������������� � ����������'),
			font => $pdf->{-font_bold}, font_size => 14);
	#
	#	���� �� ��������� ����������
	foreach my $preparation (@{ $data_report->{-preparation} })
	{
		#	�������� �������
		$pdf->add_table($preparation,
			size	=> '5cm 1*',
		);
	}

	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� PDF-����
	my	$pdf_file_name = $pdf->save();
	#
	#	����� �� �����
	print STDERR "\n\tCreate *PDF*-file '$pdf_file_name'\n\n";
	#	��� �����
	return $pdf_file_name;
}
__DATA__
