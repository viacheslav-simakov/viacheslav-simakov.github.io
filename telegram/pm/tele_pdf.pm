#
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
#	�������� PDF-�������
#
package Tele_PDF {
#
#	��������, ��������� � �������� PDF-������
#	https://metacpan.org/pod/PDF::API2
use PDF::API2;
#
#	��������� ����� ��� ���������� ������� ������
#	https://metacpan.org/pod/PDF::Table
use PDF::Table;
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�����������
	---
	$obj = Tele_PDF->new( $message );

		$message	- ������ �� ��������� (���)	
=cut
sub new {
	#	�������� ������
	my	$class = shift @_;
	#	��������� ������������, ������� ������ ������
	my	$from = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� PDF
	my	$pdf = PDF::API2->new();
	#
	#	������ �������� �� ���������
		$pdf->default_page_size('A4');
	#
	#	������� �������� (pt)
	my	($page_width, $page_height) = ($pdf->default_page_size)[2,3];
	#
	#	������������� ����� � ����������
	my	$font = $pdf->ttfont('times.ttf');
	#
	#	������ �����
	my	$font_bold = $pdf->ttfont('timesbd.ttf');
	#
	#	������ �� ������
	my	$self =
		{
			-from			=> $from,			# ��������� ������������
			-pdf			=> $pdf,			# pdf-��������
			-font			=> $font,			# �����
			-font_bold		=> $font_bold,		# ������ �����
			-page_width		=> $page_width,		# ������ ��������
			-page_height	=> $page_height,	# ������ ��������
			-page_margin	=>					# ������� �� ���� ��������
			{
				-left		=> 72,
				-right		=> 36,
				-top		=> 36,
				-bottom		=> 36,
			},
			-current_y		=> undef,			# ������ �� �������� ����
		};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������ � ���� __PACKAGE__
	return bless $self, $class;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	��������� ����
	---
	$obj->save();

=cut
sub save
{
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������� �� ��������
		$self->page_header_footer();
	#
	#	��� PDF-�����
	my	$pdf_file = sprintf '%s.pdf', $self->{-from}->{id};
	#
	#	��������� ����
#	$self->{-pdf}->saveas($self->{-from}->{id}.'.pdf');
	$self->{-pdf}->saveas($pdf_file);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��� �����
	return $pdf_file;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������� ��� ���������� ������������
	---
	$obj->page_header_footer();
	
=cut
sub page_header_footer {
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� �����: https://perldoc.perl.org/functions/localtime
	my	($sec, $min, $hour, $mday, $mon, $year) = localtime;
	#
	#	TimeStamp
	my	$time_stamp = sprintf "%02d-%02d-%04d %02d:%02d:%02d",
			$mday, $mon+1, $year+1900, $hour, $min, $sec;
	#
	#	pdf-��������
	my	$pdf = $self->{-pdf};
	#
	#	������� �� ���� ��������
	my	$margin = $self->{-page_margin};
	#
	#	���������� �������
	my	$total_pages = $pdf->page_count();
	#
	#	���� �� ������� �������
	for (my $i = 1; $i <= $total_pages; $i++)
	{
		#	������� ��������
		my	$page = $pdf->open_page($i);
		#
		#	����� ������-�����
		my	$text = $page->text();
		#
		#	�����
			$text->font($self->{-font}, 10);
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	������� ���������� (header)
		my	$header = Encode::decode('windows-1251', sprintf '������������ "%s" (%s)',
				$self->{-from}->{username} || 'unknow', $self->{-from}->{id});
		#	x-�������
		my	$x = $margin->{-left};
		#	y-�������
		my	$y = $self->{-page_height} - 0.5*$margin->{-top};
		#
		#	������� ������
			$text->translate($x, $y);
			$text->text($header);
		#
		#	���� + �����
			$header = $time_stamp;
		#
		#	��������� ������ ������
		my	$text_width = $text->text_width($header);
		#
		#	��������� ������� x ��� ������������ �� ������� ����
			$x = $self->{-page_width} - $text_width - $margin->{-right};
		#
		#	������� ������
			$text->translate($x, $y);
			$text->text($header);
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#	������ ���������� (footer)
		my	$footer = Encode::decode('windows-1251', "�������� $i �� $total_pages");
		#
		#	��������� ������ ������
			$text_width = $text->text_width($footer);
		#
		#	��������� ������� 'x' ��� ������������ �� ������� ����
			$x = $self->{-page_width} - $text_width - $margin->{-right};
		#
		#	������� ������
			$text->translate($x, 0.5*$margin->{-bottom});
			$text->text($footer);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ������
	return $self;
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�������� ������ ��������
	---
	$obj->add_page();
	
=cut
sub add_page
{
	#	������ �� ������
	my	$self = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	�������� ������ ��������
	$self->{-pdf}->page();
	#
	#	������ �� �������� ���� ��������
	$self->{-current_y} = $self->{-page_height} - 1*$self->{-page_margin}->{-top};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ������
	return $self;
}	
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	�������� �����
	---
	$obj->add_text($string, %settings);
	
		$string		- ������ ������
		%settings	- ��������� ������
=cut
sub add_text
{
	#	������ �� ������
	my	$self = shift @_;
	#	������ ������
	my	$string = shift @_;
	#	������� �������� (������, ������)
	my	$page_width = $self->{-page_width};
	my	$page_height = $self->{-page_height};
	#	������� �� ���� ��������
	my	$margin = $self->{-page_margin};
	#	��������� ������
	my	%settings = (
			font 		=> $self->{-font},
			font_size	=> 12,
			x         	=> $margin->{-left},
			y			=> $self->{-current_y},
	, @_);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ ������ (�� ������� ���� ��������)
	my	$width = $page_width - $settings{x} - $margin->{-right};
	#
	#	������ ������ (�� ������� ���� ��������)
	my	$height = $settings{y} - $margin->{-bottom};
	#
	#	������� �������� � ������� 'page_number'
	#	https://metacpan.org/pod/PDF::API2#open_page
	my	$page = $self->{-pdf}->open_page(0);
	#
	#	�������� ������ ���������� ����������� ��������
	my	$text = $page->text();
	#
	#	������������� ����� � ������
		$text->font($settings{font}, $settings{font_size});
	#
	#	��������� ������
		$text->translate($settings{x}, $settings{y});
	#
	#	�������� ��������
	#	https://metacpan.org/pod/PDF::API2::Content#paragraph
	my	($overflow, $last_height) = $text->paragraph($string, $width, $height);
	#
	#	������ �� �������� ���� ��������
	$self->{-current_y} -= $height - $last_height + 0*36;
	
	print STDERR "$overflow, $last_height\n";
	
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod
	������� �������
	---
	$obj->add_table($data, %settings);
	
		$data		- ������ �� ������� ������ [[row-1],[row-2], ...]
		%settings	- ��������� �������
=cut
sub add_table
{
	#	������ �� ������
	my	$self = shift @_;
	#	������ �������
	my	$data = shift @_;
	#	������� �������� (������, ������)
	my	$page_width = $self->{-page_width};
	my	$page_height = $self->{-page_height};
	#	������� �� ���� ��������
	my	$margin = $self->{-page_margin};
	#	����� �������: https://metacpan.org/pod/PDF::Table#Table-settings
	my	%settings = (
			header_props => # ��������� �������
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
	#	������ ������� (�� ����� ��������)
		$settings{h} = $settings{y} - $margin->{-top};# - $margin->{-bottom};
	#
	#	����� ������ �������
	my	$copy_data;
	#
	#	������������� ������ (�� UTF-8)
	foreach my $i (0 .. $#{ $data })
	{
		foreach my $j (0 .. $#{ $data->[$i] })
		{
			$copy_data->[$i]->[$j] = Encode::decode('UTF-8', $data->[$i]->[$j]);
		}
	}
	#
	#	PDF-��������
	my	$pdf = $self->{-pdf};
	#
	#	������� �������� � ������� 'page_number'
	#	https://metacpan.org/pod/PDF::API2#open_page
	my	$page = $pdf->open_page(0);
	#
	#	������� ������-�������
	my	$table = PDF::Table->new();
	#
	#	������������� �������
	#	https://metacpan.org/pod/PDF::Table#table()
	#
	my	($final_page, $number_of_pages, $final_y) = $table->table(
			$pdf,			# ������ �� ������
			$page,			# ��������
			$copy_data,		# ������ �������
			%settings,		# ����� �������
		);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��������� ������ �� �������� ���� ��������
		$self->{-current_y} = $final_y - 36;
	#
	#	��������
	if ($self->{-current_y} <= 1.5*72)
	{
		#	�������� ������ ��������
		$self->add_page();
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ������
	return $self;
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

#
#
#	�������� ������ ��������
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
# ������ �������
my @data = (
    ["Sam-����", "25", "������", "�������"],
    ["�����", "30", "�����-���������", "����"],
    ["�������", "28", "�����������", "�����������"],
    ["�����", "35", "������������", "�������"],
    ["Sam-����", "25", "������", "�������"],
    ["�����", "30", "�����-���������", "����"],
    ["�������", "28", "�����������", "�����������"],
    ["�����", "35", "������������", "�������"],
    ["�������", "28", "�����������", "�����������"],
    ["�����", "35", "������������", "�������"],
);
#
#	������������� ������
#
foreach my $i (0 .. $#data)
{
	foreach my $j (0 .. $#{ $data[$i] })
	{
		$data[$i]->[$j] = decode('UTF-8', $data[$i]->[$j]);
	}
}
#
#	������� �������
#
my	$table = PDF::Table->new();
#
#	����� �������
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
			[{colspan => 4}],#	��� ������ ������, ������ ������
			[],
			[{colspan => 4}],#	��� ������� ������, ������ ������
		],
);
#
#	��������� PDF
#
$pdf->saveas('russian_table2.pdf');

print STDERR "Create file: 'russian_table2.pdf'\n";

exit;