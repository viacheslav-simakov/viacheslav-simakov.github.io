#
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Альтернатива 'warn' и 'die' для модулей
#	https://perldoc.perl.org/Carp
use Carp();
#
#	Строковые структуры данных Perl, подходящие как для печати
#	https://metacpan.org/pod/Data::Dumper
use	Data::Dumper;
#
#	Декодирование символов
#	https://perldoc.perl.org/Encode
use Encode qw(encode);
#
#	JSON (JavaScript Object Notation) кодирование/декодирование
#	https://metacpan.org/pod/JSON
use	JSON qw(encode_json decode_json);
#
#	Телеграм-Бот
#	https://metacpan.org/pod/WWW::Telegram::BotAPI
use WWW::Telegram::BotAPI;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	папки библиотек (модулей)
#	'.' = текущая папка!
use lib ('pm');
#
#	Утилиты для работы
use Med::Tools qw(decode_utf8 decode_win time_stamp);
#
#	PDF-документы
use Med::PDF();
#
#	Администратор
use Med::Admin();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	проверка доступности файлов и папок
#
unless (-d $ENV{'DB_FOLDER'})
{
	Carp::confess "Папка '$ENV{'DB_FOLDER'}' базы данных не существует\n";
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	Бот @tele_rheumatology_bot
#	Токен (получите у @BotFather)
#
my	$token = '8278981933:AAGOZMWywJZxlR-Vj5kwh4HeISQhwPpXuwE';
#
#	Создаем объект API
my	$api = WWW::Telegram::BotAPI->new(token => $token);
#
#	Обновления
my	$updates;
#
#	Получаем последние обновления
my	$offset = 0;
#
#	Список авторизованных пользователей (ссылка на хэш)
my	$user = user_authorized();
#
#	Журнал
my	$log_dbh = DBI->connect("dbi:SQLite:dbname=db/log.db","","")
		or Carp::confess $DBI::errstr;
#
#	Администратор
my	$admin = Med::Admin->new($api, '5483130027', $log_dbh);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	Главный цикл обработки событий бота
#
printf STDOUT "Telegram Bot \@tele_rheumatology_bot is started at %s\n", time_stamp();
#	Tele_PDF::time_stamp();
	
while (1) {
	#	задержка 1 секунда
#	sleep(1);
	#	Безопасная конструкция
	eval {
		#	Получаем обновления
		$updates = $api->getUpdates(
			{
				offset	=> $offset,	# Смещение
				timeout	=> 30,		# Determines the timeout in seconds for long polling
			}
		)
	};
	#	Проверка ошибок
	if ($@)
	{
		#	информации об ошибке
		Carp::carp sprintf(
			"\n%s Ошибка при получении обновлений: $@\n", time_stamp());
		#	следующее обновление
		next;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #
    #	Обрабатываем каждое обновление
	#
    foreach my $update (@{ $updates->{result} })
	{
		#	Увеличиваем смещение
        $offset = $update->{update_id} + 1 if $update->{update_id} >= $offset;
        #
		#	Сообщение
        my	$message = $update->{message} or next;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	Проверка ID пользователя
		if (!exists $user->{ $message->{chat}->{id} })
		{
			#	информация об ошибке
			$admin->send_msg('*Access denied*',
				sprintf('telegram id=(%s)', $message->{chat}->{id} || 'unknow'));
			#
			#	вывод на экран
			Carp::carp "Access denied\n";
			#	следующее обновление
			next;
		}
		#	Вывод на экран
		printf STDOUT "\nUpdate at %s (%s)\n", time_stamp(),
			encode('windows-1251', $user->{$message->{chat}->{id}}->{user_name});
		#
		#	Запись в Журнал
		log_message($message);
		#
		#	Результат обработки сообщения
		my	$result = undef;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#
        #	Обработка команд
		#
		if ($message->{web_app_data}->{data})
		{
			#	данные Web App
			$result = user_request($message);
		}
		elsif (!defined $message->{text})
		{
			#	отсутствует текст сообщения
			next;
		}
        elsif ($message->{text} =~ m{^/start}i)
		{
			#	клавиатура
			$result = send_keyboard($message);
        }
		elsif ($message->{chat}->{id} eq $admin->{-telegram_id})
		{
			#	Администратор
			$result = $admin->run($message);
			
			print STDOUT Dumper($result);
		}
        else
		{
			#	неизвестный запрос
			$result = send_default($message);
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	запись в журнале
		log_update($result) if defined($result);
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Входящее сообщение Пользователя
	---
	log_message(\%message)
		
		%message	- сообщение (хэш)
=cut
sub log_message
{
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	telegram_id пользователя
	my	$telegram_id = $message->{chat}->{id};
	#
	#	Запись в базу данных
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
	Ответ Пользователю
	---
	log_replay(\%result)
		
		%result		- результат обработки сообщения (хэш)
=cut
sub log_update
{
	#	Результат обработки сообщения
	my	$result = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Изменение записи
	my	$sth = $log_dbh->prepare(qq
		@
			UPDATE "logger" SET result = ?
			WHERE id = (SELECT MAX(id) FROM "logger")
		@);
		$sth->execute(encode_json($result)) or Carp::carp $DBI::errstr;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Неизвестное сообщение
	---
	send_default($message)

		$message	- ссылка на сообщение (хэш)
=cut
sub send_default
{
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Telegram ID
	my	$telegram_id = $message->{chat}->{id};
	#
	#	Пользователь
	my	$user_name = $user->{$telegram_id}->{user_name} || 'undef';
	#
	#	Статус отправленного сообщения
	my	$status;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение боту (вывод клавиатуры)
		$status = $api->api_request('sendMessage',
		{
			chat_id		=> $telegram_id,
			parse_mode	=> 'Markdown',
			text		=> decode_win(sprintf(
				"Привет _%s_!\nЯ бот *Электронный ассистент врача-ревматолога*.\n".
				"Используйте /start для начала работы.",
				encode('windows-1251', $user_name))
			),
		});
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка ошибок
	if ($@)
	{
		#	вывод на экран
		Carp::carp "\nОшибка при отправке 'default' сообщения: $@\n";
		#
		#	информация об ошибке
		$admin->send_msg('Ошибка при отправке "default" сообщения', $@);
	}
	else
	{
		printf STDOUT "Unknown message! 'Default' response to Bot has been send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $status;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Клавиатура Бота
	---
	\%result = send_keyboard( \%message )
		
		%message	- сообщение (хэш)
		%result		- результат отправки (хэш)
=cut
sub send_keyboard
{
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Telegram ID
	my	$telegram_id = $message->{chat}->{id};
	#
	#	Пользователь
	my	$user_name = $user->{$telegram_id}->{user_name} || 'undef';
	#
	#	результат
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Клавиатура
	my	$keyboard = [[
		{
			text	=> "\x{1F48A} " . decode_win('Электронный ассистент врача-ревматолога'),
			web_app	=> {
#				url	=> 'https://viacheslav-simakov.github.io/med/med.html'
				url	=> $ENV{'HTTP_URL'}
			},
		}
	],];
	#
	#	добавить клавиатуру Администратора
	push @{ $keyboard }, @{ $admin->keyboard($telegram_id) };
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение боту (вывод клавиатуры)
		$result = $api->api_request('sendMessage',
		{
			chat_id => $telegram_id,
			parse_mode => 'Markdown',
			text => decode_win("*Электронный ассистент врача-ревматолога*\n(СГМУ имени В.И. Разумовского)"),
			reply_markup =>
			{
				keyboard => $keyboard,
				resize_keyboard => \1,
				one_time_keyboard => \0,
			},
		});
	};
	#	Проверка ошибок
	if ($@)
	{
		#	информация об ошибке
		$admin->send_msg('Ошибка при отправке "клавиатуры"', $@);
		#	вывод на экран
		Carp::carp "\nОшибка при отправке 'клавиатуры' Бота: $@\n";
	}
	else
	{
		printf STDOUT "'reply mark' keyboard to '%s' has been send\n",
			encode('windows-1251', $user_name);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Отправить файл
	---
	send_file(\%message, $file_name)
	
		%message	- сообщение (хэш)
		$file		- имя файла (в текущей папке)
=cut
sub send_file
{
	#	сообщение (ссылка на хэш)
    my	$message = shift @_;
	#	имя PDF-файла
	my	$file = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	пользователь
	my	$user_name = $user->{$message->{chat}->{id}}->{user_name} || 'undef';
	#
	#	экранирование символов '\'
		$file =~ s/\\/\//g;
	#
	#	результат
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка существование файла
	unless (-e $file)
	{
		#	предупреждение!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"file '%s' is not exist!\n",
			(caller(0))[0,1,3], $file;
		#
		#	возврат из функции
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval
	{
		#	название файла
		my	$filename = decode_win( sprintf('Рекомендации (%s).pdf', 
				(split '\s', time_stamp())[0]) );
		#
		#	Отправляем PDF файл
		$result = $api->api_request('sendDocument',
		{
			chat_id		=> $message->{chat}->{id},
#			caption		=> decode_win('Рекомендации по применению препаратов'),
			document	=>
			{
				file		=> $file,
				filename	=> $filename,
#				filename	=> $file,
			},
		});
		#	Вывод на экран
		printf STDOUT
			"Send file '%s' (%s) to '%s' successed\n",
			encode('windows-1251', $result->{result}->{document}->{file_name}),
			sprintf('%.1f kB', $result->{result}->{document}->{file_size}/1024),
			encode('windows-1251', $user_name);
	};
	#	Проверка ошибок
	if ($@)
	{
		#	информация об ошибке
		$admin->send_msg('Ошибка при отправке файла', $@);
		#	вывод на экран
		Carp::carp "\nОшибка при отправке файла: $@\n";
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Список авторизированных пользователей
	---
	\%user = user_authorized()
	
=cut
sub user_authorized
{
	#	Список пользователей
	my	%user = ();
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	открыть базу данных
	my	$dbh = DBI->connect("dbi:SQLite:dbname=db/user.db","","")
			or Carp::confess $DBI::errstr;
	#
	#	SQL-запрос
	my	$sth = $dbh->prepare('SELECT * FROM "user"')
			or Carp::confess "Ошибка запроса к таблице пользователей";
	#
	#	Выполнить запрос к таблице
		$sth->execute;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		#	Добавить пользователя в хэш
		$user{ $row->{telegram_id} } = decode_utf8($row);
	}
	#	Закрыть базу данных
	$dbh->disconnect or Carp::carp $DBI::errstr;
	#
	#	Вывод на экран
	print STDOUT "Loading authorized users from 'bot.db' is completed\n";
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return \%user;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Обработка данных HTML-формы полученных из Web App
	---
	user_request( \%message )
	
		%message	- сообщение (хэш)

=cut
sub user_request
{
	#	сообщение (ссылка на хэш)
    my	$message = shift @_;
	#	результат
	my	($result, $msg_id);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval
	{
		#	отправка сообщения Пользователю
		$api->api_request('sendChatAction',
		{
			chat_id	=> $message->{chat}->{id},
			action	=> 'upload_document',
		});
		#	отправка сообщения Пользователю
		$result = $api->api_request('sendMessage',
		{
			chat_id	=> $message->{chat}->{id},
			text	=> "\x{23F3} " . decode_win('Ваш запрос выполняется ...'),
		});
		#
		#	id сообщения
		$msg_id = $result->{result}->{message_id};
	};
	#	Проверка ошибок
	if ($@)
	{
		#	послать информацию об ошибке
		$admin->send_msg('*Ошибка* при отправке сообщения Пользователю', $@);
		#	вывод на экран
		Carp::carp "Error send to User: $@";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	имя PDF-файла
	my	$pdf_file_name = sprintf '%s.pdf', $message->{chat}->{id};
	#
	#	Данные HTML-формы
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
	#	PDF-документ
	my	$pdf = Med::PDF->new
		(
			$user->{$message->{chat}->{id}},
			decode_json($web_app_data),
			'db/med.db'
		);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval
	{
		#	Создать PDF-файл
		$pdf->save($pdf_file_name);
	};
	#	Проверка ошибок
	if ($@)
	{
		#	послать информацию об ошибке
		$admin->send_msg('*Ошибка* создания PDF-файла', $@);
		#	вывод на экран
		Carp::carp "Error file '$pdf_file_name' created: $@";
	}
	else
	{
		#	Отправить пользователю PDF-файл
		$result = send_file($message, $pdf_file_name);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Изменить текст сообщения
	$api->api_request('editMessageText',
	{
        chat_id		=> $message->{chat}->{id},
        message_id	=> $msg_id,
        text		=> "\x{2935} " . decode_win('Файл с результатами запроса загружен'),
    });
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__DATA__
