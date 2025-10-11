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
use Encode;# qw(decode encode);
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
my	$log_dbh = DBI->connect("dbi:SQLite:dbname=log.db","","")
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
my	$user = users_authorized();
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
			send_error(sprintf 'Access denied for id=(%s)', $message->{chat}->{id} || 'unknow');
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
			$result = unknow($message);
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	������ � ������
		logger($message, $result);
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
	#	��������� ��������� ���������
	my	$result = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
	send_error($error, $debug)

		$error	- ��������� �� ������
		$debug	- ���������� ����������
=cut
sub send_error
{
	#	��������� �� ������
	my	$error = shift @_;
	#	���������� ����������
	my	$debug = shift @_;
	if (!defined $debug)
	{
		$debug = sprintf(
			"*ERROR*\npackage = '%s', line = %d", (caller(1))[1,2])
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� admin
		$api->api_request('sendMessage',
		{
			chat_id		=> '5483130027',# �������
			parse_mode	=> 'Markdown',
			text		=> sprintf("%s\n%s", $debug, $error),
		})
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		Carp::carp "\n������ ��� �������� 'error' ���������: $@\n";
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
	unknow($message)

		$message	- ������ �� ��������� (���)
=cut
sub unknow
{
	#	��������� (������ �� ���)
	my	$message = shift @_;
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
		send_error($@);
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
	#	���������
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������
	my	$keyboard = [[
		{
			text	=> "\x{1F48A} " . decode('windows-1251',
						'����������� ��������� �����-�����������'),
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
				{text => "\x{2139} " . decode('windows-1251', '��������� 10 ��������')},
				{text => "\x{274C} " . decode('windows-1251', '�������� ������ ��������')},
			],
			[
				{text => "\x{1F4D4} " . decode('windows-1251', '�������� ������ ��������')},
				{text => "\x{267B} " . decode('windows-1251', '�������� ���� ������')},
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
			text => decode('windows-1251',
				"*����������� ��������� �����-�����������*\n(���� ����� �.�. ������������)"),
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
		send_error($@);
		#	����� �� �����
		Carp::carp "\n������ ��� �������� '����������' ����: $@\n";
	}
	else
	{
		printf STDERR "'reply mark' keyboard to Bot has been send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $result;
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
		send_error($@);
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
			caption		=> decode('windows-1251','���� ����� �.�. ������������'),
			document	=>
			{
				file		=> $file_name,
#				filename	=> decode('windows-1251', '������������.pdf'),
				filename	=> $file_name,
			},
		});
		#	����� �� �����
		printf STDERR
			"Send file '%s' (%s) into chat id='%s' successed\n",
			$result->{result}->{document}->{file_name},
			sprintf('%.1f kB', $result->{result}->{document}->{file_size}/1024),
			$message->{chat}->{id};
	};
	#	�������� ������
	if ($@)
	{
		#	���������� �� ������
		send_error($@);
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
sub users_authorized
{
	#	������ �������������
	my	%user = ();
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� ���� ������
	my	$dbh = DBI->connect("dbi:SQLite:dbname=bot.db","","")
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
		#	���� �� ������ ����
		foreach (keys %{ $row })
		{
			#	������������ ������ �� "UTF-8"
			$row->{$_} = decode('UTF-8', $row->{$_});
		}
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
		#	���� �������
		send_file($message, 'log.db');
		#
		#	������������
		send_file($message, 'bot.db');
	}
	elsif ($text eq '�������� ���� ������')
	{
		#	����������� ���� ������
		my	$err = system('perl',
			'pl/make_html.pl', $ENV{'DB_FILE'}, $ENV{'HTML_FOLDER'});
		#
		#	����������
		send_error(decode('windows-1251',
			"*���������� ���� ������*\nerrno=($err)\n"), $!);
		#
		#	������� ���� ���� ������
		send_file($message, $ENV{'DB_FILE'});
	}
	elsif ($text eq '��������� 10 ��������')
	{
		#	��������� 10 ������� � ������� ��������
		my	$sth = $log_dbh->prepare(qq
			@
				SELECT * FROM logger ORDER BY id DESC LIMIT 10
			@);
			$sth->execute() or Carp::carp $DBI::errstr;
		#
		#	���������� � ��������
		my	$log;
		#
		#	���� �� ��������� �������
		while (my $row = $sth->fetchrow_hashref)
		{
			#	�������� � ����� ������
			$log .= sprintf "*%s* (%s)\n",
				$user->{ $row->{telegram_id} }->{user_name},
				$row->{time_stamp};
		}
		#
		#	��������� ������ �������� ����
		send_error($log, decode('windows-1251',"_������ ��������_"));
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
	}
	else
	{
		#	����������� �������
		send_error(
			decode('windows-1251', "*����������� �������*"),
			$message->{text});
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__DATA__
