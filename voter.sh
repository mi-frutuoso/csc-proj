#!/bin/bash

# step 0) Verify the validity of the voter certificate
voter=$(basename "`pwd`")

verify=$(openssl verify -verbose -CAfile my-ca.crt "${voter}.crt")
if [ "${verify}" = "${voter}.crt: OK" ]; then
    echo "Verified ${voter} certificate OK"
else
    echo "Verification ${voter} certificate Failure"
    exit 1
fi

# step 1) Reads the voter’s intentions from the command line;

# get nCandidates
echo "Insert number of candidates: "
read nCandidates

# add read robustness

# initialize output files
touch votelist.txt # useful for debug
# get votes for each candidate
for ((i=1;i<=${nCandidates};i++))
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
    echo "Insert your vote for candidate ${j}: "
    read vote
    printf "${vote}\n" >> vote.txt
    cat vote.txt >> votelist.txt # useful for debug
    rm -r vote.txt
    
    # step 2) Encrypts the vote using the election public key and Microsoft seal library;
    ./weights_encryptor $vote # --> generate encrypted.txt

    # add day + time
    datetime=$(date +'%Y%m%d%H%M%S')
    candidateVoteFile="crypt_${voter}_cand${j}_${datetime}.txt"
    # rename file
    mv encrypted.txt $candidateVoteFile

    # 3) Signs the vote using the voter’s private key, using the libcryp library;
    # first prepare input file
    privateKeyFile="${voter}.pem"
    signatureFile="signature_${voter}_${j}_${datetime}.txt"

    # sign
    openssl dgst -sha256 -sign $privateKeyFile -out sign.sha256 $candidateVoteFile    # binary file
    openssl base64 -in sign.sha256 -out $signatureFile                                  # base64 format
    rm sign.sha256
    
    # 4) Cast the vote and sends it to the ballot box.
    mv $candidateVoteFile ../../BallotBox
    # send signature
    mv $signatureFile ../../BallotBox

    echo "generated ${candidateVoteFile}"
    echo "generated ${signatureFile}"

done

# generate public key to send to ballot box
publicKeyFile="${voter}_public.key"
openssl rsa -in $privateKeyFile -pubout -out $publicKeyFile

mv $publicKeyFile ../../BallotBox
