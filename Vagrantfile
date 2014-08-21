# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

$script = <<SCRIPT
aptitude update
aptitude safe-upgrade -y
aptitude install -y apt-transport-https curl
curl https://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -
echo "deb https://repo.varnish-cache.org/debian/ wheezy varnish-3.0" > /etc/apt/sources.list.d/varnish-cache.list
curl http://www.dotdeb.org/dotdeb.gpg | apt-key add -
echo "deb http://packages.dotdeb.org wheezy all" > /etc/apt/sources.list.d/dotdeb.list
aptitude update
aptitude install -y varnish nginx php5-fpm openssl
mkdir -p /etc/nginx/ssl
mkdir -p /var/www/www.example.com
mkdir -p /var/www/test.example.com
cp /vagrant/files/server.key /etc/nginx/ssl
cp /vagrant/files/server.crt /etc/nginx/ssl
cp /vagrant/files/index_www.php /var/www/www.example.com/index.php
cp /vagrant/files/index_test.php /var/www/test.example.com/index.php
cp /vagrant/files/nginx_default /etc/nginx/sites-available/default
cp /vagrant/files/varnish_default.vcl /etc/varnish/default.vcl
cp /vagrant/files/varnish /etc/default/varnish
/etc/init.d/varnish restart
/etc/init.d/nginx restart
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "wheezy"
  config.vm.hostname = "testbox-ssl-nginx-varnish"
  config.vm.network "public_network", :bridge => "en0: Ethernet"
  config.vm.provision "shell", inline: $script

end
