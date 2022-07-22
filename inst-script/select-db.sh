# select db

if [ "${ALM_DB_SETUP}" = "y" ]; then
  if [ "${ALM_UPGRADE}" = "y" ]; then
    if [ "${ALM_DB_HOST}" != "" ]; then
      ALM_USE_EXISTING_DB=y
    else
      ALM_USE_EXISTING_DB=N
      ALM_DB_HOST=localhost
      ALM_DB_ROOT_PASS=
    fi
  else
    if  [ "${ALM_DB_HOST}" = "" ]; then
      echo ""
      echo -n 既に設置済みのMySQLデータベースサービスを利用しますか？[y/N]
      read ALM_USE_EXISTING_DB;
      if [ "${ALM_USE_EXISTING_DB}" = "y" ]; then
        # db client install
        source inst-script/${OS}/install_db_client.sh
        # DBへのアクセスが成功するまでループしながらチェック
        CHK_DB=
        while [ "${CHK_DB}" = "" ]; do
          echo ""
          echo -n データベースサーバー名を入力してください:
          read ALM_DB_HOST
          echo -n データベース管理者パスワードを入力してください：
          read ALM_DB_ROOT_PASS
          CHK_DB=$(db_test)
          if [ "${CHK_DB}" = "" ]; then
            echo データベースに接続できませんでした。
          fi
        done
      else
        ALM_DB_HOST=localhost
        ALM_DB_ROOT_PASS=
      fi
    else
      ALM_USE_EXISTING_DB=y
    fi
  fi
fi

