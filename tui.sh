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
message="Congratulations Elliot,\nYou have been infected with a RANSOMWARE!!!!!\nI know. Scary stuff.\nAnyways, Im giving you a choice. You can either encrypt some important files, or lose access to your box and keep the files. Your choice kid.\nLove, Mr. Robot\n\nKeep the files?"
title="Oops.."

$DIALOG --backtitle "RanPaul 0.0.1" \
       --title "$title" \
       --yesno "$message" 15 60
