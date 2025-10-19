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
use	JSON qw(encode_json decode_json);
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
use Med::Tools qw(decode_utf8 decode_win time_stamp);
#
#	PDF-���������
use Med::PDF();
#
#	�������������
use Med::Admin();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	�������� ����������� ������ � �����
#
unless (-d $ENV{'DB_FOLDER'})
{
	Carp::confess "����� '$ENV{'DB_FOLDER'}' ���� ������ �� ����������\n";
}
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
#
#	������
my	$log_dbh = DBI->connect("dbi:SQLite:dbname=db/log.db","","")
		or Carp::confess $DBI::errstr;
#
#	�������������
my	$admin = Med::Admin->new($api, '5483130027', $log_dbh);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	������� ���� ��������� ������� ����
#
printf STDOUT "Telegram Bot \@tele_rheumatology_bot is started at %s\n", time_stamp();
#	Tele_PDF::time_stamp();
	
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
		Carp::carp sprintf(
			"\n%s ������ ��� ��������� ����������: $@\n", time_stamp());
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
			$admin->send_msg('*Access denied*',
				sprintf('telegram id=(%s)', $message->{chat}->{id} || 'unknow'));
			#
			#	����� �� �����
			Carp::carp "Access denied\n";
			#	��������� ����������
			next;
		}
		#	����� �� �����
		printf STDOUT "\nUpdate at %s (%s)\n", time_stamp(),
			encode('windows-1251', $user->{$message->{chat}->{id}}->{user_name});
		#
		#	������ � ������
		log_message($message);
		#
		#	��������� ��������� ���������
		my	$result = undef;
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
		elsif ($message->{chat}->{id} eq $admin->{-telegram_id})
		{
			#	�������������
			$result = $admin->run($message);
			
			print STDOUT Dumper($result);
		}
        else
		{
			#	����������� ������
			$result = send_default($message);
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	������ � �������
		log_update($result) if defined($result);
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�������� ��������� ������������
	---
	log_message(\%message)
		
		%message	- ��������� (���)
=cut
sub log_message
{
	#	��������� (������ �� ���)
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	telegram_id ������������
	my	$telegram_id = $message->{chat}->{id};
	#
	#	������ � ���� ������
	my	$sth = $log_dbh->prepare(qq
		@
			INSERT INTO "logger" (telegram_id, user_name, message)
			VALUES (?, ?, ?)
		@);
		$sth->execute(
			$telegram_id,
			$user->{$telegram_id}->{user_name},
			encode_json($message)
		)
		or Carp::carp $DBI::errstr;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	����� ������������
	---
	log_replay(\%result)
		
		%result		- ��������� ��������� ��������� (���)
=cut
sub log_update
{
	#	��������� ��������� ���������
	my	$result = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��������� ������
	my	$sth = $log_dbh->prepare(qq
		@
			UPDATE "logger" SET result = ?
			WHERE id = (SELECT MAX(id) FROM "logger")
		@);
		$sth->execute(encode_json($result)) or Carp::carp $DBI::errstr;
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
	#	Telegram ID
	my	$telegram_id = $message->{chat}->{id};
	#
	#	������������
	my	$user_name = $user->{$telegram_id}->{user_name} || 'undef';
	#
	#	������ ������������� ���������
	my	$status;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� ���� (����� ����������)
		$status = $api->api_request('sendMessage',
		{
			chat_id		=> $telegram_id,
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
		#	����� �� �����
		Carp::carp "\n������ ��� �������� 'default' ���������: $@\n";
		#
		#	���������� �� ������
		$admin->send_msg('������ ��� �������� "default" ���������', $@);
	}
	else
	{
		printf STDOUT "Unknown message! 'Default' response to Bot has been send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $status;
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
	#	Telegram ID
	my	$telegram_id = $message->{chat}->{id};
	#
	#	������������
	my	$user_name = $user->{$telegram_id}->{user_name} || 'undef';
	#
	#	���������
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������
	my	$keyboard = [[
		{
			text	=> "\x{1F48A} " . decode_win('����������� ��������� �����-�����������'),
			web_app	=> {
#				url	=> 'https://viacheslav-simakov.github.io/med/med.html'
				url	=> $ENV{'HTTP_URL'}
			},
		}
	],];
	#
	#	�������� ���������� ��������������
	push @{ $keyboard }, @{ $admin->keyboard($telegram_id) };
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� ���� (����� ����������)
		$result = $api->api_request('sendMessage',
		{
			chat_id => $telegram_id,
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
		$admin->send_msg('������ ��� �������� "����������"', $@);
		#	����� �� �����
		Carp::carp "\n������ ��� �������� '����������' ����: $@\n";
	}
	else
	{
		printf STDOUT "'reply mark' keyboard to '%s' has been send\n",
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
		$file		- ��� ����� (� ������� �����)
=cut
sub send_file
{
	#	��������� (������ �� ���)
    my	$message = shift @_;
	#	��� PDF-�����
	my	$file = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������
	my	$user_name = $user->{$message->{chat}->{id}}->{user_name} || 'undef';
	#
	#	������������� �������� '\'
		$file =~ s/\\/\//g;
	#
	#	���������
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������������� �����
	unless (-e $file)
	{
		#	��������������!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"file '%s' is not exist!\n",
			(caller(0))[0,1,3], $file;
		#
		#	������� �� �������
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval
	{
		#	�������� �����
		my	$filename = decode_win( sprintf('������������ (%s).pdf', 
				(split '\s', time_stamp())[0]) );
		#
		#	���������� PDF ����
		$result = $api->api_request('sendDocument',
		{
			chat_id		=> $message->{chat}->{id},
#			caption		=> decode_win('������������ �� ���������� ����������'),
			document	=>
			{
				file		=> $file,
				filename	=> $filename,
#				filename	=> $file,
			},
		});
		#	����� �� �����
		printf STDOUT
			"Send file '%s' (%s) to '%s' successed\n",
			encode('windows-1251', $result->{result}->{document}->{file_name}),
			sprintf('%.1f kB', $result->{result}->{document}->{file_size}/1024),
			encode('windows-1251', $user_name);
	};
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		$admin->send_msg('������ ��� �������� �����', $@);
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
		#	�������� ������������ � ���
		$user{ $row->{telegram_id} } = decode_utf8($row);
	}
	#	������� ���� ������
	$dbh->disconnect or Carp::carp $DBI::errstr;
	#
	#	����� �� �����
	print STDOUT "Loading authorized users from 'bot.db' is completed\n";
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
	my	($result, $msg_id);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval
	{
		#	�������� ��������� ������������
		$api->api_request('sendChatAction',
		{
			chat_id	=> $message->{chat}->{id},
			action	=> 'upload_document',
		});
		#	�������� ��������� ������������
		$result = $api->api_request('sendMessage',
		{
			chat_id	=> $message->{chat}->{id},
			text	=> "\x{23F3} " . decode_win('��� ������ ����������� ...'),
		});
		#
		#	id ���������
		$msg_id = $result->{result}->{message_id};
	};
	#	�������� ������
	if ($@)
	{
		#	������� ���������� �� ������
		$admin->send_msg('*������* ��� �������� ��������� ������������', $@);
		#	����� �� �����
		Carp::carp "Error send to User: $@";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��� PDF-�����
	my	$pdf_file_name = sprintf '%s.pdf', $message->{chat}->{id};
	#
	#	������ HTML-�����
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
	#	PDF-��������
	my	$pdf = Med::PDF->new
		(
			$user->{$message->{chat}->{id}},
			decode_json($web_app_data),
			'db/med.db'
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
		$admin->send_msg('*������* �������� PDF-�����', $@);
		#	����� �� �����
		Carp::carp "Error file '$pdf_file_name' created: $@";
	}
	else
	{
		#	��������� ������������ PDF-����
		$result = send_file($message, $pdf_file_name);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ����� ���������
	$api->api_request('editMessageText',
	{
        chat_id		=> $message->{chat}->{id},
        message_id	=> $msg_id,
        text		=> "\x{2935} " . decode_win('���� � ������������ ������� ��������'),
    });
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__DATA__
