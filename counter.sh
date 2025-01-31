#!/bin/bash

# Define useful variables, read from file parameters.txt
## Number of voters
NVOTERS=0

## Number of trustees
NTRUSTEES=0
THRESHOLD=0

## Number of candidates
NCANDIDATES=0

input="../parameters.txt"
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
        NCANDIDATES)
            NCANDIDATES=$value
            ;;
    esac
done < "$input"

#########################

#Check the validity of the Tally Certificate and Public Key
verify=$(openssl verify -verbose -CAfile my-ca.crt tally.crt)
if [ "${verify}" = "tally.crt: OK" ]; then
    echo "Verified Tally certificate OK"
else
    echo "Verification Tally Certificate Failure"
    exit 1
fi

verify2=$(openssl x509 -noout -modulus -in tally.crt | openssl md5)

verify4=$(openssl rsa -noout -modulus -in tally_public.key | openssl md5)

if [ "${verify2}" != "${verify4}" ]; then
    echo "Verification 2 Tally Certificate Failure"
    exit 1
fi

# Check if number of candidates exceeds NCANDIDATES
otherCand=$((NCANDIDATES+1))
#echo "other ${otherCand}" #debug

# convert to string
if [ "$otherCand" -lt "10" ]; then
    j="00${otherCand}"
else
    if [ "$otherCand" -lt "100" ]; then
        j="0${otherCand}"
    else
        j="$otherCand"
    fi
fi
otherVotes=$(find -name "total_votes_cand${j}.txt")
#echo "$otherVotes" #debug

# If candidate N+1 exists, the election shall be rejected
if [ "$otherVotes" ]
then
    echo "Corrupted election -- too many candidates." #debug
    exit 1
#else
#    echo "Election OK." #debug
fi

# Rebuild the signing key of the election private key
for ((i=1;i<=${NTRUSTEES};i++))
do
    filename="../Trustees/trustee${i}/Share${i}.txt"
    cp $filename .
done

./Join_Shares $NTRUSTEES $THRESHOLD # --> password.txt

# Decrypt election private key
value=$(cat password.txt)
#echo "$value" #debug
sudo openssl enc -d -aes-256-cbc -in election_private_encrypted.key -k $value -pbkdf2 -out election_private.key # -> will print key

# Decrypt total checksum after validation of signature
openssl base64 -d -in sign_checksum_total.txt -out sign.sha256
verify=$(openssl dgst -sha256 -verify tally_public.key -signature sign.sha256 checksum_total.txt)
rm sign.sha256
if [ "${verify}" = "Verified OK" ]; then
    echo "Verified Checksum Signature OK"
else
    echo "Verification Failure - Checksum"
    echo "Corrupted election - checksum validity failed."
    exit 1
fi

./decrypt checksum_total.txt decrypted_checksum_total.txt election_private.key
typeset -i checksum_total=$(cat decrypted_checksum_total.txt)
#echo "checksum_total ${checksum_total}" #debug

# Compute number of candidates times number of voters
candXvoter=$((NCANDIDATES*NVOTERS))

if [ "$checksum_total" -ne "$candXvoter" ]
then
    echo "Corrupted election - checksum validity failed." #debug
    exit 1
fi

# variable to store election winner
winner=0
winnerVotes=0
echo "[Election results]"
# Decrypt candidates' total votes (results)
for ((i=1;i<=${NCANDIDATES};i++))
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

    outputFile="decrypted_total_votes_cand${j}.txt"

    cryptTotalVotes_i=$(find -name "total_votes_cand${j}.txt")
    if [ -z "$cryptTotalVotes_i" ]
    then
        #echo "file ${j} does not exist" #debug
        continue
    fi
    #echo "file ${j} OK." #debug

    # Verify the signature of the total votes for each candidate and decrypt
    sign_cryptTotalVotes_i=$(find -name "sign_total_votes_cand${j}.txt")
    if [ -z "$sign_cryptTotalVotes_i" ]
    then
        #echo "file ${j} does not exist" #debug
        continue
    fi
    openssl base64 -d -in $sign_cryptTotalVotes_i -out sign.sha256
    verify=$(openssl dgst -sha256 -verify tally_public.key -signature sign.sha256 $cryptTotalVotes_i)
    rm sign.sha256
    if [ "${verify}" = "Verified OK" ]; then
        echo "Verified Total Votes for candidate${j} Signature OK"
    else
        echo "Verification Failure - Total Votes for candidate${j}"
        echo "Corrupted election - Total Votes for candidate${j} validity failed."
        exit 1
    fi

    ./decrypt $cryptTotalVotes_i $outputFile election_private.key
    typeset -i votes_candidate_i=$(cat ${outputFile})
    echo "candidate${j} --> ${votes_candidate_i} votes"

    # update winner
    if [ "$votes_candidate_i" -gt "$winnerVotes" ]; then
        winnerVotes=$votes_candidate_i
        winner=$j
    fi
done

echo "WINNER: candidate${winner} (${winnerVotes} votes)"
