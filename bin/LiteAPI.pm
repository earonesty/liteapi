use File::Slurp qw(slurp);
package LiteAPI;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($HOME litedb literpc litevalidaddr Dumper burp); 

sub Dumper;

use LWP::UserAgent;
use DBI;
use File::Slurp qw(slurp);
use JSON;
use JSON::RPC::Client;

our $HOME="/var/www/liteapi";
our $DBPW=slurp("$HOME/etc/dbpw"); chomp $DBPW;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my %lite;
load_lite_conf();

my $client = new JSON::RPC::Client;

sub load_lite_conf {
    %lite=map {split /\s*=\s*/ unless /^\s*#/} split(/\n/,slurp("$HOME/etc/lite.conf"));
}

my @b58 = qw{
      1 2 3 4 5 6 7 8 9
    A B C D E F G H   J K L M N   P Q R S T U V W X Y Z
    a b c d e f g h i j k   m n o p q r s t u v w x y z
};
my %b58 = map { $b58[$_] => $_ } 0 .. 57;

sub service_status {
    my $stat=slurp("$HOME/etc/lite.status");
    my %r;
    for (split "\n", $stat) {
        chomp;
        next unless /([^:]+):(.*)/;
        $r{$1}=$2;
    }
    return \%r;
}
 
sub unbase58 {
    use integer;
    my @out;
    for my $c ( map { $b58{$_} } shift =~ /./g ) {
        for (my $j = 25; $j--; ) {
            $c += 58 * ($out[$j] // 0);
            $out[$j] = $c % 256;
            $c /= 256;
        }
    }
    return @out;
}

sub litenewaddr {
    my $db=litedb();
    my $res=literpc({method=>"getnewaddress"});
    return $res;
}
 
sub litevalidaddr {
    # does nothing if the address is valid
    # dies otherwise
    
    return 0 unless $_[0]=~/^L/;
    use Digest::SHA qw(sha256);
    my @byte = unbase58 shift;

    return 0 unless
    join('', map { chr } @byte[21..24]) eq
    substr sha256(sha256 pack 'C*', @byte[0..20]), 0, 4;

    return 1;
}

sub literpc {
    my $rpcuri = "http://localhost:$lite{rpcport}/";
    $client->ua->credentials(
        "localhost:$lite{rpcport}", 'jsonrpc', $lite{rpcuser} => $lite{rpcpassword}
    );

    my $res = $client->call( $rpcuri, $_[0] );
    if (!$res) {
        croak $client->status_line;
    }
    if ($res->is_error) {
        croak $res->error_message;
    }
    return $res->result;
}

sub litedb {
	return DBI->connect("DBI:Pg:dbname=lite;host=127.0.0.1", "lite", $DBPW, {'RaiseError' => 1});
}

sub Dumper {to_json(@_>1?[@_]:$_[0],{allow_nonref=>1,pretty=>1,canonical=>1,allow_blessed=>1});}

sub burp {
    my ($f, $d)=@_;
    open($t, ">$f.tmp") || die $!;
    print $t $d;
    close $t;
    rename("$f.tmp", $f);
}

sub cache_price {
    my ($coin, $cur) = @_;
    my $dat;
    my $tick="$HOME/log/cur";
    mkdir $tick;

    $coin=lc($coin);
    $cur=lc($cur);

    die unless $coin=~/btc|ltc/;
    die unless $cur=~/usd|eur|rur/;

    $tick="$tick/$coin.$cur";

    if (((stat($tick))[9])<time()-30) {
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        my $res=$ua->get("https://btc-e.com/api/2/${coin}_$cur/ticker");
        if ($res->is_success) {
            $dat=from_json($res->decoded_content());
            $dat=$dat->{ticker};
            open(FILE, ">:encoding(UTF-8)", "$tick.$$");
            print FILE to_json($dat);
            close FILE;
            rename("$tick.$$", $tick);
            return $dat;
        }
    }
    return from_json(slurp($tick));
}

sub cache_ticker {
    my $dat;
    my $tick="$HOME/log/ticker";
    if (((stat($tick))[9])<time()-30) {
    # poor mans ticker...
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        my $res=$ua->get("https://btc-e.com/api/2/ltc_btc/ticker");
        my $btc;
        if ($res->is_success) {
            my $dat=from_json($res->decoded_content());
            $btc=$dat->{ticker}->{sell};
            if ($btc) {
                my $res=$ua->get("https://blockchain.info/ticker");
                if ($res->is_success) {
                    $dat=from_json($res->decoded_content());
                    for (keys(%$dat)) {
                        $dat->{$_}->{"15m"}*=$btc;
                        $dat->{$_}->{"24h"}*=$btc;
                        $dat->{$_}->{buy}*=$btc;
                        $dat->{$_}->{last}*=$btc;
                        $dat->{$_}->{sell}*=$btc;
                    }
                    open(FILE, ">:encoding(UTF-8)", "$tick.$$");
                    print FILE to_json($dat);
                    close FILE;
                    rename("$tick.$$", $tick);
                    return $dat;
                }
            }
        }
    }
    return from_json(slurp($tick,binmode => ':raw'));
}

1;

# vim: noai:ts=4:sw=4
