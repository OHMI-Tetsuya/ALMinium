#!/bin/bash

# apache confs
## set Redmine.pm
sudo mkdir -p /etc/perl/Apache/Authn
sudo rm -f /etc/perl/Apache/Authn/Redmine.pm
sudo ln -s ${ALM_INSTALL_DIR}/extra/svn/Redmine.pm /etc/perl/Apache/Authn/Redmine.pm

## modules
sudo a2enmod expires
sudo a2enmod dav_fs
sudo a2enmod authz_svn
sudo a2enmod proxy_http
sudo a2enmod headers
sudo a2enmod rewrite
#sudo a2enmod passenger
sudo a2enmod perl
sudo a2enmod wsgi
sudo a2enmod cgi
sudo a2dismod mpm_event
sudo a2enmod mpm_prefork

## site
sudo a2ensite alminium

# vim: set ts=2 sw=2 et:
