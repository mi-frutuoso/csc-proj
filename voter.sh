#!/bin/bash

# step 1) Reads the voter’s intentions from the command line;

# get nCandidates
echo "Insert number of candidates: "
read nCandidates

# add read robustness

# initialize output files
voter=$(basename "`pwd`")
touch votelist.txt # useful for debug
# get votes for each candidate
for ((i=1;i<=${nCandidates};i++))
do
    echo "Insert your vote for candidate ${i}: "
    read vote
    printf "${vote}\n" >> vote.txt
    cat vote.txt >> votelist.txt # useful for debug
    rm -r vote.txt
    
    # step 2) Encrypts the vote using the election public key and Microsoft seal library;
    ./weights_encryptor $vote # --> generate encrypted.txt

    # add day + time
    datetime=$(date +'%d%m%Y-%H%M%S')
    candidateVoteFile="crypt_${voter}_cand${i}_${datetime}.txt"
    # rename file
    mv encrypted.txt ${candidateVoteFile}

    # 3) Signs the vote using the voter’s private key, using the libcryp library;
    # first prepare input file
    privateKeyFile="${voter}.pem"
    signatureFile="signature_${voter}_${i}_${datetime}.txt"

    # sign
    openssl dgst -sha256 -sign $privateKeyFile -out sign.sha256 ${candidateVoteFile}    # binary file
    openssl base64 -in sign.sha256 -out $signatureFile                                  # base64 format
    rm sign.sha256
    
    # 4) Cast the vote and sends it to the ballot box.
    mv ${candidateVoteFile} ../../BallotBox
    # send signature
    mv $signatureFile ../../BallotBox

done


# generate public key to send to ballot box
publicKeyFile="${voter}_public.key"
openssl rsa -in $privateKeyFile -pubout -out $publicKeyFile

mv $publicKeyFile ../../BallotBox
