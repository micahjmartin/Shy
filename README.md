# Shy
Meant to be a quick and dirty ransomware written in Bash/Sh. 
Relies on OpenSSL for all the encryption.

This program was written for education purposes only.
It was designed for red/blue security competitions.

## Usage
Shy renders a script based on the configuration file given to it.

### Update the config
Generate a private/public key pair and update `config.yml`

Change the password and add any files that you want to be
added to the target list.

### Generate the script
Shy can be run either as a web server or a stand-alone builder

**Server Usage**

Run the server, you may specify the port number
```
./Shy.py [port]
```
Get the script
```
curl localhost/shy
```

**Inplace Usage**

To build a config file inplace
```
./Shy.py <file>
```

## Disclaimer
As mentioned this is to be used for educational purposes only. The script is not guarenteed to work in any way.
Only run and develop on testing machines. This program WILL DESTROY YOUR FILES. Currently there is no functional decryption.
