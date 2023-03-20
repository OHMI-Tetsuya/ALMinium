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

# update submodules
if [ $(git config -l | egrep 'submodule.+url=' | wc -l) -ne \
     $(grep submodule .gitmodules | wc -l) ]; then
  git submodule init || fatal_error_exit ${BASH_SOURCE}
fi
git submodule sync || fatal_error_exit ${BASH_SOURCE}
git submodule update || fatal_error_exit ${BASH_SOURCE}
