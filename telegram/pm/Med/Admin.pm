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

	������������� ����

=cut
package Med::Admin {
#
#	������������� ��������
#	https://perldoc.perl.org/Encode
use Encode qw(encode);
#
#	������� ��� ������
use Med::Tools qw(decode_utf8 decode_win);
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�����������
	---
	$obj = Med::Admin->new($api, $telegram_id, $dbh);

		$api			- ������ API �������� ����
		$telegram_id	- ID Telegram
		$dbh			- ��������� ���� ������
=cut
sub new {
	#	�������� ������
	my	$class = shift @_;
	#	������ API �������� ����
	my	$api = shift @_;
	#	ID Telegram
	my	$telegram_id = shift @_;
	#	��������� ���� ������
	my	$dbh = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ������
	my	$self =
		{
			-bot			=> $api,			# API �������� ����
			-telegram_id	=> $telegram_id,	# telegram ID ������������
			-dbh			=> $dbh,			# ��������� ���� ������
		};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������ � ���� "class"
	return bless $self, $class;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	���������� ��������������
	---
	$obj->keyboard($telegram_id)
	
		$telegram_id	- telegram ID ������������

=cut
sub keyboard
{
	#	������ �� ������
	my	$self = shift @_;
	#	telegram_id
	my	$telegram_id = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������
	my	@keyboard;
	#
	#	�������� ������������
	if ($telegram_id eq $self->{-telegram_id})
	{
		#	������ ������
		@keyboard = (
		[
			{text => "\x{2139} " . decode_win('��������� 10 ��������')},
			{text => "\x{2702} " . decode_win('�������� ������ ��������')},
		],
		[
			{text => "\x{1F4D4} " . decode_win('��������� ���� ������')},
			{text => "\x{267B} " . decode_win('�������� ���� ������')},
		],
		)
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ������
	return \@keyboard;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ���������
	---
	$obj->send_msg($caption, $msg_text)

		$caption	- ��������� ���������
		$msg_text	- ����� ���������
=cut
sub send_msg
{
	#	������ �� ������
	my	$self = shift @_;
	#	��������� ���������
	my	$caption = decode_win(shift @_);
	#	����� ���������
	my	$msg_text = shift @_ || 'undef';
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval {
		#	������� ��������� admin
		$self->{-bot}->api_request('sendMessage',
		{
			chat_id		=> $self->{-telegram_id},
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
		printf STDOUT "Message to Admin has been send\n";
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ����
	---
	$obj->send_file($file_name)
	
		$file_name	- ��� ����� (� ������� �����)
=cut
sub send_file
{
	#	������ �� ������
	my	$self = shift @_;
	#	��� PDF-�����
	my	$file_name = shift @_;
	#	������������� �������� '\'
		$file_name =~ s/\\/\//g;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������������� �����
	unless (-e $file_name)
	{
		#	��������������!
		Carp::carp "���� '$file_name' �� ����������\n";
		#
		#	������� �� �������
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	���������� �����������
	eval
	{
		#	���������� PDF ����
		$self->{-bot}->api_request('sendDocument',
		{
			chat_id		=> $self->{-telegram_id},
			document	=>
			{
				file		=> $file_name,
				filename	=> $file_name,
			},
		})
	};
	#	�������� ������
	if ($@)
	{
		#	��������������
		Carp::carp "\n������ ��� �������� �����: $@\n";
	}
	else
	{
		printf STDOUT "File '$file_name' has to be send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ��� ����� ���� ������
	---
	download_db
=cut
sub download_db
{
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��������� ����� ��� ������
	$self->send_file('db/med.db');
	$self->send_file('db/med-extra.db');
	$self->send_file('db/user.db');
	$self->send_file('db/log.db');
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� 10 ������� � ������� ��������
	---
	$obj->last_log()
	
=cut
sub last_log
{
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��������� �������
	my	$sth = $self->{-dbh}->prepare(qq
		@
		SELECT * FROM (
			SELECT * FROM
			(
				SELECT id, telegram_id, user_name, time(time_stamp) as time,
					json_extract(message, '\$.text') as action
				FROM "logger"
				WHERE action NOT NULL
			UNION
				SELECT id, telegram_id, user_name, time(time_stamp) as time,
					json_extract(result, '\$.result.document.file_name') as action
				FROM "logger"
				WHERE action NOT NULL
			)
			ORDER BY id DESC LIMIT 10
		)
		ORDER BY id ASC
		@);
		$sth->execute() or Carp::carp $DBI::errstr;
	#
	#	���������� � ��������
	my	$log;
	#
	#	���� �� ��������� �������
	while (my $row = $sth->fetchrow_hashref)
	{
		#	������������
		decode_utf8($row);
		#
		#	������������ ������� 'Markdown'
		$row->{action} =~ s/[_\*\~]/ /g;
		#
		#	�������� � ����� ������
		$log .= sprintf "\x{26A1} *%s* (%s)\n`%s`\n\n",
			$row->{user_name} || 'undef', $row->{time}, $row->{action};
	}
	#
	#	��������� ������ ��������
	$self->send_msg('_������ ��������_', $log);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�������� ������ �������� (����� 10 ��������� �������)
	---
	$obj->truncate_log()
=cut
sub truncate_log
{
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������
	$self->{-dbh}->do(qq
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
	$self->send_msg('*������ ��������* ������', ($DBI::errstr
		? "\x{1F6AB} DBI err='$DBI::errstr'"
		: "\x{2705} " . decode_win("������� ��� ������, ����� 10 ��������� ")));
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ��������
	---
	$obj->run($message);
	
		$message	- ������ �� ��������� (���)

=cut
sub run
{
	#	������ �� ������
	my	$self = shift @_;
	#	��������� (������ �� ���)
	my	$message = shift @_;
	#	�������� ���� ��������������
	return undef if
	(
		$message->{chat}->{id} ne $self->{-telegram_id}) ||
		!defined($message->{text}
	);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������� ������ ���������
	my	$text = encode('windows-1251', $message->{text});
	#
	#	������� ������ 2 ������� (�����)
		$text =~ s/^..//;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����� ��������������
	if ($text eq '��������� ���� ������')
	{
		#	��������� ����� ��� ������
		$self->download_db();
	}
	elsif ($text eq '�������� ���� ������')
	{
		#	����������� ���� ������
		my	$err = system('perl',
			'lib/make_html.pl', $ENV{'DB_FOLDER'}, 'html');
		#
		#	�������������� ���������
		$self->send_msg(
			'*���������� ���� ������*',
			decode_win("��� ����������: ($err)\n������: ($?)\n������: '$!'"));
		#
		#	��������� ����� ���� ������
		$self->download_db();
	}
	elsif ($text eq '��������� 10 ��������')
	{
		#	��������� 10 ������� � ������� ��������
		$self->last_log();
	}
	elsif ($text eq '�������� ������ ��������')
	{
		#	�������� ������ �������� (����� 10 ��������� �������)
		$self->truncate_log();
	}
	else
	{
		#	����������� �������
		$self->send_msg('*����������� �������*', $message->{text});
	}
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
