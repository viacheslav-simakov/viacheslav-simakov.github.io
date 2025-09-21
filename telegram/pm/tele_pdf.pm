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
	my	$font = $pdf->ttfont('arial.ttf');
	#
	#	������ �����
	my	$font_bold = $pdf->ttfont('arialbd.ttf');	
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
			}
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
	#	��������� ����
	$self->{-pdf}->saveas($self->{-from}->{id}.'.pdf');
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
		my	$header = Encode::decode('windows-1251', sprintf "������������ '%s' (%s)",
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
		my	$text_width = $text->advancewidth($header);
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
			$text_width = $text->advancewidth($footer);
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
	������� �������
	---
	$obj->table($page_number, $data, %settings);
	
=cut
sub table
{
	#	������ �� ������
	my	$self = shift @_;
	#	����� �������� � ���������
	my	$page_number = shift @_;
	#	������ �������
	my	$data = shift @_;
	#	����� �������: https://metacpan.org/pod/PDF::Table#Table-settings
	my	%settings = (
			header_props => # ��������� �������
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
	#	������ ������� (�� ����� ��������)
		$settings{h} = $settings{y} - 36;
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
	#	pdf-��������
	my	$pdf = $self->{-pdf};
	#
	#	������� �������� � ������� 'page_number'
	my	$page = $pdf->open_page($page_number);
	#
	#	������� ������-�������
	my	$table = PDF::Table->new();
	#
	#	������������� �������: https://metacpan.org/pod/PDF::Table#table()
	my	@res = $table->table(
			$pdf,									# ������ �� ������
			$page,									# ��������
			$copy_data,								# ������ �������
			%settings,								# ����� �������
		);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ ����������� ���������� �������
	return @res;
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