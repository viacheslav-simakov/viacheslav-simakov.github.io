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
	my	$font = $pdf->ttfont('arial.ttf');
	#
	#	Жирный шрифт
	my	$font_bold = $pdf->ttfont('arialbd.ttf');	
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
			}
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
	#	Сохранить файл
	$self->{-pdf}->saveas($self->{-from}->{id}.'.pdf');
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
		my	$header = Encode::decode('windows-1251', sprintf "Пользователь '%s' (%s)",
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
		my	$text_width = $text->advancewidth($header);
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
			$text_width = $text->advancewidth($footer);
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
	Создать таблицу
	---
	$obj->table($page_number, $data, %settings);
	
=cut
sub table
{
	#	ссылка на объект
	my	$self = shift @_;
	#	номер страницы в документе
	my	$page_number = shift @_;
	#	данные таблицы
	my	$data = shift @_;
	#	опции таблицы: https://metacpan.org/pod/PDF::Table#Table-settings
	my	%settings = (
			header_props => # Заголовок таблицы
			{
				font 			=> $self->{-font_bold},
				font_size		=> 14,
				font_color		=> 'black',
				bg_color		=> 'lightgray',
				valign			=> 'middle',
				padding_top		=> 10,
				padding_bottom	=> 10,
				repeat		=> 1,    # 1/0 eq On/Off  if the header row should be repeated to every new page
			},
			font 		=> $self->{-font},
			font_size	=> 12,
			x         	=> 36,
			w         	=> $self->{-page_width} - 2*36,
			y			=> undef,
			padding   	=> 5,
			size		=> '8cm *',
			border_w	=> 1,
			next_y		=> $self->{-page_height} - 1*36,
			next_h		=> $self->{-page_height} - 2*36,
		, @_);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	Высота таблицы (до конца страницы)
		$settings{h} = $settings{y} - 36;
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
	#	pdf-документ
	my	$pdf = $self->{-pdf};
	#
	#	Открыть страницу с номером 'page_number'
	my	$page = $pdf->open_page($page_number);
	#
	#	Создать объект-таблицу
	my	$table = PDF::Table->new();
	#
	#	Сгенерировать таблицу: https://metacpan.org/pod/PDF::Table#table()
	my	@res = $table->table(
			$pdf,									# ссылка на объект
			$page,									# страница
			$copy_data,								# данные таблицы
			%settings,								# опции таблицы
		);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	список фактических параметров таблицы
	return @res;
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