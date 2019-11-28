#!/bin/bash

# Define useful variables
## Number of voters
declare -i NVOTERS=10

## Number of trustees
declare -i NTRUSTEES=5

## Vote weights
declare -i WEIGHTMAX=5
declare -i WEIGHTMIN=1
### RANDOM threshold
declare -i RANDMAX=32767

#########################
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
for i in {1..$NVOTERS}
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
# TODO: sss

# generate Trustees folders and distribute
cd ../Trustees
for i in {1..$NTRUSTEES}
do
    dirname="trustee${i}"
    sharename="share${i}.extensao" #TODO: change extensao to correct file type
    mkdir -p -- "$dirname"

    cp ../Admin/$sharename $dirname
done

cd ../Admin
rm -r election.key

# step 7) Assigns a weight to each voter, encrypts it with the election public key and publishes the list of encrypted weights.
touch weightlist.txt # useful for debug
touch cryptWeights.txt
for ((i=1;i<=${NVOTERS};i++))
do
    # random number 1~${WEIGHTMAX}
    printf "$((RANDOM*${WEIGHTMAX}/${RANDMAX}+${WEIGHTMIN}))\n" >> weight${i}.txt
    cat weight${i}.txt >> weightlist.txt # useful for debug
    openssl rsautl -encrypt -pubin -inkey election_public.key -in weight${i}.txt -out encrypted${i}.txt
    cat encrypted${i}.txt >> cryptWeights.txt
    rm -r weight${i}.txt
    rm -r encrypted${i}.txt
done

#copy encrypted weigths list to Tally
cp cryptWeights.txt ../Tally