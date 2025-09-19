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
	#	Данные HTML-формы
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
    #	Декодирование JSON данных полученных из Web App
	my	$data = decode_json($web_app_data);
	#
	#	Параметры запроса
#	my	$req = tele_db::request($data);
	#
	#	ссылка на объект
	my	$req = Tele_DB->new($data);
		
#	print STDERR Dumper($req->report);
#	print STDERR Dumper($req->request);
	
	#	Открыть файл
	open(my $fh, ">", '000.txt') or die "Cannot open file: $!";
	#
	#	Печать в файл
	print $fh Dumper($req->request);
#	print $fh decode('UTF-8', Dumper($req->report));
	print $fh Dumper($req->report);
	#
	#	Закрыть файл
	close($fh);
	#
	#	Вывод на экран
	print STDERR "\n\n\tCreate TXT-file\n\n\n";
	
	
	my	$info_query = $req->request;
	#
	#	pdf-документ
	my	$pdf = Tele_PDF->new($message->{from}->{id});
	#
	#	добавить пустую страницу
	$pdf->{-pdf}->page();

	my	$y = 842 - 36 - 4*36;
	my	$h = $y - 36;

	my	@res = $pdf->table(1, $info_query->{rheumatology},
		y	=> $y,
		h	=> $h,
		ink => 0,
	);
	
	printf "\n(%s)\nh=%s\n", join(', ', @res), $h;
	
	@res = $pdf->table(1, $info_query->{rheumatology},
#		y	=> 842-36-$res[0],
		y	=> $y,
#		h	=> $res[0],
		h	=> $h,
		ink	=> 1,
	);
	
	printf "\n(%s)\nh=%s\n", join(', ', @res), $h;
	#
	#	Создать PDF-файл
	$pdf->save();
	
	print STDERR "\n\n\tCreate *PDF*-file\n\n\n";
	
	return;
	
    $api->sendMessage(
	{
        chat_id => $chat_id,
        text => "Received data from Web App\n" . Dumper($data),
    });
	
#	send_pdf($message, 'C:/Git-Hub/viacheslav-simakov.github.io/telegram/russian_table2.pdf');
#	send_pdf($message, 'russian_table2.pdf');
	send_pdf($message);
}
=pod
	Отправка PDF-файла
	---
	send_pdf($message, $pdf_file)
	
		$message	- ссылка на сообщение (хэш)
		$pdf_file	- путь pdf-файла (строка)

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
	#
	#	Вывод на экран
	printf STDERR "\n\tsend pdf file to chat_id='%s'\n\n", $chat_id;
#return;
	#
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
		print STDERR Dumper($result);
	};
	#	Проверка ошибок
	die "\nОшибка при отправке файла: $@\n" if ($@);
}
__DATA__
