#!/bin/bash

# OSチェック
source ./inst-script/check-os.sh

# restart apache
source ./inst-script/${OS}/service-restart.sh

