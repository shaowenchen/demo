#!/bin/bash

# Script to generate self-signed certificates for a specified domain
# Usage: ./generate-certificates.sh <domain>
# Example: ./generate-certificates.sh myexample.com

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
  echo "Error: Domain name must be provided as an argument."
  echo "Usage: $0 <domain>"
  exit 1
fi

echo "Generating certificates for domain: $DOMAIN"

# Create directory for certificates
CERT_DIR="certs"
mkdir -p "$CERT_DIR"

echo "Certificates will be stored in: $CERT_DIR"

# Step 1: Generate CA certificate
# 1.1 Generate CA private key
echo "Generating CA private key..."
openssl genrsa -out "$CERT_DIR/ca.key" 4096

# 1.2 Generate CA certificate
echo "Generating CA certificate..."
openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=$DOMAIN-CA" \
  -key "$CERT_DIR/ca.key" \
  -out "$CERT_DIR/ca.crt"

# Step 2: Generate domain certificate for $DOMAIN
# 2.1 Generate private key for domain
echo "Generating private key for $DOMAIN..."
openssl genrsa -out "$CERT_DIR/$DOMAIN.key" 4096

# 2.2 Generate Certificate Signing Request (CSR) for domain
echo "Generating CSR for $DOMAIN..."
openssl req -sha512 -new \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=*.$DOMAIN" \
  -key "$CERT_DIR/$DOMAIN.key" \
  -out "$CERT_DIR/$DOMAIN.csr"

# 2.3 Generate x509 v3 extension file
echo "Creating x509 v3 extension file..."
cat > "$CERT_DIR/v3.ext" <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1=$DOMAIN
DNS.2=*.$DOMAIN
EOF

# 2.4 Generate domain certificate
echo "Generating certificate for $DOMAIN..."
openssl x509 -req -sha512 -days 3650 \
  -extfile "$CERT_DIR/v3.ext" \
  -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
  -in "$CERT_DIR/$DOMAIN.csr" \
  -out "$CERT_DIR/$DOMAIN.crt"

echo "Certificates generated successfully."
echo "Generated files:"
ls -l "$CERT_DIR/"

echo "
Next steps:"
echo "1. Use $CERT_DIR/$DOMAIN.crt and $CERT_DIR/$DOMAIN.key for your registry HTTPS configuration."
echo "2. Add $CERT_DIR/ca.crt to trusted certificates on client machines to trust this CA." 