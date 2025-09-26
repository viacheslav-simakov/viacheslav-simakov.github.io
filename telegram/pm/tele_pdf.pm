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
#	���� ������
use Tele_DB();
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
	$obj = Tele_PDF->new($message_from, $web_app_data);

		$message_from	- ��������� ������������ (������ �� ���)
		$web_app_data	- ������ HTML-����� (������ �� ���)
=cut
sub new {
	#	�������� ������
	my	$class = shift @_;
	#	��������� ������������, ������� ������ ������
	my	$from = shift @_;
	#	���� ������
	my	$db = Tele_DB->new( shift @_ );
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
	#	������������� ������ � ����������
#	my	$font = $pdf->font('times.ttf');
#	my	$font = font_ttf($pdf, 'font/OpenSans-Regular.ttf');
	my	$font = font_ttf($pdf, 'font/Roboto-Regular.ttf');
	#
	#	������ �����
	my	$font_bold = font_ttf($pdf, 'font/Roboto-Bold.ttf');
	#
	#	��������� �����
	my	$font_italic = font_ttf($pdf, 'font/Roboto-Italic.ttf');
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ������
	my	$self =
		{
			-DB				=> $db,				# ���� ������
			-from			=> $from,			# ��������� ������������
			-pdf			=> $pdf,			# pdf-��������
			-font			=> $font,			# �����
			-font_bold		=> $font_bold,		# ������ �����
			-font_italic	=> $font_italic,	# ��������� �����
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
	��������� ������ �� ����� *.ttf
	---
	$font = font_ttf($pdf, $file_font);
	
		$pdf		- PDF-��������
		$file_font	- ���� ������ (*.ttf)
		$font		- �����
=cut
sub font_ttf
{
	#	PDF-��������
	my	$pdf = shift @_;
	#	���� ������ (*.ttf)
	my	$file_font = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����� �� ���������
	my	$font = $pdf->font('times.ttf');
	#
	#	�������� ������������� �����
	unless (-e $file_font)
	{
		#	��������������!
		warn "���� ������ $file_font �� ������!\n";
	}
	else
	{
		#	��������� ������
		$font = $pdf->font($file_font);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	TTF-�����
	return $font;
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
	#	PDF-��������
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
	#-------------------------------------------------------------------------
	#	������� �������� (������, ������)
	my	$page_width = $self->{-page_width};
	my	$page_height = $self->{-page_height};
	#
	#	������� �� ���� ��������
	my	$margin = $self->{-page_margin};
	#-------------------------------------------------------------------------
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
	#	��������� ������ (������� ����� ����)
		$text->translate($settings{x}, $settings{y});
	#
	#	�������� ��������
	#	https://metacpan.org/pod/PDF::API2::Content#paragraph
	my	($overflow, $last_height) = $text->paragraph($string, $width, $height);
	#
	#	��������� ������ �� �������� ���� ��������
	$self->{-current_y} -= $height - $last_height + 0*36;
	
#	print STDERR "$overflow, $last_height\n";
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
	#	����� �������: https://metacpan.org/pod/PDF::Table#Table-settings
	my	%settings = (
			header_props => # ��������� �������
			{
				font 			=> $self->{-font_bold},
				font_size		=> 12,
				font_color		=> 'black',
#				bg_color		=> '#D4EBF2',
				bg_color		=> '#f8f4e8',
				valign			=> 'middle',
				padding_top		=> 7,
				padding_bottom	=> 7,
				repeat			=> 1,    # 1/0 eq On/Off  if the header row should be repeated to every new page
			},
			font 		=> $self->{-font},
			font_size	=> 12,
			padding   	=> 5,
			size		=> '8cm 1*',
			border_w	=> 0.5,
		, @_);
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������� �������� (������, ������)
	my	$page_width = $self->{-page_width};
	my	$page_height = $self->{-page_height};
	#
	#	������� �� ���� ��������
	my	$margin = $self->{-page_margin};
	#
	#	?!? �������� ���������� ������ �������
	if ($self->{-current_y} <= 1.5*72)
	{
		#	�������� ������ ��������
		$self->add_page();
	};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����� �������: https://metacpan.org/pod/PDF::Table#Table-settings
	%settings = (%settings,
		x         	=> $margin->{-left},
		w         	=> $page_width - $margin->{-left} - $margin->{-right},
		y			=> $self->{-current_y},
		next_y		=> $page_height - $margin->{-top},
		next_h		=> $page_height - $margin->{-top} - $margin->{-bottom},
	);
	#	������ ������� (�� ����� ��������)
		$settings{h} = $settings{y} - $margin->{-bottom};
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
	#
	#	������ �� �������� ���� ��������
		$self->{-current_y} = $final_y;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������ �� ������
	return $self;
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
	#
	#	(I) ������ ������� ������������
	#
	my	$data_query = $self->{-DB}->request();
	#
	#	�������� ������ ��������
		$self->add_page();
	#
	#	��������� ������ �� �������� ���� ��������	
		$self->{-current_y} -= 12;
	#
	#	���������
		$self->add_text(Encode::decode('windows-1251',
			'������ ������� ������������'),
			font => $self->{-font_bold}, font_size => 14);
	#
	#	���� �� ������� �������
	foreach my $name ('rheumatology', 'comorbidity', 'status', 'manual', 'probe', 'preparation')
	{
		#	��� ��������� ������
		next if scalar @{ $data_query->{$name} } < 2;
		#
		#	������� ������� �������
		my	$column_size = ($name eq 'probe') ? '8cm 3cm 1*' : '8cm 1*';
		#
		#	�������� �������
		$self->add_table($data_query->{$name}, size => $column_size);
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#	(II) ������ ���������� ������������� � ����������
	#
	my	$data_report = $self->{-DB}->report();
	#
	#	�������� ������ ��������
		$self->add_page();
	#
	#	��������� ������ �� �������� ���� ��������	
		$self->{-current_y} -= 12;
	#
	#	��������� �������
		$self->add_text(Encode::decode('windows-1251',
			'������ ���������� ������������� � ����������'),
			font => $self->{-font_bold}, font_size => 14);
	#
	#	��������� ������� '������������ ������������'
	my	@probe_title = map
		{
			Encode::encode('UTF-8', Encode::decode('windows-1251', $_))
		}
		('����������', '��', '����', '��', '������������');
	#
	#	���� �� ��������� ����������
	for (my $i = 0; $i < scalar @{ $data_report->{-preparation} }; $i++)
	{
		#	�������� �������
		$self->add_table($data_report->{-preparation}->[$i], size => '5cm 1*');
		#
		#	������������ ������������
		if (defined $data_report->{-probe}->[$i])
		{
			#	��������� �������
			unshift @{ $data_report->{-probe}->[$i] }, \@probe_title;
			#
			#	�������� �������
			$self->add_table($data_report->{-probe}->[$i],
				size			=> '5cm 2cm 2cm 2cm 1*',
				header_props	=>
				{
					font		=> $self->{-font_italic},
					font_size	=> 12,
					repeat		=> 1,
				},
			);
		}
		#
		#	��������� ������ �� �������� ���� ��������
		$self->{-current_y} -= 36;
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������� �� ��������
		$self->page_header_footer();
	#
	#	��� PDF-�����
	my	$pdf_file = sprintf '%s.pdf', $self->{-from}->{id};
	#
	#	��������� ����
	$self->{-pdf}->saveas($pdf_file);
	#
	#	����� �� �����
	print STDERR "Create file '$pdf_file'\n";
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	��� �����
	return $pdf_file;
}
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
} ### end of package
return 1;
__DATA__
