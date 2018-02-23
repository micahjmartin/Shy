# Outline the Shy client

### Get OS
Figure out the OS, error if not unix

### Check for a TUI
See if we can get a TUI message. Might be difficult in python

### Check all the requirements
- Root
- OpenSSL (Or python lib)
- Iptables (python lib?)

### Make file modifiable
Undo any chattrs, appends, or chmods

### Init
1. Save the public key in memory and on disk
2. Generate a new AES key
3. Encrypt AES key with pubkey for sending back to the server

### Encrypt a file
1. Add file to master list
2. Unlock the file
3. Encrypt the file in memory and dump the contents back into the file

### Encrypt all files
Loop through the target list and call encrypt on everything that isnt whitelisted

### Set the message to be displayed and the message
/etc/profile
grub?

### Lock out the users
Kill every session on the machine
/etc/nologin?

### Call back
Send the key and file list back to the server

### Main Function
1. Trap kill signals
2. Initialize
3. Loop through targets
4. Encrypt list of files
5. Send file list and key back to server and save on disk in a few places
6. Set the Ransom message
7. Lock users out
8. Delete self
9. Exit
