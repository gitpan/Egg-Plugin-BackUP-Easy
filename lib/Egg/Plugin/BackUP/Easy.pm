package Egg::Plugin::BackUP::Easy;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id$
#
use strict;
use warnings;
use Carp qw/croak/;
use File::Path;
use FileHandle;

our $VERSION = '2.00';

=head1 NAME

Egg::Plugin::BackUP::Easy -  Preserve backup data for Egg plugin.

=head1 SYNOPSIS

  use Egg qw/ Plugin::BackUP::Easy /;

configuration.

  plugin_backup => {
    base_path   => '<$e.dir.tmp>/backup',
    amount_save => 60,
    extention   => 'dat',
    },

code.

  my $save_data= '.......';
  
  $e->backup(\$save_data);

=head1 DESCRIPTION

It is a plug-in that generates the directory every date, and saves data.

When the date that exceeds 'amount_save' directory exists, it is deleted from
the old one by the automatic operation.

The file name is made by a certain specific rule and if it is generation,
'_backup_create_fname' method is made for the controller.

The value of sha_hex generated from the content of data is used in default for
the file name.

  sub _backup_create_fname {
    my($e, $body)= @_;
    my $count= $e->get_count_data;
    return sprintf "%06d", $count;
  }

To correct the content of data when preserving it, '_backup_create_body' method
is made for the controller.

It preserves it as it is in default.

  sub _backup_create_body {
    my($e, $body)= @_;
    $$body=~s{(?:\r\n|\r|\n)} [\r\n]sg;
    $e->sjis_conv($body);
  }

=head1 CONFIGURATION

A configuration name is 'plugin_backup'.

=head2 base_path => [PATH]

Directory PATH preservation ahead.

There is no default. Please set it.

  plugin_backup => {
    ...
    base_path => '/path/to/backup',
    },

=head2 amount_save => [NUMBER]

Number of date left under the control of 'base_path' directories.

Default is 90.

  plugin_backup => {
    ...
    amount_save => 120,
    },

=head2 extention => [STRING]

Extension of preservation data.

Default is txt.

  plugin_backup => {
    ...
    extention => 'dat',
    },

=head1 METHODS

=head2 backup ([DATA_VALUE_REF])

The called directory of the date is made under the control of 'base_path', and
DATA_VALUE_REF is preserved by the file name generated with '_backup_create_fname'
in that.

  my $mailbody= '.....';
  $e->mail->send( body => \$mailbody );
  $e->backup( \$mailbody );

=cut

sub backup {
	my $e = shift;
	my $body= $_[0] ? (ref($_[0]) eq 'SCALAR' ? $_[0]: \$_[0])
	                : croak q{ I want backup data. };
	my $cf= $e->config->{plugin_backup}
	     || die q{ I want setup plugin->{plugin_backup}. };
	my $base= $cf->{base_path}
	     || die q{ I want setup plugin->{plugin_backup}{base_path}. };
	my $path= "${base}/". _backup_create_dname();
	unless (-e $path) {
		my $count= $cf->{amount_save} || 90;
		for my $dir (sort{$b<=>$a}(<$base/*>)) {  ## no critic.
			next if --$count> 0;
			File::Path::rmtree($dir);
		}
		File::Path::mkpath($path, 0, 0755);  ## no critic.
	}
	my $ext= $cf->{extention} || 'txt'; $ext=~s{^\.+} [];
	my $fname= $e->_backup_create_fname($body);
	my $fh= FileHandle->new("> ${path}/${fname}.${ext}")
	     || die qq{ save error (${path}/${fname}.${ext}): $! };
	print $fh $e->_backup_create_body($body);
	$fh->close;
	1;
}
sub _backup_create_dname {
	my @t= localtime(time);
	sprintf("%02d%02d", ($t[5]+ 1900), ++$t[4], $t[3]);
}
sub _backup_create_fname {
	my($e, $body)= @_;
	require Digest::SHA1;
	Digest::SHA1::sha1_hex($$body);
}
sub _backup_create_body {
	my($e, $body)= @_;
	return $$body;
}

=head1 SEE ALSO

L<File::Path>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
