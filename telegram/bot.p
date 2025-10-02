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


users();
exit;
#
#	���� ������
#use tele_db();
#
#	pdf-���������
use Tele_PDF();
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
#	����������
my	$updates;
#
#	�������� ��������� ����������
my	$offset = 0;
#
#	������� ���� ��������� ������� ����
printf STDERR
	"Telegram Bot \@tele_rheumatology_bot is started at %3\$02d:%2\$02d:%1\$02d\n",
	(localtime)[0 ... 2];
while (1) {
	#	�������� 1 �������
#	sleep(1);
	#	���������� �����������
	eval {
		#	�������� ����������
		$updates = $api->getUpdates(
			{
				offset	=> $offset,	# ��������
				timeout	=> 30,		# Determines the timeout in seconds for long polling
			}
		)
	};
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		Carp::carp "\n������ ��� ��������� ����������: $@\n\n";
		#
		#	��������� �������� �����
		next;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    #	������������ ������ ����������
	#
    foreach my $update (@{ $updates->{result} })
	{
		#	����������� ��������
        $offset = $update->{update_id} + 1 if $update->{update_id} >= $offset;
		#
		#	������
		logger($update);
        #
		#	���������
        my	$message = $update->{message} or next;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	�������� ID ����
		unless ($message->{chat}->{id})
		{
			#	����� �� �����
			Carp::carp "������! �������� 'chat id'";
			#	��������� ����������
			next;
		}
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#
        #	��������� ������
		#
		if ($message->{web_app_data}->{data})
		{
			#	������ Web App
			user_request($message);
		}
        elsif (defined($message->{text}) and $message->{text} =~ m{^/start}i)
		{
			#	����������
			web_app_keyboard($message);
        }
        else
		{
			#	����������� ������
			unknow($message);
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����� �� �����
	---
	logger($update)
		
		$update	- ������ �� ���������� (���)
=cut
sub logger
{
	#	������ �� ����������
	my	$update = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������
	printf STDERR "\nUpdate at %3\$02d:%2\$02d:%1\$02d\n", (localtime)[0 ... 2];
=pod
	printf STDERR "from_id='%s'\ttext='%s'\tweb_app_data='%s'\n%s%s\n",
		$update->{message}->{from}->{id},
		encode('windows-1251', $update->{message}->{text} || ''),
		encode('windows-1251', $update->{message}->{web_app_data}->{data} || ''),
		Dumper($update),
		('~' x 79);
=cut
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����������� ���������
	---
	unknow($message)

		$message	- ������ �� ��������� (���)
=cut
sub unknow
{
	#	������ �� ���������
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� ���� (����� ����������)
		$api->api_request('sendMessage',
		{
			chat_id		=> $message->{chat}->{id},
			parse_mode	=> 'Markdown',
			text		=> decode('windows-1251', sprintf(
				"������ _%s_!\n� ��� *����������� ��������� �����-�����������*.\n".
				"����������� /start ��� ������ ������.",
				encode('windows-1251', ($message->{from}->{first_name} || 'unknow')))
			),
		});
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		Carp::carp "\n������ ��� �������� 'default' ���������: $@\n";
	}
	else
	{
		printf STDERR "Unknown message! 'Default' response to Bot has been send\n";
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
	#	����������
	my	$keyboard = [[
		{
			text	=> "\x{1F48A}" . decode('windows-1251',
						'����������� ��������� �����-�����������'),
			web_app	=> {
				url	=> 'https://viacheslav-simakov.github.io/med/med.html'
			},
		}
	],];
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� ���� (����� ����������)
		$api->api_request('sendMessage',
		{
			chat_id => $message->{chat}->{id},
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
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		Carp::carp "\n������ ��� �������� '����������' ����: $@\n";
	}
	else
	{
		printf STDERR "'reply mark' keyboard to Bot has been send\n";
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ������ HTML-����� ���������� �� Web App
	---
	user_request($message)
	
		$message	- ������ �� ��������� (���)

=cut
sub user_request
{
	#	������ �� ���������
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��� PDF-�����
	my	$pdf_file_name = sprintf '%s.pdf', $message->{chat}->{id};
	#
	#	������ HTML-�����
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
		
		$message->{from}->{-organization} =
			decode('windows-1251', '��������� ����������� �������� (���)');
	#
	#	PDF-��������
	my	$pdf = Tele_PDF->new($message->{from}, decode_json($web_app_data));
	#
	#	������� PDF-����
		$pdf->save($pdf_file_name);
	#
	#	��������� ������������ PDF-����
		send_pdf($message, $pdf_file_name);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�������� PDF-�����
	---
	send_pdf($message, $pdf_file_name)
	
		$message		- ������ �� ��������� (���)
		$pdf_file_name	- ��� PDF-�����
=cut
sub send_pdf
{
	#	ID ���� ������������
    my	$message = shift @_;
	#	��� PDF-�����
	my	$pdf_file_name = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������������� �����
	unless (-e $pdf_file_name)
	{
		#	��������������!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"PDF-file '%s' file is not exist!\n",
			(caller(0))[0,1,3], $pdf_file_name;
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
			chat_id		=> $message->{chat}->{id},
			caption		=> decode('windows-1251','���� ����� �.�. ������������'),
			document	=>
			{
				file		=> $pdf_file_name,
#				filename	=> decode('windows-1251', '������������.pdf'),
				filename	=> $pdf_file_name,
			},
		});
		#	����� �� �����
		printf STDERR
			"Send file '%s' (%s) into chat id='%s' successed\n",
			$result->{result}->{document}->{file_name},
			sprintf('%.1f kB', $result->{result}->{document}->{file_size}/1024),
			$message->{chat}->{id};
#		print STDERR Dumper($result);
	};
	#	�������� ������
	Carp::carp "\n������ ��� �������� �����: $@\n" if ($@);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������ �������������
	---
	\%user = users()
	
=cut
sub users
{
	#	������� ���� ������
	my	$dbh = DBI->connect("dbi:SQLite:dbname=bot.db","","")
			or die $DBI::errstr;
	#
	#	SQL-������
	my	$sth = $dbh->prepare('SELECT * FROM "user"')
			or Carp::confess "������ ������� � ������� �������������";
		$sth->execute;
	#
	#	������ �������������
	my	%user;
	#
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		#	���� �� ������ ����
		foreach (keys %{ $row })
		{
			#	������������ ������ �� "UTF-8"
			$row->{$_} = decode('UTF-8', $row->{$_});
		}
		#	Telegram-ID
		my	$telegram_id = delete $row->{telegram_id};
		#
		#	�������� ������������ � ���
		$user{ $telegram_id } = $row;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
	return \%user;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__DATA__
