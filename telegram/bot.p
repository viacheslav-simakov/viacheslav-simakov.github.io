#
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
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
#	Создание и изменение PDF-файлов
#	https://metacpan.org/pod/PDF::Builder
#use PDF::Builder;
#
#	Телеграм-Бот
#	https://metacpan.org/pod/WWW::Telegram::BotAPI
use WWW::Telegram::BotAPI;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	папки библиотек (модулей)
#	'.' = текущая папка!
use lib ('pm');


users();
exit;
#
#	База данных
#use tele_db();
#
#	pdf-документы
use Tele_PDF();
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
#	Главный цикл обработки событий бота
printf STDERR
	"Telegram Bot \@tele_rheumatology_bot is started at %3\$02d:%2\$02d:%1\$02d\n",
	(localtime)[0 ... 2];
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
		Carp::carp "\nОшибка при получении обновлений: $@\n\n";
		#
		#	следующая итерация цикла
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
		#	Журнал
		logger($update);
        #
		#	Сообщение
        my	$message = $update->{message} or next;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	Проверка ID чата
		unless ($message->{chat}->{id})
		{
			#	вывод на экран
			Carp::carp "Ошибка! Неверный 'chat id'";
			#	следующее обновление
			next;
		}
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#
        #	Обработка команд
		#
		if ($message->{web_app_data}->{data})
		{
			#	данные Web App
			user_request($message);
		}
        elsif (defined($message->{text}) and $message->{text} =~ m{^/start}i)
		{
			#	клавиатура
			web_app_keyboard($message);
        }
        else
		{
			#	неизвестный запрос
			unknow($message);
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Вывод на экран
	---
	logger($update)
		
		$update	- ссылка на обновление (хэш)
=cut
sub logger
{
	#	ссылка на обновление
	my	$update = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Журнал
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
	Неизвестное сообщение
	---
	unknow($message)

		$message	- ссылка на сообщение (хэш)
=cut
sub unknow
{
	#	ссылка на сообщение
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение боту (вывод клавиатуры)
		$api->api_request('sendMessage',
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
		#	информации об ошибке
		Carp::carp "\nОшибка при отправке 'default' сообщения: $@\n";
	}
	else
	{
		printf STDERR "Unknown message! 'Default' response to Bot has been send\n";
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Вывод клавиатуры на экран
	---
	web_app_keyboard($message)
		
		$message	- ссылка на сообщение (хэш)
=cut
sub web_app_keyboard
{
	#	ссылка на сообщение
	my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Клавиатура
	my	$keyboard = [[
		{
			text	=> "\x{1F48A}" . decode('windows-1251',
						'Электронный ассистент врача-ревматолога'),
			web_app	=> {
				url	=> 'https://viacheslav-simakov.github.io/med/med.html'
			},
		}
	],];
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Послать сообщение боту (вывод клавиатуры)
		$api->api_request('sendMessage',
		{
			chat_id => $message->{chat}->{id},
			parse_mode => 'Markdown',
			text => decode('windows-1251',
				"*Электронный ассистент врача-ревматолога*\n(СГМУ имени В.И. Разумовского)"),
			reply_markup =>
			{
				keyboard => $keyboard,
				resize_keyboard => \1,
				one_time_keyboard => \1,
			},
		});
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка ошибок
	if ($@)
	{
		#	информации об ошибке
		Carp::carp "\nОшибка при отправке 'клавиатуры' Бота: $@\n";
	}
	else
	{
		printf STDERR "'reply mark' keyboard to Bot has been send\n";
	}
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Обработка данных HTML-формы полученных из Web App
	---
	user_request($message)
	
		$message	- ссылка на сообщение (хэш)

=cut
sub user_request
{
	#	ссылка на сообщение
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	имя PDF-файла
	my	$pdf_file_name = sprintf '%s.pdf', $message->{chat}->{id};
	#
	#	Данные HTML-формы
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
		
		$message->{from}->{-organization} =
			decode('windows-1251', 'Областная клиническая больница (ОКБ)');
	#
	#	PDF-документ
	my	$pdf = Tele_PDF->new($message->{from}, decode_json($web_app_data));
	#
	#	Создать PDF-файл
		$pdf->save($pdf_file_name);
	#
	#	Отправить пользователю PDF-файл
		send_pdf($message, $pdf_file_name);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Отправка PDF-файла
	---
	send_pdf($message, $pdf_file_name)
	
		$message		- ссылка на сообщение (хэш)
		$pdf_file_name	- имя PDF-файла
=cut
sub send_pdf
{
	#	ID чата пользователя
    my	$message = shift @_;
	#	имя PDF-файла
	my	$pdf_file_name = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Проверка существование файла
	unless (-e $pdf_file_name)
	{
		#	предупреждение!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"PDF-file '%s' file is not exist!\n",
			(caller(0))[0,1,3], $pdf_file_name;
		#
		#	возврат из функции
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Безопасная конструкция
	eval {
		#	Отправляем PDF файл
		my $result = $api->api_request('sendDocument',
		{
			chat_id		=> $message->{chat}->{id},
			caption		=> decode('windows-1251','СГМУ имени В.И. Разумовского'),
			document	=>
			{
				file		=> $pdf_file_name,
#				filename	=> decode('windows-1251', 'Рекомендации.pdf'),
				filename	=> $pdf_file_name,
			},
		});
		#	Вывод на экран
		printf STDERR
			"Send file '%s' (%s) into chat id='%s' successed\n",
			$result->{result}->{document}->{file_name},
			sprintf('%.1f kB', $result->{result}->{document}->{file_size}/1024),
			$message->{chat}->{id};
#		print STDERR Dumper($result);
	};
	#	Проверка ошибок
	Carp::carp "\nОшибка при отправке файла: $@\n" if ($@);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Список пользователей
	---
	\%user = users()
	
=cut
sub users
{
	#	открыть базу данных
	my	$dbh = DBI->connect("dbi:SQLite:dbname=bot.db","","")
			or die $DBI::errstr;
	#
	#	SQL-запрос
	my	$sth = $dbh->prepare('SELECT * FROM "user"')
			or Carp::confess "Ошибка запроса к таблице пользователей";
		$sth->execute;
	#
	#	Список пользователей
	my	%user;
	#
	#	цикл по выбранным записям
	while (my $row = $sth->fetchrow_hashref)
	{
		#	цикл по ключам хэша
		foreach (keys %{ $row })
		{
			#	декодировать строку из "UTF-8"
			$row->{$_} = decode('UTF-8', $row->{$_});
		}
		#	Telegram-ID
		my	$telegram_id = delete $row->{telegram_id};
		#
		#	Добавить пользователя в хэш
		$user{ $telegram_id } = $row;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на хэш
	return \%user;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
__DATA__
