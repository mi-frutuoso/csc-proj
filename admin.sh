#!/bin/bash

# Define useful variables, read from file parameters.txt
## Number of voters
NVOTERS=0

## Number of trustees
NTRUSTEES=0
THRESHOLD=0

## Vote weights
WEIGHTMAX=0
WEIGHTMIN=0
### RANDOM threshold
RANDMAX=0
PASSWORD=0

input="parameters.txt"
while IFS= read -r line
do
    parameter=$(echo "${line}" | cut -d "=" -f1)
    value=$(echo "${line}" | cut -d "=" -f2)
    case ${parameter} in
        NVOTERS)
            NVOTERS=$value
            ;;
        NTRUSTEES)
            NTRUSTEES=$value
            ;;
        THRESHOLD)
            THRESHOLD=$value
            ;;
        WEIGHTMAX)
            WEIGHTMAX=$value
            ;;
        WEIGHTMIN)
            WEIGHTMIN=$value
            ;;
        RANDMAX)
            RANDMAX=$value
            ;;
        PASSWORD)
            PASSWORD=$value
            ;;
    esac
done < "$input"

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
cp tally.sh Tally
cp calculator Tally
cp sumcheck Tally
cp decrypt Counter

# step 1) Generate a root CA certificate and private key
cd Admin
sudo openssl genrsa -des3 -passout pass:admin -out my-ca.key 2048 
sudo openssl req -new -x509 -days 3650 -key my-ca.key -passin pass:admin -out my-ca.crt -subj "/C=PT/ST=Lisbon/L=Lisbon/O=IST/OU=CSC/CN=CSC/emailAddress=CSCgp13"

# step 4) Generate the election key - a special homomorphic key pair
./key_generator

cd ../Voters
for ((i=1;i<=${NVOTERS};i++))
do
    if [ "$i" -lt "10" ]; then
        j="00${i}"
    else
        if [ "$i" -lt "100" ]; then
            j="0${i}"
        else
            j=i
        fi
    fi
    dirname="voter${j}"
    pemname="voter${j}.pem"
    csrname="voter${j}.csr"
    crtname="voter${j}.crt"
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

    # copy files to each voter folder
    cp ../../voter.sh .
    cp ../../weights_encryptor .
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
    sharename="Share${i}.txt"
    mkdir -p -- "$dirname"

    mv ../Admin/$sharename $dirname
done

cd ../Admin
rm -r election_private.key

# step 7) Assigns a weight to each voter, encrypts it with the election public key and publishes the list of encrypted weights.
touch weightlist.txt # useful for debug
for ((i=1;i<=${NVOTERS};i++))
do
    if [ "$i" -lt "10" ]; then
        j="00${i}"
    else
        if [ "$i" -lt "100" ]; then
            j="0${i}"
        else
            j=i
        fi
    fi
    # random number 1~${WEIGHTMAX}
    weight=$((RANDOM*${WEIGHTMAX}/${RANDMAX}+${WEIGHTMIN}))
    printf "${weight}\n" >> weight.txt
    cat weight.txt >> weightlist.txt # useful for debug
    rm -r weight.txt

    ./weights_encryptor $weight # --> generate encrypted.txt
    # rename file
    weightFile="cryptWeight_voter${j}.txt"
    mv encrypted.txt ${weightFile}
    #copy encrypted weight to Tally (or move)
    cp ${weightFile} ../Tally
done
