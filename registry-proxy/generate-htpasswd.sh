USERNAME=$1
PASSWORD=$2

docker run \
  --entrypoint htpasswd \
  httpd:2 -Bbn $USERNAME $PASSWORD