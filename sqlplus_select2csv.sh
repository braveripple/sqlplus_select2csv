#!/bin/bash

#
# 定数
#
# 一時的な区切り文字
readonly TEMP_COLUMN_SEPARATOR="#XX#"

function induction() {
  echo "Try '--help' option for more information." 1>&2
  exit 1
}
function usage() {
  echo "Usage:$0 -c <SQL*Plus接続文字列> [-f sqlfile=-] [-d delimiter=\t]" 1>&2
  exit 0
}

#
# getopts
#
connection_string=""
delimiter="\t"
file="-"
while getopts c:d:f:-: OPT
do
  case $OPT in
    -)
      case "${OPTARG}" in
        help) usage;;
      esac
      ;;
    c ) connection_string="${OPTARG}";;
    d ) delimiter="${OPTARG}";;
    f ) file="${OPTARG}";;
    :|\?) induction;;
  esac
done

#
# check
#
if [ -z "${connection_string}" ]; then
  echo "SQL*Plus接続文字列は必須です" 1>&2
  induction
fi

# -------------------------------------------------------

function make_select_sql_for_sqlplus() {

  local sql=$(cat -)
  local sqlplus_sql=$(cat << EOF

REMARK #### DB CONNECT ####
WHENEVER OSERROR EXIT 9
WHENEVER SQLERROR EXIT 9
connect ${connection_string}

REMARK #### SQLFILE SELECT ####
REMARK # 1ページの行数
SET PAGESIZE 50000

REMARK # 1行の長さ
SET LINESIZE 30000

REMARK # 1度にFETCHするデータ数
SET ARRAYSIZE 100

SET TAB ON
SET TRIMSPOOL ON

REMARK # SELECT 結果の区切り文字列
SET COLSEP '${TEMP_COLUMN_SEPARATOR}'

REMARK # 問い合わせの結果レコード件数を表示しない
SET FEEDBACK OFF

REMARK # 置換変数に設定する前後の状態を表示しない
SET VERIFY OFF

REMARK # SELECT する列のヘッダ情報を表示しない
SET HEAD OFF

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
WHENEVER OSERROR EXIT 2 ROLLBACK

REMARK # SQLを実行
${sql}
EXIT;
EOF
)

  echo "${sqlplus_sql}"
  return 0
}

function execute_sqlplus() {

  local sqlplus_sql=$(cat -)
  local response=$(sqlplus -s -L /nolog << EOS
    ${sqlplus_sql}
EOS
  )

  local return_code=$?
  if [[ $return_code -ne 0 ]]; then
    >&2 echo "${return_code},${response}"
    exit $return_code
  fi
  echo "${response}"
  return 0
}

function convert_from_sqlplus_to_csv() {
  # タブ区切り
  local response=$(cat -)
  local response_csv=$(
    echo "${response}"   |
    perl -pe "s/^\s+//g" |
    perl -pe "s/[\t ]+${TEMP_COLUMN_SEPARATOR}[\t ]+/${delimiter}/g"  |
    perl -pe "s/[\t ]+${TEMP_COLUMN_SEPARATOR}/${delimiter}/g"  |
    perl -pe "s/${TEMP_COLUMN_SEPARATOR}[\t ]+/${delimiter}/g"  |
    perl -pe "s/${TEMP_COLUMN_SEPARATOR}/${delimiter}/g"        |
    sed -e "/^$/d"
  )
  echo "${response_csv}"
  return 0
}

# -------------------------------------------------------

cat "${file}" | make_select_sql_for_sqlplus | execute_sqlplus | convert_from_sqlplus_to_csv