#!/bin/bash

# Creates a script that will decrypt all the files in a given decryption packet
[ "$1" = "" ] && echo "USAGE: $0 packet private-key" && exit
[ "$2" = "" ] && echo "USAGE: $0 packet private-key" && exit
echo "[$1] [$2]"
echo "Creating decryption script for [$1]"
echo "[*] Getting Primary Key..."
key=$(grep ^$ -B100 $1 | openssl base64 -d | openssl rsautl -decrypt -inkey $2)
echo "[+] Key decrypted: $key"
echo "[*] Decrypting Targets..."
targets=$(grep  ^$ -A999999999999999 $1 | openssl base64 -d | openssl aes-256-cbc -d -k "$key")
echo -n $targets

