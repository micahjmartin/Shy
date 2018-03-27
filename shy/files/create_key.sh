[ "$1" = "" ] && name="shy" || name="$1"
openssl genrsa -out $name.key 2048 
openssl rsa -in $name.key -pubout > $name.pub
