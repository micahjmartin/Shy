#!/bin/bash
# Creates a script that will decrypt all the files in a given decryption packet
BASEFILE="shell.sh"
[ "$1" = "" ] && echo "USAGE: $0 packet private-key" && exit
[ "$2" = "" ] && echo "USAGE: $0 packet private-key" && exit
[ "$3" != "" ] && code="$(cat $3 | openssl base64 | tr '\n' '!' | sed 's:!:\\n:g' | head -c -1)"
#echo "[$1] [$2]"
#echo "Creating decryption script for [$1]"
#echo "[*] Getting Primary Key..."
key=$(grep ^$ -B100 $1 | openssl base64 -d | openssl rsautl -decrypt -inkey $2)
#echo "[+] Key decrypted: $key"
#echo "[*] Decrypting Targets..."
targets=$(grep  ^$ -A999999999999999 $1 | openssl base64 -d | openssl aes-256-cbc -d -k "$key")
if [ "$?" != "0" ]; then
   echo Bad Key!
   exit
fi
#echo "Code: $code"
if [ "$code" == "" ]; then
   sed "s:__KEY__:$key:g; s:__TARGETS__:$(echo $targets):g" $BASEFILE | grep -v -e "__STRING" -e "PUBLICKEY"
else
   sed "s:__KEY__:$key:g; s:__TARGETS__:$(echo $targets):g; s:__STRING__:$code :g" $BASEFILE
fi
