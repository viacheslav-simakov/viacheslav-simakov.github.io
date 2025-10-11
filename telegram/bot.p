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
use Encode;# qw(decode encode);
#
#	JSON (JavaScript Object Notation) кодирование/декодирование
#	https://metacpan.org/pod/JSON
use	JSON;
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
#	PDF-документы
use Tele_PDF();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	проверка доступности файлов и папок
#
unless (-e $ENV{'DB_FILE'})
{
	Carp::confess "Файл '$ENV{'DB_FILE'}' базы данных не существует\n";
}
unless (-d $ENV{'HTML_FOLDER'})
{
	Carp::confess "Папка '$ENV{'HTML_FOLDER'}' для копирования не существует\n";
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#	открыть базу данных
my	$log_dbh = DBI->connect("dbi:SQLite:dbname=log.db","","")
		or Carp::confess $DBI::errstr;
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
my	$user = users_authorized();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#	Главный цикл обработки событий бота
#
printf STDERR "Telegram Bot \@tele_rheumatology_bot is started at %s\n",
	Tele_PDF::time_stamp();
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
		Carp::carp sprintf("\n%s Ошибка при получении обновлений: $@\n",
			Tele_PDF::time_stamp());
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
			send_error(sprintf 'Access denied for id=(%s)', $message->{chat}->{id} || 'unknow');
			#
			#	вывод на экран
			Carp::carp "Access denied\n";
			#	следующее обновление
			next;
		}
		#	Вывод на экран
		printf STDERR "\nUpdate at %s (%s)\n", Tele_PDF::time_stamp(),
			encode('windows-1251', $user->{$message->{chat}->{id}}->{user_name});
		#
		#	Результат обработки сообщения
		my	$result = {};
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
		elsif ($message->{chat}->{id} eq '5483130027')
		{
			#	Администратор
			$result = admin($message);
		}
        else
		{
			#	неизвестный запрос
			$result = unknow($message);
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	запись в журнал
		logger($message, $result);
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Вывод на экран
	---
	logger(\%message, \%result)
		
		%message	- сообщение (хэш)
		%result		- результат обработки сообщения (хэш)
=cut
sub logger
{
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#	результат обработки сообщения
	my	$result = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	telegram_id пользователя
	my	$telegram_id = $message->{chat}->{id};
	#
	#	Запись в базу данных
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
	Сообщение об ошибке
	---
	send_error($error, $debug)

		$error	- сообщение об ошибке
		$debug	- отладочная информация
=cut
sub send_error
{
	#	сообщение об ошибке
	my	$error = shift @_;
	#	отладочная информация
	my	$debug = shift @_;
	if (!defined $debug)
	{
		$debug = sprintf(
			"*ERROR*\npackage = '%s', line = %d", (caller(1))[1,2])
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение admin
		$api->api_request('sendMessage',
		{
			chat_id		=> '5483130027',# Симаков
			parse_mode	=> 'Markdown',
			text		=> sprintf("%s\n%s", $debug, $error),
		})
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка ошибок
	if ($@)
	{
		#	информации об ошибке
		Carp::carp "\nОшибка при отправке 'error' сообщения: $@\n";
	}
	else
	{
		printf STDERR "Message to Admin has been send\n";
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Неизвестное сообщение
	---
	unknow($message)

		$message	- ссылка на сообщение (хэш)
=cut
sub unknow
{
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#	результат
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение боту (вывод клавиатуры)
		$result = $api->api_request('sendMessage',
		{
			chat_id		=> $message->{chat}->{id},
			parse_mode	=> 'Markdown',
			text		=> decode('windows-1251', sprintf(
				"Привет _%s_!\nЯ бот *Электронный ассистент врача-ревматолога*.\n".
				"Используйте /start для начала работы.",
				encode('windows-1251', ($message->{from}->{first_name} || 'unknow')))
			),
		});
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка ошибок
	if ($@)
	{
		#	информация об ошибке
		send_error($@);
		#	вывод на экран
		Carp::carp "\nОшибка при отправке 'default' сообщения: $@\n";
	}
	else
	{
		printf STDERR "Unknown message! 'Default' response to Bot has been send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $result;
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
	#	результат
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Клавиатура
	my	$keyboard = [[
		{
			text	=> "\x{1F48A} " . decode('windows-1251',
						'Электронный ассистент врача-ревматолога'),
			web_app	=> {
				url	=> 'https://viacheslav-simakov.github.io/med/med.html'
			},
		}
	],];
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Администратор
	if ($message->{chat}->{id} eq '5483130027')
	{
		#	клавиатура администратора
		my	@admin = (
			[
				{text => "\x{2139} " . decode('windows-1251', 'Последние 10 запросов')},
				{text => "\x{274C} " . decode('windows-1251', 'Очистить журнал запросов')},
			],
			[
				{text => "\x{1F4D4} " . decode('windows-1251', 'Получить журнал запросов')},
				{text => "\x{267B} " . decode('windows-1251', 'Обновить базу данных')},
			],
			);
		#	добавить клавиатуру
		push @{ $keyboard }, @admin;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение боту (вывод клавиатуры)
		$result = $api->api_request('sendMessage',
		{
			chat_id => $message->{chat}->{id},
			parse_mode => 'Markdown',
			text => decode('windows-1251',
				"*Электронный ассистент врача-ревматолога*\n(СГМУ имени В.И. Разумовского)"),
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
		send_error($@);
		#	вывод на экран
		Carp::carp "\nОшибка при отправке 'клавиатуры' Бота: $@\n";
	}
	else
	{
		printf STDERR "'reply mark' keyboard to Bot has been send\n";
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	возвращаемое значение
	return $result;
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
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	имя PDF-файла
	my	$pdf_file_name = sprintf '%s.pdf', $message->{chat}->{id};
	#
	#	Данные HTML-формы
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
	#	PDF-документ
	my	$pdf = Tele_PDF->new(
			$user->{$message->{chat}->{id}},
			decode_json($web_app_data)
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
		send_error($@);
		#	вывод на экран
		Carp::carp "Error file '$pdf_file_name' created: $@";
	}
	else
	{
		#	Отправить пользователю PDF-файл
		$result = send_file($message, $pdf_file_name);
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
		$file_name	- имя файла (в текущей папке)
=cut
sub send_file
{
	#	сообщение (ссылка на хэш)
    my	$message = shift @_;
	#	имя PDF-файла
	my	$file_name = shift @_;
	#	результат
	my	$result;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка существование файла
	unless (-e $file_name)
	{
		#	предупреждение!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"file '%s' is not exist!\n",
			(caller(0))[0,1,3], $file_name;
		#
		#	возврат из функции
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval
	{
		#	Отправляем PDF файл
		$result = $api->api_request('sendDocument',
		{
			chat_id		=> $message->{chat}->{id},
			caption		=> decode('windows-1251','СГМУ имени В.И. Разумовского'),
			document	=>
			{
				file		=> $file_name,
#				filename	=> decode('windows-1251', 'Рекомендации.pdf'),
				filename	=> $file_name,
			},
		});
		#	Вывод на экран
		printf STDERR
			"Send file '%s' (%s) into chat id='%s' successed\n",
			$result->{result}->{document}->{file_name},
			sprintf('%.1f kB', $result->{result}->{document}->{file_size}/1024),
			$message->{chat}->{id};
	};
	#	Проверка ошибок
	if ($@)
	{
		#	информация об ошибке
		send_error($@);
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
sub users_authorized
{
	#	Список пользователей
	my	%user = ();
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	открыть базу данных
	my	$dbh = DBI->connect("dbi:SQLite:dbname=bot.db","","")
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
		#	цикл по ключам хэша
		foreach (keys %{ $row })
		{
			#	декодировать строку из "UTF-8"
			$row->{$_} = decode('UTF-8', $row->{$_});
		}
		#	Добавить пользователя в хэш
		$user{ $row->{telegram_id} } = $row;
	}
	#	Закрыть базу данных
	$dbh->disconnect or Carp::carp $DBI::errstr;
	#
	#	Вывод на экран
	print STDERR "Loading authorized users from 'bot.db' is completed\n";
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return \%user;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Администрирование
	---
	admin($message)
	
		$message	- ссылка на сообщение (хэш)
=cut
sub admin
{
	#	сообщение (ссылка на хэш)
	my	$message = shift @_;
	#	проверка прав администратора
	return undef if
		($message->{chat}->{id} ne '5483130027') || !defined($message->{text});
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	результат
	my	$result = {-admin => $message->{text}};
	#
	#	кодирование текста сообщения
	my	$text = encode('windows-1251', $message->{text});
	#
	#	удалить первые 2 символа
		$text =~ s/^..//;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Ответ Администратору
	if ($text eq 'Получить журнал запросов')
	{
		#	файл журнала
		send_file($message, 'log.db');
		#
		#	пользователи
		send_file($message, 'bot.db');
	}
	elsif ($text eq 'Обновить базу данных')
	{
		#	копирование базы данных
		my	$err = system('perl',
			'pl/make_html.pl', $ENV{'DB_FILE'}, $ENV{'HTML_FOLDER'});
		#
		#	информация
		send_error(decode('windows-1251',
			"*Обновление базы данных*\nerrno=($err)\n"), $!);
		#
		#	послать файл базы данных
		send_file($message, $ENV{'DB_FILE'});
	}
	elsif ($text eq 'Последние 10 запросов')
	{
		#	Последние 10 записей в журнале запросов
		my	$sth = $log_dbh->prepare(qq
			@
				SELECT * FROM logger ORDER BY id DESC LIMIT 10
			@);
			$sth->execute() or Carp::carp $DBI::errstr;
		#
		#	информация о запросах
		my	$log;
		#
		#	цикл по выбранным записям
		while (my $row = $sth->fetchrow_hashref)
		{
			#	Добавить в конец списка
			$log .= sprintf "*%s* (%s)\n",
				$user->{ $row->{telegram_id} }->{user_name},
				$row->{time_stamp};
		}
		#
		#	отправить журнал запросов Боту
		send_error($log, decode('windows-1251',"_Журнал запросов_"));
	}
	elsif ($text eq 'Очистить журнал запросов')
	{
		#	очистить журнал запросов (кроме 10 последних записей)
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
		#	неизвестная команда
		send_error(
			decode('windows-1251', "*Неизвестная команда*"),
			$message->{text});
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	return $result;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__DATA__
