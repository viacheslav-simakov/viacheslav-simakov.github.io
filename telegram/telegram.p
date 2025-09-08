#
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
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
#
#	Токен бота (получите у @BotFather)
#	my	$token = '8105314834:AAE6cZ9KTYsXr4od7SvZckslisl1MRp0OXI';
#
#	имя бота: @tele_rheumatology_bot
#
my	$token = '8278981933:AAGOZMWywJZxlR-Vj5kwh4HeISQhwPpXuwE';
#
#	Создаем объект API
my	$api = WWW::Telegram::BotAPI->new(token => $token);
=pod
#
#	Создание клавиатуры
my	$keyboard =
	[[{
		text => decode('windows-1251', 'Начать'),
		web_app => {
			url => 'https://viacheslav-simakov.github.io/'
		},
	},],];
=cut
#
#	Получаем последние обновления
my	$offset = 0;
#
#	Главный цикл обработки событий бота
print STDERR "Telegram Bot \@tele_rheumatology_bot ... started\n\n";
while (1) {
	sleep(1);
	my @time = localtime;
#	printf STDERR "%3\$02d:%2\$02d:%1\$02d\n", @time[0 ... 2];
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
        next unless $message->{chat}->{id};
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
=pod
            $api->sendMessage(
			{
                chat_id => $message->{chat}->{id},
				parse_mode => 'Markdown',
                text => decode('windows-1251', sprintf(
					"Привет *%s*!\nЯ бот \"Электронный ассистент врача-ревматолога\".\nИспользуйте /start для начала работы.",
					encode('windows-1251', ($message->{from}->{first_name} || 'unknow')))
				),
            });
=cut
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
	printf STDERR "\n\nfrom_id='%s'\ttext='%s'\tweb_app_data='%s'\n%s%s\n",
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
	my	$msg = shift @_;
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
	$api->sendMessage(
	{
		chat_id => $msg->{chat}->{id},
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
	#	Данные HTML-формы
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
#    my	$web_app_data = $message->{web_app_data}->{data};
	#
    #	Декодирование JSON данных полученных из Web App
	my	$data = decode_json($web_app_data);
	
	print STDERR Dumper($data);

#	return;
	
    $api->sendMessage(
	{
        chat_id => $chat_id,
        text => "Received data from Web App\n" . Dumper($data),
    });
}