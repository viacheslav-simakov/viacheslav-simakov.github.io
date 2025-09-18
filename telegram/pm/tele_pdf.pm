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
#	��������� SQL-�������� � ���� ������ SQLite
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
	$obj = Tele_PDF->new( $user_id );
	
		$user_id	- ID ������������, ������� ������ ������
=cut
sub new {
	#	�������� ������
	my	$class = shift @_;
	#	ID ������������, ������� ������ ������
	my	$user_id = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� PDF
	my	$pdf = PDF::API2->new();
	#
	#	������ �������� �� ���������
		$pdf->default_page_size('A4');
		print STDERR join(',', $pdf->default_page_size),"\n\n";

	my	@rectangle = 

	#
	#	������������� ����� � ����������
	my	$font = $pdf->ttfont('Arial.ttf');
	#
	#	������ �� ������
	my	$self =
		{
			-user_id		=> $user_id,	# ID �������������
			-pdf			=> $pdf,		# pdf-��������
			-font			=> $font,		# �����
			-page_width		=> ($pdf->default_page_size)[2],
			-page_height	=> ($pdf->default_page_size)[3],
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
	#	��������� ����
	$self->{-pdf}->saveas($self->{-user_id}.'.pdf');
}
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
=pod

=cut
sub table
{
	#	������ �� ������
	my	$self = shift @_;
	#	������ �������
	my	$data = shift @_;
	#	����� �������
	my	%settings = (
			header_props => # ��������� �������
			{
				font 		=> $self->{-font},
				font_size	=> 14,
				font_color	=> '#006666',
				bg_color	=> 'yellow',
				repeat		=> 1,    # 1/0 eq On/Off  if the header row should be repeated to every new page
			},
			font 		=> $self->{-font},
			font_size	=> 12,
			x         	=> 36,
			w         	=> $self->{-page_width} - 72,
			padding   	=> 5,
			size		=> '8cm *',
			border_w	=> 1,
		, @_);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����� ������ �������
	my	$copy_data;
	#
	#	������������� ������
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
	#	�������� ������ ��������
	my	$page = $pdf->page();
	#
	#	������� �������
	my	$table = PDF::Table->new();
	#
	#	����� �������: https://metacpan.org/pod/PDF::Table#Table-settings
	#
	my	@res = $table->table($pdf, $page, $copy_data,
			y	=> $self->{-page_height} - 36,
			h   => 500,
			%settings,
	);
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