#!/bin/bash

# Setup entities' folders
mkdir Admin 
mkdir BallotBox 
mkdir Counter 
mkdir Tally 
mkdir Trustees 
mkdir Voters

# step 1) Generate a root CA certificate and private key
cd Admin
sudo openssl genrsa -des3 -passout pass:admin -out my-ca.key 2048 
sudo openssl req -new -x509 -days 3650 -key my-ca.key -passin pass:admin -out my-ca.crt -subj "/C=PT/ST=Lisbon/L=Lisbon/O=IST/OU=CSC/CN=CSC/emailAddress=CSCgp13"

# step 4) Generate the election key - a special homomorphic key pair
openssl genrsa -out election.key 1024
openssl rsa -in election.key -pubout -out election_public.key

cd ../Voters
for i in {1..10}
do
    dirname="voter${i}"
    pemname="voter${i}.pem"
    csrname="voter${i}.csr"
    crtname="voter${i}.crt"
    mkdir -p -- "$dirname"
    cd $dirname

    # step 3) Generate a certificate for every voter
    openssl genrsa -out $pemname 1024
    openssl req -new -key $pemname -out $csrname -subj "/C=PT/ST=Lisbon/L=Lisbon/O=IST/OU=CSC/CN=SC/emailAddress=CSCgp13"
    openssl x509 -req -in $csrname -out $crtname -sha1 -CA ../../Admin/my-ca.crt -CAkey ../../Admin/my-ca.key -CAcreateserial -days 3650 -passin pass:admin

    # step 2) Install the root certificate in the tally official app
    cp ../../Admin/my-ca.crt .

    # step 5) Install on each voter app: c. The election public key
    cp ../../Admin/election_public.key .
    cd ..
done
cd ../Admin

# step 6) Split the election private key using Shamir’s secret sharing, distribute each of the shares by the trustees, and erase the private key.