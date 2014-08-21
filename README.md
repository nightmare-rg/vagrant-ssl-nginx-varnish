vagrant-ssl-nginx-varnish
=========================

Vagrant Box for testing SSL with nginx and varnish (offloading SSL) with subdomains ans wildcard certificate 

Usage:


- vagrant up
- vagrant ssh
- ifconfig
- add IP from eth1 to your hosts files: xx.xx.xx.xx example.com www.example.com test.example.com
- browse to: www.example.com and test.example.com or example.com 
