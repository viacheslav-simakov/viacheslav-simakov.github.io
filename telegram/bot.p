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
#
#	База данных
use tele_db();
#
#	pdf-документы
use tele_pdf();
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
#	Получаем последние обновления
my	$offset = 0;
#
#	Главный цикл обработки событий бота
printf STDERR
	"Telegram Bot \@tele_rheumatology_bot is started at %3\$02d:%2\$02d:%1\$02d\n\n",
	(localtime)[0 ... 2];
while (1) {
	#	задержка 1 секунда
#	sleep(1);
	#
    #	Получаем обновления
	#
    my	$updates = $api->getUpdates(
		{
			offset => $offset,	# Смещение
			timeout => 30,		# Determines the timeout in seconds for long polling
		}
	) or die "Ошибка при получении обновлений: $!";
    #
    #	Обрабатываем каждое обновление
	#
    foreach my $update (@{ $updates->{result} })
	{
		#	Увеличиваем смещение
        $offset = $update->{update_id} + 1 if $update->{update_id} >= $offset;
		#
		#	Журнал
			_logger($update);
        #
		#	Сообщение
        my	$message = $update->{message} or next;
        #
		#	ID чата
		my	$chat_id = $message->{chat}->{id} or next;
		#
		#	Текст сообщения
        my	$msg_text = $message->{text} or undef;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #	Обработка команд
		if ($message->{web_app_data}->{data})
		{
			#	Данные Web App
			web_app_data($message);
			#
			#	Следующая итерация цикла
			next;
		}
        elsif ($msg_text and $msg_text =~ m{^/start}i)
		{
			#	клавиатура
			web_app_keyboard($message);
        }
        else
		{
            $api->sendMessage(
			{
                chat_id => $message->{chat}->{id},
				parse_mode => 'Markdown',
                text => decode('windows-1251', sprintf(
					"Привет *%s*!\nЯ бот \"Электронный ассистент врача-ревматолога\".\nИспользуйте /start для начала работы.",
					encode('windows-1251', ($message->{from}->{first_name} || 'unknow')))
				),
            });
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    }
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Вывод на экран
	---
	_logger($update)
		
		$update	- ссылка на обновление (хэш)
=cut
sub _logger
{
	#	ссылка на обновление
	my	$update = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Журнал
	printf STDERR "update at %3\$02d:%2\$02d:%1\$02d\n", (localtime)[0 ... 2];
	printf STDERR "from_id='%s'\ttext='%s'\tweb_app_data='%s'\n%s%s\n",
		$update->{message}->{from}->{id},
		encode('windows-1251', $update->{message}->{text} || ''),
		encode('windows-1251', $update->{message}->{web_app_data}->{data} || ''),
		Dumper($update),
		('~' x 79);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Кнопка
	---
	_button($text, $page, $emoji)
	
		$text	- надпись на кнопке
		$page	- страница
		$emoji	- эмодзи
=cut
sub _button
{
	#	название кнопки, html-страница
	my	($text, $page, $emoji) = @_;
	#	значок
		$emoji = defined $emoji ? $emoji . ' ' : '';
	#
	#	ссылка на хэш
	return
	{
		text => $emoji . decode('windows-1251', $text),
		web_app => {url => 'https://viacheslav-simakov.github.io/med/' . $page},
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
	#	ID чата
    my	$chat_id = $message->{chat}->{id} || undef;
	#
	#	Проверка ID чата
	unless (defined $chat_id)
	{
		printf STDERR "\n\t%s: Ошибка! Неверный 'chat id'\n", (caller(0))[3];
		#
		#	возврат из функции
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Клавиатура
	my	$keyboard = [
		[
			{
				text	=> "\x{1F48A}" . decode('windows-1251',
							'Электронный ассистент врача-ревматолога'),
				web_app	=> {
					url	=> 'https://viacheslav-simakov.github.io/med/med.html'
				},
			}
#		_button('Электронный ассистент врача-ревматолога', 'med.html', "\x{1F48A}")
		],
	];
	#-----------------------------------------------------------------
	#	Сообщение
	$api->api_request('sendMessage',
	{
		chat_id => $chat_id,
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
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Обработка данных HTML-формы полученных из Web App
	---
	web_app_data($message)
	
		$message	- ссылка на сообщение (хэш)

=cut
sub web_app_data
{
	#	ссылка на сообщение
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ID чата
    my	$chat_id = $message->{chat}->{id};
	#
	#	Проверка ID чата
	unless (defined $chat_id)
	{
		printf STDERR "\n\t%s: Ошибка! Неверный 'chat id'\n", (caller(0))[3];
		#
		#	возврат из функции
		return undef;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Создать PDF-файл
		make_pdf($message);
	#
	#	Отправить пользователю PDF-файл
		send_pdf($message);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Отправка PDF-файла
	---
	send_pdf( $message )
	
		$message	- ссылка на сообщение (хэш)
=cut
sub send_pdf
{
	#	ссылка на сообщение
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ID чата
    my	$chat_id = $message->{chat}->{id};
	#
	#	PDF-файл
	my	$pdf_file = sprintf '%s.pdf', $chat_id;
	#
	#	Проверяем существование файла
	unless (-e $pdf_file)
	{
		#	предупреждение!
		Carp::carp sprintf
			"package '%s', filename '%s', subroutine '%s':\n".
			"PDF-file '%s' file is not exist!\n",
			(caller(0))[0,1,3], $pdf_file;
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
			chat_id		=> $chat_id,
			caption		=> decode('windows-1251','СГМУ имени В.И. Разумовского'),
			document	=>
			{
				file		=> $pdf_file,
#				filename	=> decode('windows-1251', 'Рекомендации.pdf'),
				filename	=> $pdf_file,
			},
		});
		#	Вывод на экран
		printf STDERR
			"PDF файл '%s' успешно отправлен!\nmessage ID: %s\n",
			$pdf_file, $result->{result}->{message_id};
#		print STDERR Dumper($result);
	};
	#	Проверка ошибок
	Carp::carp "\nОшибка при отправке файла: $@\n" if ($@);
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Создать PDF-файла
	---
	make_pdf( $message )
	
		$message	- ссылка на сообщение (хэш)

=cut
sub make_pdf
{
	#	ссылка на сообщение
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Данные HTML-формы
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
    #	Декодирование JSON данных HTML-формы полученных из Web App
	my	$data = decode_json($web_app_data);
	#
	#	ссылка на объект
	my	$req = Tele_DB->new($data);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Запрос пользователя
	my	$data_query = $req->request();
	#
	#	Отчет по запросу пользователя
	my	$data_report = $req->report();
	#
	#	PDF-документ
	my	$pdf = Tele_PDF->new( $message->{from} );
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Добавить пустую страницу
		$pdf->add_page();
	#
	#	увеличить отступ от верхнего края страницы	
		$pdf->{-current_y} -= 12;
	#
	#	Данные запроса пользователя
	#
		$pdf->add_text(decode('windows-1251',
			'Данные запроса пользователя'),
			font => $pdf->{-font_bold}, font_size => 14);
	#
	#	цикл по секциям запроса
	foreach my $name ('rheumatology', 'comorbidity', 'status', 'manual', 'probe', 'preparation')
	{
		#	нет выбранных данных
		next if scalar @{ $data_query->{$name} } < 2;
		#
		#	добавить таблицу
		if ($name eq 'probe')
		{
			$pdf->add_table($data_query->{$name}, size => '8cm 3cm 1*');
		}
		else
		{
			$pdf->add_table($data_query->{$name}, size => '8cm 1*');
		}
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Добавить пустую страницу
		$pdf->add_page();
	#
	#	увеличить отступ от верхнего края страницы	
		$pdf->{-current_y} -= 12;
	#
	#	Список препаратов рекомендуемых к применению
	#
	$pdf->add_text(decode('windows-1251',
			'Список препаратов рекомендуемых к применению'),
			font => $pdf->{-font_bold}, font_size => 14);
	#
	#	цикл по выбранным препаратам
	foreach my $preparation (@{ $data_report->{-preparation} })
	{
		#	добавить таблицу
		$pdf->add_table($preparation,
			size	=> '5cm 1*',
		);
	}

	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Создать PDF-файл
	my	$pdf_file_name = $pdf->save();
	#
	#	вывод на экран
	print STDERR "\n\tCreate *PDF*-file '$pdf_file_name'\n\n";
	#	имя файла
	return $pdf_file_name;
}
__DATA__
