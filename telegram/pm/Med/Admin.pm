#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#	Альтернатива 'warn' и 'die' для модулей
#	https://perldoc.perl.org/Carp
use Carp();
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
=pod

	Администратор Бота

=cut
package Med::Admin {
#
#	Утилиты для работы
use Med::Tools qw(decode_utf8 decode_win);
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Конструктор
	---
	$obj = Med::Admin->new($api, $telegram_id, $dbh);

		$api			- объект API Телеграм Бота
		$telegram_id	- ID Telegram
		$dbh			- указатель базы данных
=cut
sub new {
	#	название класса
	my	$class = shift @_;
	#	объект API Телеграм Бота
	my	$api = shift @_;
	#	ID Telegram
	my	$telegram_id = shift @_;
	#	указатель базы данных
	my	$dbh = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на объект
	my	$self =
		{
			-bot			=> $api,			# API Телеграм Бота
			-telegram_id	=> $telegram_id,	# telegram ID пользователя
			-dbh			=> $dbh,			# указатель базы данных
		};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	привести ссылку к типу "class"
	return bless $self, $class;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Отправить сообщение
	---
	$obj->send_msg($caption, $msg_text)

		$caption	- заголовок сообщения
		$msg_text	- текст сообщения
=cut
sub send_msg
{
	#	ссылка на объект
	my	$self = shift @_;
	#	заголовок сообщения
	my	$caption = decode_win(shift @_);
	#	текст сообщения
	my	$msg_text = shift @_ || 'undef';
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение admin
		$self->{-bot}->api_request('sendMessage',
		{
			chat_id		=> $self->{-telegram_id},
			parse_mode	=> 'Markdown',
			text		=> sprintf("%s\n%s", $caption, $msg_text),
		})
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка ошибок
	if ($@)
	{
		#	информации об ошибке
		Carp::carp "\nОшибка при отправке сообщения Администратору: $@\n";
	}
	else
	{
		printf STDERR "Message to Admin has been send\n";
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Отправить файл
	---
	$obj->send_file($file_name)
	
		$file_name	- имя файла (в текущей папке)
=cut
sub send_file
{
	#	ссылка на объект
	my	$self = shift @_;
	#	имя PDF-файла
	my	$file_name = shift @_;
	#	экранирование символов '\'
		$file_name =~ s/\\/\//g;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка существование файла
	unless (-e $file_name)
	{
		#	предупреждение!
		Carp::carp "Файл '$file_name' не существует\n";
		#
		#	возврат из функции
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval
	{
		#	Отправляем PDF файл
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
	#	Проверка ошибок
	if ($@)
	{
		#	информация об ошибке
		send_admin('Ошибка при отправке файла', $@);
		#	вывод на экран
		Carp::carp "\nОшибка при отправке файла: $@\n";
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Переслать файлы баз данных
	---
	$obj->send_database()
	
=cut
sub send_database
{
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	переслать файлы баз данных
	$self->send_file('db/med.db');
	$self->send_file('db/med-extra.db');
	$self->send_file('db/user.db');
	$self->send_file('db/log.db');
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Последние 10 записей в журнале запросов
	---
	$obj->last_log()
	
=cut
sub last_log
{
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	указатель таблицы
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
	#	информация о запросах
	my	$log;
	#
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		#	декодировать
		decode_utf8($row);
		#
		#	экранировать символы 'Markdown'
		$row->{reply} =~ s/[_\*\~]/ /g;
		#
		#	Добавить в конец списка
		$log .= sprintf "*%s* (%s)\n`%s`\n\x{26A1} %s\n",
			$user->{ $row->{telegram_id} }->{user_name},
			$row->{time}, $row->{request}, $row->{reply};
	}
	#
	#	отправить журнал запросов Боту
	$self->send_msg('_Журнал запросов_', $log);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Очистить журнал запросов (кроме 10 последних записей)
	---
	$obj->truncate_log()
=cut
sub truncate_log
{
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Очистить журнал
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
	#	Сообщение
	$self->send_msg('*Журнал запросов* очищен', ($DBI::errstr
		? "\x{1F6AB} DBI err='$DBI::errstr'"
		: "\x{2705} " . decode_win("удалены все записи, кроме 10 последних ")));
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $self;
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
