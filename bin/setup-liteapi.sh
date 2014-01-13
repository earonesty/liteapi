#!/bin/bash

if [ -z "$1" ]; then
    echo "usage $0 <host>"
    exit 1
fi
host=$1

HOME=/var/www/liteapi
mkdir $HOME
cd $HOME

rsync -a --exclude "**/coin/**" --exclude "**/log/**" $host:$HOME/ $HOME/ &

yum -y update

yum -y install bind-utils cpan
yum -y install httpd httpd-devel mod_ssl mod_perl php boost
yum -y install 'perl(File::Slurp)' 'perl(JSON)' 'perl(Digest::SHA)' 'perl(IO::Socket::SSL)' 'perl(DBI)'  'perl(URI)' 'perl(LWP::UserAgent)' 'perl(Test::Simple)' 'perl(CGI)' 'perl(parent)' 'perl(DBD::Pg)'
perl -MJSON::RPC::Client -e 1 2> /dev/null || cpan -i 'JSON::RPC::Client'

(crontab -l ; echo "* * * * * $HOME/bin/minutely")  |uniq - | crontab -
(crontab -l ; echo "0 * * * * /var/www/liteapi/bin/hourly")  |uniq - | crontab -

if [ ! -n "`which pgsql`" ]; then
    yum -y install postgresql postgresql-server postgresql-contrib 
    service postgresql initdb 
    rsync -a $host:/var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf
    /etc/init.d/postgresql start
    groupadd -g 502 lite
    useradd -u 502 -g 502 lite
    sudo -u postgres psql < bin/user.sql
    sudo -u postgres psql lite < bin/lite.sql
fi


bin/litedb "select * from cbs"

cd src/openssl-1.0.1f
make install
cd $HOME

ln -fs $HOME/etc/lite.conf coin/lite.conf

cp src/litecoin-0.8.6.2/src/litecoind /usr/local/bin/litecoind

chkconfig postgresql on
chkconfig httpd on

ln -fs $HOME/LiteAPI.pm /usr/share/perl5/
cp etc/liteapi.crt /etc/pki/tls/certs/liteapi.crt
cp etc/liteapi.key /etc/pki/tls/private/liteapi.key

ln -fs $HOME/etc/liteapi.conf /etc/httpd/conf.d/

ifconfig | grep "inet addr:" | grep -v 127.0 | cut -f 2 -d ":" | cut -f 1 -d " " | tail -n 1 > etc/primaryip

primaryip=`cat etc/primaryip`

rpm -i src/maradns-2.0.07d-1.x86_64.rpm
chkconfig maradns on
rm -rf /etc/maradns
ln -fs $HOME/etc/maradns /etc/maradns
ln -fs $HOME/etc/mararc /etc/mararc

perl -i -pe "s{\\d+\\.\\d+\\.\\d+\\.\\d+}{$primaryip}" etc/mararc
perl -i -pe "s{\\d+\\.\\d+\\.\\d+\\.\\d+}{$primaryip}" etc/maradns/db.liteapi.org

