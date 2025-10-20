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
#	Декодирование символов
#	https://perldoc.perl.org/Encode
use Encode qw(encode);
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
	return bless($self, $class);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Клавиатура администратора
	---
	$obj->keyboard($telegram_id)
	
		$telegram_id	- telegram ID пользователя

=cut
sub keyboard
{
	#	ссылка на объект
	my	$self = shift @_;
	#	telegram_id
	my	$telegram_id = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	клавиатура
	my	@keyboard;
	#
	#	Проверка пользователя
	if ($telegram_id eq $self->{-telegram_id})
	{
		#	список кнопок
		@keyboard = (
		[
			{text => "\x{2139} " . decode_win('Последние 10 запросов')},
			{text => "\x{2702} " . decode_win('Очистить журнал запросов')},
		],
		[
			{text => "\x{1F4D4} " . decode_win('Запросить базы данных')},
			{text => "\x{267B} " . decode_win('Обновить базу данных')},
		],
		)
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на список
	return \@keyboard;
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
	#	Ответ
	my	$response;
	#
	#	Безопасная конструкция
	eval {
		#	Послать сообщение admin
		$response = $self->{-bot}->api_request('sendMessage',
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
		printf STDOUT "Message to Admin has been send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $response;
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
	#	Ответ
	my	$response;
	#
	#	Безопасная конструкция
	eval
	{
		#	Отправляем PDF файл
		$response = $self->{-bot}->api_request('sendDocument',
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
		#	предупреждение
		Carp::carp "\nОшибка при отправке файла: $@\n";
	}
	else
	{
		printf STDOUT "File '$file_name' has to be send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $response;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Отправить все файлы базы данных
	---
	download_db
=cut
sub download_db
{
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Результат
	my	$result;
	#
	#	список файлов баз данных
	foreach my $file ('med.db', 'med-extra.db', 'user.db', 'log.db')
	{
		#	переслать файл
		push @{ $result->{-db} }, $self->send_file(sprintf 'db/%s', $file);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $result;
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
				SELECT id, telegram_id, user_name, time_stamp,
					json_extract(message, '\$.text') as action
				FROM "logger"
				WHERE action NOT NULL
			UNION
				SELECT id, telegram_id, user_name, time_stamp,
					json_extract(result, '\$.result.document.file_name') as action
				FROM "logger"
				WHERE action NOT NULL
			)
			WHERE (telegram_id != ?) ORDER BY id DESC LIMIT 10
		)
		ORDER BY id ASC
		@);
		$sth->execute($self->{-telegram_id}) or Carp::carp $DBI::errstr;
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
		$row->{action} =~ s/[_\*\~]/ /g;
		#
		#	Добавить в конец списка
		$log .= sprintf "\x{26A1} *%s* (%s)\n`%s`\n\n",
			$row->{user_name} || 'undef', $row->{time_stamp}, $row->{action};
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	отправить журнал запросов
	return $self->send_msg('_Журнал запросов_', $log);
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
	my	$sth = $self->{-dbh}->prepare(qq
		@
			DELETE FROM "logger"
			WHERE id NOT IN (
				SELECT id FROM "logger"
				WHERE (telegram_id != ?)
				ORDER BY id DESC LIMIT 10
			)
		@);
		$sth->execute($self->{-telegram_id}) or Carp::carp $DBI::errstr;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Сообщение
	return $self->send_msg('*Журнал запросов* очищен', ($DBI::errstr
		? "\x{1F6AB} DBI err='$DBI::errstr'"
		: "\x{2705} " . decode_win("удалены все записи, кроме 10 последних ")));
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Обработка запросов
	---
	$obj->run($message);
	
		$message	- ссылка на сообщение (хэш)

=cut
sub run
{
	#	ссылка на объект
	my	$self = shift @_;
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#	проверка прав администратора
	return undef if
	(
		$message->{chat}->{id} ne $self->{-telegram_id}) ||
		!defined($message->{text}
	);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	кодирование текста сообщения
	my	$text = encode('windows-1251', $message->{text});
	#
	#	удалить первые 2 символа (ВАЖНО)
		$text =~ s/^..//;
	#
	#	Результат
	my	$res;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Ответ Администратору
	if ($text eq 'Запросить базы данных')
	{
		#	переслать файлы баз данных
		$res = $self->download_db();
	}
	elsif ($text eq 'Обновить базу данных')
	{
		#	копирование базы данных
		my	$err = system('perl',
			'lib/make_html.pl', $ENV{'DB_FOLDER'}, 'html');
		#
		#	информационное сообщение
		$res->{-html_update} = $self->send_msg(
			'*Обновление базы данных*',
			decode_win("код завершения: ($err)\nстатус: ($?)\nошибка: '$!'"));
		#
		#	переслать файлы базы данных и объединить хэши
		%{ $res } = (%{ $res }, %{ $self->download_db() });
	}
	elsif ($text eq 'Последние 10 запросов')
	{
		#	Последние 10 записей в журнале запросов
		$res = $self->last_log();
	}
	elsif ($text eq 'Очистить журнал запросов')
	{
		#	очистить журнал запросов (кроме 10 последних записей)
		$res = $self->truncate_log();
	}
	else
	{
		#	неизвестная команда
		$res = $self->send_msg('*Неизвестная команда*', $message->{text});
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $res;
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
