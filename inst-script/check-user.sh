#!/bin/bash
# check user
check_user() {
  if [ `whoami` != 'root' ]; then
    echo "$1はルートユーザで行う必要があります。"
    echo "rootユーザもしくはsudoで実行してください。"
    exit 1
  fi
}
