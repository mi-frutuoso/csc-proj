#!/bin/bash

# step 1) Reads the voter’s intentions from the command line;

# get nCandidates
echo "Insert number of candidates: "
read nCandidates
echo $nCandidates

# initialize output files
touch votelist.txt # useful for debug
touch cryptVotes.txt
# get votes for each candidate
for ((i=1;i<=${nCandidates};i++))
do
    echo "Insert your vote for candidate ${i}: "
    read vote
    printf $vote >> vote.txt
    cat vote.txt >> votelist.txt # useful for debug
    # step 2) Encrypts the vote using the election public key and Microsoft seal library;
    ./weights_encryptor vote
    cat encrypted.txt >> cryptVotes.txt
    rm -r vote.txt
    rm -r encrypted.txt
done

# # add day + time
datetime=$(date +'%d%m%Y_%H%M%S')

echo "${datetime}"
echo "$(cat cryptVotes.txt)$datetime" > cryptVotes.txt #optimize this

# 3) Signs the vote using the voter’s private key, using the libcryp library;

# first prepare input file
voter=$(basename "`pwd`")
echo "${voter}"
privateKeyFile="${voter}.pem"
echo "${privateKeyFile}"
signatureFile="signature_${voter}.txt"

# sign
openssl dgst -sha256 -sign $privateKeyFile -out sign.sha256 cryptVotes.txt # binary file
openssl base64 -in sign.sha256 -out $signatureFile                         # base64 format

# 4) Cast the vote and sends it to the ballot box.
#cp cryptVotes.txt ../../BallotBox

# generate public key to send to ballot box
publicKeyFile="${voter}_public.key"
openssl rsa -in $privateKeyFile -pubout -out $publicKeyFile

#cp publicKeyFile ../../BallotBox