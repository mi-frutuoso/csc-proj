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

# Check if NCandidates is <= NCANDIDATES

otherCand=NCANDIDATES+1

echo "other ${otherCand}"

otherVotes=$(find -name "total_votes_cand${otherCand}.txt")
echo "$otherVotes" #debug
if [ "$otherVotes" ]
then
    echo "Corrupted election." #debug
    exit 1
else
    echo "Election OK." #debug
fi

# Rebuild election private key
for ((i=1;i<=${NTRUSTEES};i++))
do
    filename="../Trustees/trustee${i}/Share${i}.txt"
    
    cp $filename .
done

./Join_Shares $NTRUSTEES $THRESHOLD

value=$(<password.txt)
sudo openssl enc -d -aes-256-cbc -in election_private_encrypted.key -k $value -pbkdf2 -out election_private.key


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
        echo "file ${j} does not exist"
    else
        echo "file ${j} OK." #debug
        ./decrypt $cryptTotalVotes_i $outputFile election_private.key
    fi
done
