#!/bin/bash
# check user
check_user() {
  if [ `whoami` = 'root' ]; then
    echo "$1は一般ユーザで行う必要があります。"
    echo "rootユーザもしくはsudoで実行しないで下さい。"
    exit 1
  fi
}
