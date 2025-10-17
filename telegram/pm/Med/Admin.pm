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
		printf STDERR "Message to Admin has been send\n";
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
		#	���������� �� ������
		send_admin('������ ��� �������� �����', $@);
		#	����� �� �����
		Carp::carp "\n������ ��� �������� �����: $@\n";
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������������ ��������
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ����� ��� ������
	---
	$obj->send_database()
	
=cut
sub send_database
{
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��������� ����� ��� ������
	$self->send_file('db/med.db');
	$self->send_file('db/med-extra.db');
	$self->send_file('db/user.db');
	$self->send_file('db/log.db');
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
		$row->{reply} =~ s/[_\*\~]/ /g;
		#
		#	�������� � ����� ������
		$log .= sprintf "*%s* (%s)\n`%s`\n\x{26A1} %s\n",
			$user->{ $row->{telegram_id} }->{user_name},
			$row->{time}, $row->{request}, $row->{reply};
	}
	#
	#	��������� ������ �������� ����
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
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
