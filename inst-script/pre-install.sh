#!/bin/bash

# install packages
if [ ! -f packages.installed ]; then
  echo "*** run ${OS}'s pre-install script ***"
  source inst-script/${OS}/pre-install.sh
  touch packages.installed
fi

# install gems
if [ ! -f gems.installed ]; then
  echo "*** run gems script ***"
  source inst-script/gems.sh
  touch gems.installed
fi
