# Shy
Meant to be a quick and dirty ransomware written in Bash/Sh. WIP however the encryption works.
Relies on OpenSSL for all the encryption.

This program was written for education purposes only. It was designed for red/blue security competitions.

## Usage
Generate a new kek
```
openssl genrsa -out priv.key 2048
```

Add the public key in `main.sh`.

Run `main.sh` on the target computer.

## Disclaimer
As mentioned this is to be used for educational purposes only. The script is not guarenteed to work in any way.
Only run and develop on testing machines. This program WILL DESTROY YOUR FILES. Currently there is no functional decryption.