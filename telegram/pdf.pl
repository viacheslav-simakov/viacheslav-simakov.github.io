#
#	Ограничение небезопасных конструкций
#	https://perldoc.perl.org/strict
use strict;
#
#	Управление необязательными предупреждениями
#	https://perldoc.perl.org/warnings
use warnings;
#
#	Декодирование символов
#	https://perldoc.perl.org/Encode
use Encode qw(decode encode);
#
#	Создание, изменение и проверка PDF-файлов
#	https://metacpan.org/pod/PDF::API2
use PDF::API2;
#
#	Служебный класс для построения макетов таблиц
#	https://metacpan.org/pod/PDF::Table
use PDF::Table;
#
#	Создаем PDF
#
my $pdf = PDF::API2->new();
#
#	Устанавливаем шрифт с кириллицей
#
my	$font = $pdf->ttfont('Arial.ttf');
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
			[{colspan => 4}], # Для первой строки, первой ячейки
		],
);
#
#	Сохраняем PDF
#
$pdf->saveas('russian_table2.pdf');

print STDERR "Create file: 'russian_table2.pdf'\n";

exit;