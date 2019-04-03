# sqlplus_select2csv
sqlplusの結果をcsv形式に変換

## 使い方
```
$ echo "<SELECT文>" | ./sqlplus_select2csv.sh -c "<SQL*Plus接続文字列>" 
```
```
$ cat "<SQLファイル>" | ./sqlplus_select2csv.sh -c "<SQL*Plus接続文字列>"
```

## オプション

* -c "<SQL*Plus接続文字列>"：必須。OracleDBの接続先を指定する。
* -d "<区切り文字>"：区切り文字を設定する。デフォルトはタブ区切り。
* -f "<SQLファイル>"：SQLファイル内のSELECT文を実行してcsvに変換する。
* --help：使用方法を表示する。
