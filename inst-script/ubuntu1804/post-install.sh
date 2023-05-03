#!/bin/bash

###
# Problem: Cannot start Redmine
# Log: The application encountered the following error: You have already activated strscan 3.0.1, but your Gemfile requires strscan 3.0.4.
#        Since strscan is a default gem, you can either remove your dependency on it or try updating to a newer version of bundler that supports strscan as a default gem.
# Temporary solution: Force reinstall strscan
###
sudo bash -cl "${GEM} update strscan --no-document" || fatal_error_exit ${BASH_SOURCE}

# apache confs
## set Redmine.pm
sudo mkdir -p /etc/perl/Apache/Authn || fatal_error_exit ${BASH_SOURCE}
sudo rm -f /etc/perl/Apache/Authn/Redmine.pm || fatal_error_exit ${BASH_SOURCE}
sudo ln -s ${ALM_INSTALL_DIR}/extra/svn/Redmine.pm /etc/perl/Apache/Authn/Redmine.pm || fatal_error_exit ${BASH_SOURCE}

## modules
sudo a2enmod expires || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod dav_fs || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod authz_svn || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod proxy_http || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod headers || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod rewrite || fatal_error_exit ${BASH_SOURCE}
#sudo a2enmod passenger || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod perl || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod wsgi || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod cgi || fatal_error_exit ${BASH_SOURCE}
sudo a2dismod mpm_event || fatal_error_exit ${BASH_SOURCE}
sudo a2enmod mpm_prefork || fatal_error_exit ${BASH_SOURCE}

## site
sudo a2ensite alminium || fatal_error_exit ${BASH_SOURCE}

# vim: set ts=2 sw=2 et:
