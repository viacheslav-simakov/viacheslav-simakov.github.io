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
#	Создание PDF-отчетов
#
package Tele_PDF {
#
#	Создание, изменение и проверка PDF-файлов
#	https://metacpan.org/pod/PDF::API2
use PDF::API2;
#
#	Служебный класс для построения макетов таблиц
#	https://metacpan.org/pod/PDF::Table
use PDF::Table;
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Конструктор
	---
	$obj = Tele_PDF->new( $message );

		$message	- ссылка на сообщение (хэш)	
=cut
sub new {
	#	название класса
	my	$class = shift @_;
	#	сообщение пользователя, который сделал запрос
	my	$from = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Создаем PDF
	my	$pdf = PDF::API2->new();
	#
	#	Размер страницы по умолчанию
		$pdf->default_page_size('A4');
	#
	#	Размеры страницы (pt)
	my	($page_width, $page_height) = ($pdf->default_page_size)[2,3];
	#
	#	Устанавливаем шрифт с кириллицей
	my	$font = $pdf->ttfont('times.ttf');
	#
	#	Жирный шрифт
	my	$font_bold = $pdf->ttfont('timesbd.ttf');
	#
	#	ссылка на объект
	my	$self =
		{
			-from			=> $from,			# сообщение пользователя
			-pdf			=> $pdf,			# pdf-документ
			-font			=> $font,			# шрифт
			-font_bold		=> $font_bold,		# жирный шрифт
			-page_width		=> $page_width,		# ширина страницы
			-page_height	=> $page_height,	# высота страницы
			-page_margin	=>					# отступы от края страницы
			{
				-left		=> 72,
				-right		=> 36,
				-top		=> 36,
				-bottom		=> 36,
			},
			-current_y		=> undef,			# отступ от верхнего края
		};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	привести ссылку к типу __PACKAGE__
	return bless $self, $class;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Сохранить файл
	---
	$obj->save();

=cut
sub save
{
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Колонтитулы на странице
		$self->page_header_footer();
	#
	#	имя PDF-файла
	my	$pdf_file = sprintf '%s.pdf', $self->{-from}->{id};
	#
	#	Сохранить файл
#	$self->{-pdf}->saveas($self->{-from}->{id}.'.pdf');
	$self->{-pdf}->saveas($pdf_file);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	имя файла
	return $pdf_file;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Функция для добавления колонтитулов
	---
	$obj->page_header_footer();
	
=cut
sub page_header_footer {
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	местное время: https://perldoc.perl.org/functions/localtime
	my	($sec, $min, $hour, $mday, $mon, $year) = localtime;
	#
	#	TimeStamp
	my	$time_stamp = sprintf "%02d-%02d-%04d %02d:%02d:%02d",
			$mday, $mon+1, $year+1900, $hour, $min, $sec;
	#
	#	pdf-документ
	my	$pdf = $self->{-pdf};
	#
	#	отступы от края страницы
	my	$margin = $self->{-page_margin};
	#
	#	количество страниц
	my	$total_pages = $pdf->page_count();
	#
	#	цикл по номерам страниц
	for (my $i = 1; $i <= $total_pages; $i++)
	{
		#	Открыть страницу
		my	$page = $pdf->open_page($i);
		#
		#	Новый объект-текст
		my	$text = $page->text();
		#
		#	Шрифт
			$text->font($self->{-font}, 10);
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	Верхний колонтитул (header)
		my	$header = Encode::decode('windows-1251', sprintf 'Пользователь "%s" (%s)',
				$self->{-from}->{username} || 'unknow', $self->{-from}->{id});
		#	x-позиция
		my	$x = $margin->{-left};
		#	y-позиция
		my	$y = $self->{-page_height} - 0.5*$margin->{-top};
		#
		#	позиция текста
			$text->translate($x, $y);
			$text->text($header);
		#
		#	Дата + Время
			$header = $time_stamp;
		#
		#	Вычисляем ширину текста
		my	$text_width = $text->text_width($header);
		#
		#	Вычисляем позицию x для выравнивания по правому краю
			$x = $self->{-page_width} - $text_width - $margin->{-right};
		#
		#	позиция текста
			$text->translate($x, $y);
			$text->text($header);
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	Нижний колонтитул (footer)
		my	$footer = Encode::decode('windows-1251', "Страница $i из $total_pages");
		#
		#	Вычисляем ширину текста
			$text_width = $text->text_width($footer);
		#
		#	Вычисляем позицию 'x' для выравнивания по правому краю
			$x = $self->{-page_width} - $text_width - $margin->{-right};
		#
		#	позиция текста
			$text->translate($x, 0.5*$margin->{-bottom});
			$text->text($footer);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на объект
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Добавить пустую страницу
	---
	$obj->add_page();
	
=cut
sub add_page
{
	#	ссылка на объект
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Добавить пустую страницу
	$self->{-pdf}->page();
	#
	#	Отступ от верхнего края страницы
	$self->{-current_y} = $self->{-page_height} - 1*$self->{-page_margin}->{-top};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на объект
	return $self;
}	
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Добавить текст
	---
	$obj->add_text($string, %settings);
	
		$string		- строка текста
		%settings	- параметры текста
=cut
sub add_text
{
	#	ссылка на объект
	my	$self = shift @_;
	#	строка текста
	my	$string = shift @_;
	#	размеры страницы (ширина, высота)
	my	$page_width = $self->{-page_width};
	my	$page_height = $self->{-page_height};
	#	отступы от краёв страницы
	my	$margin = $self->{-page_margin};
	#	параметры текста
	my	%settings = (
			font 		=> $self->{-font},
			font_size	=> 12,
			x         	=> $margin->{-left},
			y			=> $self->{-current_y},
	, @_);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Ширина текста (до правого края страницы)
	my	$width = $page_width - $settings{x} - $margin->{-right};
	#
	#	Высота текста (до нижнего края страницы)
	my	$height = $settings{y} - $margin->{-bottom};
	#
	#	Открыть страницу с номером 'page_number'
	#	https://metacpan.org/pod/PDF::API2#open_page
	my	$page = $self->{-pdf}->open_page(0);
	#
	#	Получаем объект текстового содержимого страницы
	my	$text = $page->text();
	#
	#	Устанавливаем шрифт и размер
		$text->font($settings{font}, $settings{font_size});
	#
	#	Положение текста
		$text->translate($settings{x}, $settings{y});
	#
	#	Добавить параграф
	#	https://metacpan.org/pod/PDF::API2::Content#paragraph
	my	($overflow, $last_height) = $text->paragraph($string, $width, $height);
	#
	#	Отступ от верхнего края страницы
	$self->{-current_y} -= $height - $last_height + 0*36;
	
	print STDERR "$overflow, $last_height\n";
	
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	Создать таблицу
	---
	$obj->add_table($data, %settings);
	
		$data		- ссылка на матрицу данных [[row-1],[row-2], ...]
		%settings	- параметры таблицы
=cut
sub add_table
{
	#	ссылка на объект
	my	$self = shift @_;
	#	данные таблицы
	my	$data = shift @_;
	#	размеры страницы (ширина, высота)
	my	$page_width = $self->{-page_width};
	my	$page_height = $self->{-page_height};
	#	отступы от краёв страницы
	my	$margin = $self->{-page_margin};
	#	опции таблицы: https://metacpan.org/pod/PDF::Table#Table-settings
	my	%settings = (
			header_props => # Заголовок таблицы
			{
				font 			=> $self->{-font_bold},
				font_size		=> 12,
				font_color		=> 'black',
				bg_color		=> 'lightgray',
				valign			=> 'middle',
				padding_top		=> 7,
				padding_bottom	=> 7,
				repeat			=> 1,    # 1/0 eq On/Off  if the header row should be repeated to every new page
			},
			font 		=> $self->{-font},
			font_size	=> 12,
			x         	=> $margin->{-left},
			w         	=> $page_width - $margin->{-left} - $margin->{-right},
			y			=> $self->{-current_y},
			padding   	=> 5,
			size		=> '8cm 1*',
			border_w	=> 0.5,
			next_y		=> $page_height - $margin->{-top},
			next_h		=> $page_height - $margin->{-top} - $margin->{-bottom},
		, @_);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Высота таблицы (до конца страницы)
		$settings{h} = $settings{y} - $margin->{-top};# - $margin->{-bottom};
	#
	#	Копия данных таблицы
	my	$copy_data;
	#
	#	Декодирование данных (из UTF-8)
	foreach my $i (0 .. $#{ $data })
	{
		foreach my $j (0 .. $#{ $data->[$i] })
		{
			$copy_data->[$i]->[$j] = Encode::decode('UTF-8', $data->[$i]->[$j]);
		}
	}
	#
	#	PDF-документ
	my	$pdf = $self->{-pdf};
	#
	#	Открыть страницу с номером 'page_number'
	#	https://metacpan.org/pod/PDF::API2#open_page
	my	$page = $pdf->open_page(0);
	#
	#	Создать объект-таблицу
	my	$table = PDF::Table->new();
	#
	#	Сгенерировать таблицу
	#	https://metacpan.org/pod/PDF::Table#table()
	#
	my	($final_page, $number_of_pages, $final_y) = $table->table(
			$pdf,			# ссылка на объект
			$page,			# страница
			$copy_data,		# данные таблицы
			%settings,		# опции таблицы
		);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Увеличить отступ от верхнего края страницы
		$self->{-current_y} = $final_y - 36;
	#
	#	Проверка
	if ($self->{-current_y} <= 1.5*72)
	{
		#	добавить пустую страницу
		$self->add_page();
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ссылка на объект
	return $self;
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#
#
#	Добавить пустую страницу
#
my	$page = $pdf->page();
#
#	A4 (210mm x 297mm)
	$page->mediabox(595, 842);  # 595 x 842 points
#
# Add a text object
my	$text = $page->text();
#
# Set font and size
	$text->font($font, 12);

# Write text at specific coordinates
#	$text->translate(50, 800);
	$text->translate(36, 842-36);
	$text->text('Hello, World!');
#
# Данные таблицы
my @data = (
    ["Sam-Иван", "25", "Москва", "Инженер"],
    ["Мария", "30", "Санкт-Петербург", "Врач"],
    ["Алексей", "28", "Новосибирск", "Программист"],
    ["Ольга", "35", "Екатеринбург", "Учитель"],
    ["Sam-Иван", "25", "Москва", "Инженер"],
    ["Мария", "30", "Санкт-Петербург", "Врач"],
    ["Алексей", "28", "Новосибирск", "Программист"],
    ["Ольга", "35", "Екатеринбург", "Учитель"],
    ["Алексей", "28", "Новосибирск", "Программист"],
    ["Ольга", "35", "Екатеринбург", "Учитель"],
);
#
#	Декодирование данных
#
foreach my $i (0 .. $#data)
{
	foreach my $j (0 .. $#{ $data[$i] })
	{
		$data[$i]->[$j] = decode('UTF-8', $data[$i]->[$j]);
	}
}
#
#	Создаем таблицу
#
my	$table = PDF::Table->new();
#
#	Опции таблицы
#	https://metacpan.org/pod/PDF::Table#Table-settings
	$table->table(
        $pdf,
        $page,
		\@data,
		header_props => {
			font 		=> $font,
            font_size	=> 14,
            font_color	=> '#006666',
            bg_color	=> 'yellow',
            repeat		=> 1,    # 1/0 eq On/Off  if the header row should be repeated to every new page
		},
		font 		=> $font,
		font_size	=> 12,
        x         	=> 50,
		y			=> 750,
        w         	=> 500,
        h   		=> 500,
        padding   	=> 5,
		size		=> '* 1cm 2* 4cm',
		border_w	=> 0,
#        background_color_odd  => "gray",
#        background_color_even => "lightblue",
		cell_props =>
		[
			[{colspan => 4}],#	Для первой строки, первой ячейки
			[],
			[{colspan => 4}],#	Для третьей строки, первой ячейки
		],
);
#
#	Сохраняем PDF
#
$pdf->saveas('russian_table2.pdf');

print STDERR "Create file: 'russian_table2.pdf'\n";

exit;