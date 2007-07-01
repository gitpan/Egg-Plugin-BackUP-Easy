package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  Dispatch::Fast
  Debugging
  Log
  BackUP::Easy
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup(

  title      => 'Example',
  root       => '/path/to/Example',
  static_uri => '/',
  dir => {
    lib      => '< $e.root >/lib',
    static   => '< $e.root >/htdocs',
    etc      => '< $e.root >/etc',
    cache    => '< $e.root >/cache',
    tmp      => '< $e.root >/tmp',
    template => '< $e.root >/root',
    comp     => '< $e.root >/comp',
    },
  template_path=> ['< $e.dir.template >', '< $e.dir.comp >'],

  plugin_backup => {
    base_path   => '< $e.dir.tmp >/mail.save',
    amount_save => 60,
    extention   => 'txt',
    },

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(

  _default => sub {
    my($e)= @_;
    my $body= $e->cache('Content')->get('BlankPage') || do {
        require Egg::Helper::BlankPage;
        my $tmp= Egg::Helper::BlankPage->out($e);
        $e->cache('Content')->set('BlankPage' => \$tmp);
        \$tmp;
      };
    $e->response->body( $body );
    },

  mailsend => sub {
    my($e)= @_;
    my $mailbody= $e->req->param('mailbody');
    $e->mail->send( .... body => \$mailbody );
    $e->backup( \$mailbody );
    $e->res->redirect('/mail-complete');
    },

  );
# ----------------------------------------------------------

sub _backup_create_body {
	my($e, $body)= @_;
	$$body=~s{(?:\r\n|\r|\n)} [\r\n]sg;
	$e->sjis_conv($body);
}

1;
