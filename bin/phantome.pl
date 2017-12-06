#!/usr/bin/perl

# phantome2
# no parameters, expects to be run from directory with the file
# all files created are two colum tables
#
# folker@anl.gov

# >fig|10756.2.peg.4 [Phage protein] [ACLAME_Phage_proteins_with_unknown_functions; Phage_cyanophage; Phage_experimental] [10756.2] [Bacillus phage phi29]
#MVQNDFVDSYDVTMLLQDDDGKQYYEYHKGLSLSDFEVLYGNTADEIIKLRLDKVL
#>fig|10756.2.peg.5 [involved in DNA replication] [Not in a subsystem] [10756.2] [Bacillus phage phi29]
#MGKIFDQEKRLEGTWKNSKWGNQGIIAPVDGDLKMIDLELEKKMTKLEHENKLMKNALYELSRMENNDYATWVIKVLFGGAPHGAK
#>fig|10756.2.peg.6 [DNA polymerase (EC 2.7.7.7), phage-associated] [Phage_replication; T4-like_phage_core_proteins] [10756.2] [Bacillus phage phi29]
#MPRKMYSCDFETTTKVEDCRVWAYGYMNIEDHSEYKIGNSLDEFMAWVLKVQADLYFHNLKFDGAFIINWLERNGFKWSADGLPNTYNTIISRMGQWYMIDICLGYKGKRKIHTVIYDSLKKLPFPVKKIAKDFKLTVLKGDIDYHKERPVG

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Digest::MD5 qw (md5_hex);
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Uncompress::Gunzip;

my $filename = shift @ARGV;

unless ($filename) {
    print STDERR "Usage: \tmotudb.pl <filename1> \n";
    print STDERR " \te.g. motudb.pl mOTU.v1.padded	\n";
    exit 1;
}

my $fh1 = new IO::Uncompress::Gunzip("$filename")
  or die "Cannot open '$filename': $!\n";

open( my $md52id,       '>', 'md52id.txt' )      or die;
open( my $md5seq,       '>', 'md52seq.txt' )     or die;
open( my $md5func,      '>', 'md52func.txt' )    or die;
open( my $md5tax,       '>', 'md52tax.txt' )     or die;
open( my $id2hierarchy, '>', 'id2hierarchytxt' ) or die;

my ( $id, $md5s, $func, $subsystems, $taxid, $seq );

while (<$fh1>) {

    # for every header line
    if (/^>/) {

        # if we already have a sequence ...  ## need to take care of last record
        if ($seq) {
            process_record();
        }

# >fig|10756.2.peg.12 [Phage protein] [ACLAME_Phage_head; Phage_capsid_proteins] [10756.2] [Bacillus phage phi29]

        my $line = $_;
        $line =~ s/^>//g;
        $line =~ s/\]//g;

        my @parts   = split( / \[/, $line );
        $id         = $parts[0];
        $func       = $parts[1];
        $subsystems = $parts[2];
        $taxid      = $parts[3];
    }
    else {
        s/\s+//g;    # remove whitespace
        $seq .= $_;  # add sequence
    }
}

# print final record
if ($seq) {
    process_record();
}

close($fh1);

exit 0;

sub process_record {
    $seq  = lc($seq);
    $md5s = md5_hex($seq);

    # print the output
    if ( $id && $func && $taxid ) {
        print $md52id "$md5s\t$id\n";
        print $md5seq "$md5s\t$seq\n";
        print $md5func "$md5s\t$func\n";
        print $md5tax "$md5s\t$taxid\n";
    }

    # print one entry per subsystem record we find
    foreach my $ss ( split( /; /, $subsystems ) ) {
        print $id2hierarchy "$id\t$ss\t$func\n";
    }

    # reset the values for the next record
    ( $id, $md5s, $func, $subsystems, $taxid, $seq ) = ( '', '', '', '', '', '' );
}
