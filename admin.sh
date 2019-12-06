#!/bin/bash

# Define useful variables
## Number of voters
declare -i NVOTERS=10

## Number of trustees
declare -i NTRUSTEES=5
declare -i THRESHOLD=4

## Vote weights
declare -i WEIGHTMAX=5
declare -i WEIGHTMIN=1
### RANDOM threshold
declare -i RANDMAX=32767
declare PASSWORD=password

#########################
# Setup entities' folders
mkdir Admin 
mkdir BallotBox 
mkdir Counter 
mkdir Tally 
mkdir Trustees 
mkdir Voters

cp key_generator Admin
cp weights_encryptor Admin
cp Make_Shares Admin
cp Join_Shares Counter
cp counter.sh Counter

# step 1) Generate a root CA certificate and private key
cd Admin
sudo openssl genrsa -des3 -passout pass:admin -out my-ca.key 2048 
sudo openssl req -new -x509 -days 3650 -key my-ca.key -passin pass:admin -out my-ca.crt -subj "/C=PT/ST=Lisbon/L=Lisbon/O=IST/OU=CSC/CN=CSC/emailAddress=CSCgp13"

# step 4) Generate the election key - a special homomorphic key pair
./key_generator

cd ../Voters
for ((i=1;i<=${NVOTERS};i++))
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
sudo openssl enc -aes-256-cbc -in election_private.key -k $PASSWORD -pbkdf2 -out election_private_encrypted.key
mv election_private_encrypted.key ../Counter
./Make_Shares $NTRUSTEES $THRESHOLD $PASSWORD

# generate Trustees folders and distribute
cd ../Trustees
for ((i=1;i<=${NTRUSTEES};i++))
do
    dirname="trustee${i}"
    sharename="Share${i}.txt" #TODO: change extensao to correct file type
    mkdir -p -- "$dirname"

    mv ../Admin/$sharename $dirname
done

cd ../Admin
rm -r election_private.key

# step 7) Assigns a weight to each voter, encrypts it with the election public key and publishes the list of encrypted weights.
touch weightlist.txt # useful for debug
touch cryptWeights.txt
for ((i=1;i<=${NVOTERS};i++))
do
    # random number 1~${WEIGHTMAX}
    weight=$((RANDOM*${WEIGHTMAX}/${RANDMAX}+${WEIGHTMIN}))
    printf $weight >> weight.txt
    cat weight.txt >> weightlist.txt # useful for debug
    ./weights_encryptor weight
    cat encrypted.txt >> cryptWeights.txt
    rm -r weight.txt
    rm -r encrypted.txt
done

#copy encrypted weigths list to Tally
cp cryptWeights.txt ../Tally