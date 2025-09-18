#
#	����������� ������������ �����������
#	https://perldoc.perl.org/strict
use strict;
#
#	���������� ��������������� ����������������
#	https://perldoc.perl.org/warnings
use warnings;
#
#	��������� ��������� ������ Perl, ���������� ��� ��� ������
#	https://metacpan.org/pod/Data::Dumper
use	Data::Dumper;
#
#	������������� ��������
#	https://perldoc.perl.org/Encode
use Encode;# qw(decode encode);
#
#	JSON (JavaScript Object Notation) �����������/�������������
#	https://metacpan.org/pod/JSON
use	JSON;
#
#	��������-���
#	https://metacpan.org/pod/WWW::Telegram::BotAPI
use WWW::Telegram::BotAPI;
#
#	����� ���� (�������� � @BotFather)
#	my	$token = '8105314834:AAE6cZ9KTYsXr4od7SvZckslisl1MRp0OXI';
#
#	��� ����: @tele_rheumatology_bot
#
my	$token = '8278981933:AAGOZMWywJZxlR-Vj5kwh4HeISQhwPpXuwE';
#
#	������� ������ API
my	$api = WWW::Telegram::BotAPI->new(token => $token);
=pod
#
#	�������� ����������
my	$keyboard =
	[[{
		text => decode('windows-1251', '������'),
		web_app => {
			url => 'https://viacheslav-simakov.github.io/'
		},
	},],];
=cut
#
#	�������� ��������� ����������
my	$offset = 0;
#
#	������� ���� ��������� ������� ����
print STDERR "Telegram Bot \@tele_rheumatology_bot ... started\n\n";
while (1) {
	#
    #	�������� ����������
	#
    my	$updates = $api->getUpdates(
		{
			offset => $offset,	# ��������
			timeout => 30,		# ������ ����� (long polling)
		}
	) or die "������ ��� ��������� ����������: $!";
    #
    #	������������ ������ ����������
	#
    foreach my $update (@{ $updates->{result} })
	{
		#	����������� ��������
        $offset = $update->{update_id} + 1 if $update->{update_id} >= $offset;
		#
		#	������
			logger($update);
        #
		#	���������
        my	$message = $update->{message} or next;
		#
		#	����� ���������
        my	$msg_text = $message->{text} or undef;
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #	��������� ������
		if ($message->{web_app_data}->{data})
		{
			#	������ Web App
			web_app_data($message);
			#
			#	��������� �������� �����
			next;
		}
        elsif ($msg_text and $msg_text =~ m{^/start}i)
		{
			#	����������
			web_app_keyboard($message);
        }
        else
		{
            $api->sendMessage(
			{
                chat_id => $message->{chat}->{id},
				parse_mode => 'Markdown',
                text => decode('windows-1251', sprintf(
					"������ *%s*!\n� ��� \"����������� ��������� �����-�����������\".\n����������� /start ��� ������ ������.",
					encode('windows-1251', $message->{from}->{first_name}))
				),
            });
        }
		#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    }
}
=pod
	����� �� �����
	---
	logger($update)
		
		$update	- ������ �� ���������� (���)
=cut
sub logger
{
	#	������ �� ����������
	my	$update = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	������
	printf STDERR "\n\nfrom_id='%s'\ttext='%s'\tweb_app_data='%s'\n%s%s\n",
		$update->{message}->{from}->{id},
		encode('windows-1251', $update->{message}->{text} || ''),
		encode('windows-1251', $update->{message}->{web_app_data}->{data} || ''),
		Dumper($update),
		('~' x 79);
}
=pod
	������
	---
	_button($text, $page, $emoji)
	
		$text	- ������� �� ������
		$page	- ��������
		$emoji	- ������
=cut
sub _button
{
	#	�������� ������, html-��������
	my	($text, $page, $emoji) = @_;
	
#	my $packed_utf8 = "\x{263A}";
#	my $packed_utf8 = "\x{0001f170}";
#	my $packed_utf8 = "\x{2753}";
		$emoji = defined $emoji ? $emoji . ' ' : '';
	#
	#	������ �� ���
	return
	{
		text => $emoji . decode('windows-1251', $text),
		web_app => {url => 'https://viacheslav-simakov.github.io/' . $page},
	}
}
=pod
	����� ���������� �� �����
	---
	web_app_keyboard($message)
		
		$message	- ������ �� ��������� (���)
=cut
sub web_app_keyboard
{
	#	������ �� ���������
	my	$msg = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	����������
	my	$keyboard = [
		[
			_button('������������', 'index.html', "\x{1F50D}"),
			_button('�������� �����������', 'preparation.html'),
		],
		[
			_button('������������� �����������','preparation.html'),
			_button('������������� ���������', 'preparation.html'),
		],
		[
			_button('������������ ����������', 'preparation.html', "\x{1F39B}"),
			_button('������������ ������������', 'preparation.html', "\x{1F52C}"),
		],
		[_button('���������', 'preparation.html', "\x{1F48A}")],
	];
	#-----------------------------------------------------------------
	#	���������
	$api->sendMessage(
	{
		chat_id => $msg->{chat}->{id},
		parse_mode => 'Markdown',
		text => decode('windows-1251',
			"*����������� ��������� �����-�����������*\n(���� ����� �.�. ������������)"),
		reply_markup =>
		{
			keyboard => $keyboard,
			resize_keyboard => \1,
			one_time_keyboard => \1,
		},
	});
}
=pod
	��������� ������ HTML-����� ���������� �� Web App
	---
	web_app_data($message)
	
		$message	- ������ �� ��������� (���)

=cut
sub web_app_data
{
	#	������ �� ���������
    my	$message = shift @_;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	ID ����
    my	$chat_id = $message->{chat}->{id};
	#
	#	������ HTML-�����
    my	$web_app_data = encode('UTF-8', $message->{web_app_data}->{data});
	#
    #	������������� JSON ������ ���������� �� Web App
	my	$data = decode_json($web_app_data);

	print STDERR encode('windows-1251', $data->{message})."\n";
	return;
	
	
    $api->sendMessage(
	{
        chat_id => $chat_id,
        text => "Received data from Web App:\n" . $data->{some_key},
    });
}