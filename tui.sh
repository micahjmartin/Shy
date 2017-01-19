#!/bin/sh
if [ "$(which dialog)" != "" ]; then
	DIALOG=dialog
elif [ "$(which whiptail)" != "" ]; then
	DIALOG=whiptail
fi
echo $DIALOG
case "$DIALOG" in
*dialog*)
        OPTS="$OPTS --cr-wrap"
        high=10
        ;;
*whiptail*)
        high=12
        ;;
esac
message="\nCongratulations Elliot,\nYou have been infected with a RANSOMWARE!!!!! I know. Scary stuff.\nAnyways, Im giving you a choice. You can either encrypt some important files, or lose access to your box and not have the files encrypted. Your choice kid.\n\nEncrypt the files?\nLove, Mr. Robot"
title="Oops.."

$DIALOG --backtitle "RanPaul 0.0.1" \
       --title $title \
       --yesno $message 20 60
