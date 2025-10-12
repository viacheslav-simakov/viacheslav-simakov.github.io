#
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
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
use Encode qw(encode);
#
#	JSON (JavaScript Object Notation) �����������/�������������
#	https://metacpan.org/pod/JSON
use	JSON;
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
#	������� ��� ������
use Tele_Tools qw(decode_utf8 decode_win);
#
#	PDF-���������
use Tele_PDF();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	�������� ����������� ������ � �����
#
unless (-e $ENV{'DB_FILE'})
{
	Carp::confess "���� '$ENV{'DB_FILE'}' ���� ������ �� ����������\n";
}
unless (-d $ENV{'HTML_FOLDER'})
{
	Carp::confess "����� '$ENV{'HTML_FOLDER'}' ��� ����������� �� ����������\n";
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#	������� ���� ������
my	$log_dbh = DBI->connect("dbi:SQLite:dbname=db/log.db","","")
		or Carp::confess $DBI::errstr;
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
#	������ �������������� ������������� (������ �� ���)
my	$user = user_authorized();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	������� ���� ��������� ������� ����
#
printf STDERR "Telegram Bot \@tele_rheumatology_bot is started at %s\n",
	Tele_PDF::time_stamp();
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
		Carp::carp sprintf("\n%s ������ ��� ��������� ����������: $@\n",
			Tele_PDF::time_stamp());
		#	��������� ����������
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
		#	���������
        my	$message = $update->{message} or next;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	�������� ID ������������
		if (!exists $user->{ $message->{chat}->{id} })
		{
			#	���������� �� ������
			send_admin('*Access denied*',
				sprintf('telegram id=(%s)', $message->{chat}->{id} || 'unknow'));
			#
			#	����� �� �����
			Carp::carp "Access denied\n";
			#	��������� ����������
			next;
		}
		#	����� �� �����
		printf STDERR "\nUpdate at %s (%s)\n", Tele_PDF::time_stamp(),
			encode('windows-1251', $user->{$message->{chat}->{id}}->{user_name});
		#
		#	��������� ��������� ���������
		my	$result = {};
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#
        #	��������� ������
		#
		if ($message->{web_app_data}->{data})
		{
			#	������ Web App
			$result = user_request($message);
		}
		elsif (!defined $message->{text})
		{
			#	����������� ����� ���������
			next;
		}
        elsif ($message->{text} =~ m{^/start}i)
		{
			#	����������
			$result = send_keyboard($message);
        }
		elsif ($message->{chat}->{id} eq '5483130027')
		{
			#	�������������
			$result = admin($message);
		}
        else
		{
			#	����������� ������
			$result = send_default($message);
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	������ � �������
		logger($message, $result) if defined($result);
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����� �� �����
	---
	logger(\%message, \%result)
		
		%message	- ��������� (���)
		%result		- ��������� ��������� ��������� (���)
=cut
sub logger
{
	#	��������� (������ �� ���)
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��������� ��������� ���������
	my	$result = shift @_;
	#
	#	telegram_id ������������
	my	$telegram_id = $message->{chat}->{id};
	#
	#	������ � ���� ������
	my	$sth = $log_dbh->prepare(qq
		@
			INSERT INTO "logger" (telegram_id, message, result)
			VALUES (?, ?, ?)
		@);
		$sth->execute(
			$telegram_id,
			encode_json($message),
			encode_json($result)
		)
		or Carp::carp $DBI::errstr;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� �� ������
	---
	send_admin($caption, $msg_text)

		$caption	- ��������� ���������
		$msg_text	- ����� ���������
=cut
sub send_admin
{
	#	��������� ���������
	my	$caption = decode_win(shift @_);
	#	����� ���������
	my	$msg_text = shift @_ || 'undef';
=pod
	if (!defined $debug)
	{
		$debug = sprintf(
			"*ERROR*\npackage = '%s', line = %d", (caller(1))[1,2])
	}
=cut
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� admin
		$api->api_request('sendMessage',
		{
			chat_id		=> '5483130027',# �������
			parse_mode	=> 'Markdown',
			text		=> sprintf("%s\n%s", $caption, $msg_text),
		})
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		Carp::carp "\n������ ��� �������� ��������� ��������������: $@\n";
	}
	else
	{
		printf STDERR "Message to Admin has been send\n";
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����������� ���������
	---
	send_default($message)

		$message	- ������ �� ��������� (���)
=cut
sub send_default
{
	#	��������� (������ �� ���)
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������
	my	$user_name = $user->{$message->{chat}->{id}}->{user_name} || 'undef';
	#
	#	���������
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� ���� (����� ����������)
		$result = $api->api_request('sendMessage',
		{
			chat_id		=> $message->{chat}->{id},
			parse_mode	=> 'Markdown',
			text		=> decode_win(sprintf(
				"������ _%s_!\n� ��� *����������� ��������� �����-�����������*.\n".
				"����������� /start ��� ������ ������.",
				encode('windows-1251', $user_name))
			),
		});
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		send_admin('������ ��� �������� "default" ���������', $@);
		#	����� �� �����
		Carp::carp "\n������ ��� �������� 'default' ���������: $@\n";
	}
	else
	{
		printf STDERR "Unknown message! 'Default' response to Bot has been send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	���������� ����
	---
	\%result = send_keyboard( \%message )
		
		%message	- ��������� (���)
		%result		- ��������� �������� (���)
=cut
sub send_keyboard
{
	#	��������� (������ �� ���)
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������
	my	$user_name = $user->{$message->{chat}->{id}}->{user_name} || 'undef';
	#
	#	���������
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������
	my	$keyboard = [[
		{
			text	=> "\x{1F48A} " . decode_win('����������� ��������� �����-�����������'),
			web_app	=> {
				url	=> 'https://viacheslav-simakov.github.io/med/med.html'
			},
		}
	],];
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������������
	if ($message->{chat}->{id} eq '5483130027')
	{
		#	���������� ��������������
		my	@admin = (
			[
				{text => "\x{2139} " . decode_win('��������� 10 ��������')},
				{text => "\x{2702} " . decode_win('�������� ������ ��������')},
			],
			[
				{text => "\x{1F4D4} " . decode_win('�������� ������ ��������')},
				{text => "\x{267B} " . decode_win('�������� ���� ������')},
			],
			);
		#	�������� ����������
		push @{ $keyboard }, @admin;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� ���� (����� ����������)
		$result = $api->api_request('sendMessage',
		{
			chat_id => $message->{chat}->{id},
			parse_mode => 'Markdown',
			text => decode_win("*����������� ��������� �����-�����������*\n(���� ����� �.�. ������������)"),
			reply_markup =>
			{
				keyboard => $keyboard,
				resize_keyboard => \1,
				one_time_keyboard => \0,
			},
		});
	};
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		send_admin('������ ��� �������� "����������"', $@);
		#	����� �� �����
		Carp::carp "\n������ ��� �������� '����������' ����: $@\n";
	}
	else
	{
		printf STDERR "'reply mark' keyboard to '%s' has been send\n",
			encode('windows-1251', $user_name);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ����
	---
	send_file(\%message, $file_name)
	
		%message	- ��������� (���)
		$file_name	- ��� ����� (� ������� �����)
=cut
sub send_file
{
	#	��������� (������ �� ���)
    my	$message = shift @_;
	#	��� PDF-�����
	my	$file_name = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������
	my	$user_name = $user->{$message->{chat}->{id}}->{user_name} || 'undef';
	#
	#	������������� �������� '\'
		$file_name =~ s/\\/\//g;
	#
	#	���������
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������������� �����
	unless (-e $file_name)
	{
		#	��������������!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"file '%s' is not exist!\n",
			(caller(0))[0,1,3], $file_name;
		#
		#	������� �� �������
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval
	{
		#	���������� PDF ����
		$result = $api->api_request('sendDocument',
		{
			chat_id		=> $message->{chat}->{id},
			caption		=> decode_win('���� ����� �.�. ������������'),
			document	=>
			{
				file		=> $file_name,
#				filename	=> decode('windows-1251', '������������.pdf'),
				filename	=> $file_name,
			},
		});
		#	����� �� �����
		printf STDERR
			"Send file '%s' (%s) to '%s' successed\n",
			$result->{result}->{document}->{file_name},
			sprintf('%.1f kB', $result->{result}->{document}->{file_size}/1024),
			encode('windows-1251', $user_name);
	};
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		send_admin('������ ��� �������� �����', $@);
		#	����� �� �����
		Carp::carp "\n������ ��� �������� �����: $@\n";
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������ ���������������� �������������
	---
	\%user = user_authorized()
	
=cut
sub user_authorized
{
	#	������ �������������
	my	%user = ();
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� ���� ������
	my	$dbh = DBI->connect("dbi:SQLite:dbname=db/user.db","","")
			or Carp::confess $DBI::errstr;
	#
	#	SQL-������
	my	$sth = $dbh->prepare('SELECT * FROM "user"')
			or Carp::confess "������ ������� � ������� �������������";
	#
	#	��������� ������ � �������
		$sth->execute;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		#	������������
		decode_utf8($row);
		#
		#	�������� ������������ � ���
		$user{ $row->{telegram_id} } = $row;
	}
	#	������� ���� ������
	$dbh->disconnect or Carp::carp $DBI::errstr;
	#
	#	����� �� �����
	print STDERR "Loading authorized users from 'bot.db' is completed\n";
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ���
	return \%user;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ������ HTML-����� ���������� �� Web App
	---
	user_request( \%message )
	
		%message	- ��������� (���)

=cut
sub user_request
{
	#	��������� (������ �� ���)
    my	$message = shift @_;
	#	���������
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��� PDF-�����
	my	$pdf_file_name = sprintf '%s.pdf', $message->{chat}->{id};
	#
	#	������ HTML-�����
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
	#	PDF-��������
	my	$pdf = Tele_PDF->new(
			$user->{$message->{chat}->{id}},
			decode_json($web_app_data)
		);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval
	{
		#	������� PDF-����
		$pdf->save($pdf_file_name);
	};
	#	�������� ������
	if ($@)
	{
		#	������� ���������� �� ������
		send_admin('*������* �������� PDF-�����', $@);
		#	����� �� �����
		Carp::carp "Error file '$pdf_file_name' created: $@";
	}
	else
	{
		#	��������� ������������ PDF-����
		$result = send_file($message, $pdf_file_name);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�����������������
	---
	admin($message)
	
		$message	- ������ �� ��������� (���)
=cut
sub admin
{
	#	��������� (������ �� ���)
	my	$message = shift @_;
	#	�������� ���� ��������������
	return undef if
		($message->{chat}->{id} ne '5483130027') || !defined($message->{text});
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������
	my	$result = {-admin => $message->{text}};
	#
	#	����������� ������ ���������
	my	$text = encode('windows-1251', $message->{text});
	#
	#	������� ������ 2 �������
		$text =~ s/^..//;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����� ��������������
	if ($text eq '�������� ������ ��������')
	{
		#	������������
		send_file($message, 'db/user.db');
		#
		#	���� �������
		send_file($message, 'db/log.db');
		#
		#	���� ������
		send_file($message, $ENV{'DB_FILE'});
	}
	elsif ($text eq '�������� ���� ������')
	{
		#	����������� ���� ������
		my	$err = system('perl',
			'lib/make_html.pl', $ENV{'DB_FILE'}, $ENV{'HTML_FOLDER'});
		#
		#	����������
		send_admin(
			'*���������� ���� ������*',
			decode_win("��� ����������: ($err)\n������: ($?)\n������: '$!'"));
		#
		#	������� ���� ���� ������
		send_file($message, $ENV{'DB_FILE'});
	}
	elsif ($text eq '��������� 10 ��������')
	{
		#	��������� 10 ������� � ������� ��������
		my	$sth = $log_dbh->prepare(qq
			@
				SELECT * FROM
				(
					SELECT id, telegram_id, time(time_stamp) as time,
						json_extract(message, '\$.text') as request,
						json_extract(result, '\$.result.chat.username') as reply
					FROM "logger"
					WHERE request NOT NULL
				UNION
					SELECT id, telegram_id, time(time_stamp) as time,
						json_extract(message, '\$.web_app_data.data') as request,
						json_extract(result, '\$.result.document.file_name') as reply
					FROM "logger"
					WHERE request NOT NULL
				)
				ORDER BY id DESC LIMIT 10
			@);
			$sth->execute() or Carp::carp $DBI::errstr;
		#
		#	���������� � ��������
		my	$log = "\x{1F4CE}\n\n";
		#
		#	���� �� ��������� �������
		while (my $row = $sth->fetchrow_hashref)
		{
			#	������������
			decode_utf8($row);
			#
			#	������������ ������� 'Markdown'
			$row->{reply} =~ s/[_\*\-\~]/ /g;
			#
			#	�������� � ����� ������
			$log .= sprintf "*%s* (%s)\n`%s` (%s)\n",
				$user->{ $row->{telegram_id} }->{user_name},
				$row->{time}, $row->{request}, $row->{reply};
		}
		#
		#	��������� ������ �������� ����
		send_admin('*������ ��������*', $log);
		#
		#	�� ���������� � ������
		$result = undef;
	}
	elsif ($text eq '�������� ������ ��������')
	{
		#	�������� ������ �������� (����� 10 ��������� �������)
		$log_dbh->do(qq
			@
				DELETE FROM logger
				WHERE rowid NOT IN (
					SELECT rowid FROM logger
					ORDER BY rowid DESC 
					LIMIT 10
				)
			@)
			or Carp::carp $DBI::errstr;
		#
		#	���������
		send_admin('*������ ��������* ������', ($DBI::errstr
			? "\x{1F6AB} DBI err='$DBI::errstr'"
			: "\x{2705} " . decode_win("������� ��� ������, ����� 10 ��������� ")));
	}
	else
	{
		#	����������� �������
		send_admin('*����������� �������*', $message->{text});
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__DATA__

SELECT * FROM
(
	SELECT id, telegram_id, time(time_stamp) as time,
		json_extract(message, '$.text') as request,
		json_extract(result, '$.result.chat.username') as reply
	FROM "logger"
	WHERE request NOT NULL
UNION
	SELECT id, telegram_id, time(time_stamp) as time,
		json_extract(message, '$.web_app_data.data') as request,
		json_extract(result, '$.result.document.file_name') as reply
	FROM "logger"
	WHERE request NOT NULL
)
ORDER BY id DESC LIMIT 10
