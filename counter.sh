#!/bin/bash

# Define useful variables, read from file parameters.txt
## Number of voters
NVOTERS=0

## Number of trustees
NTRUSTEES=0
THRESHOLD=0

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
    esac
done < "$input"

#########################
for ((i=1;i<=${NTRUSTEES};i++))
do
    filename="../Trustees/trustee${i}/Share${i}.txt"
    
    cp $filename .
done

./Join_Shares $NTRUSTEES $THRESHOLD

value=$(<password.txt)
sudo openssl enc -d -aes-256-cbc -in election_private_encrypted.key -k $value -pbkdf2 -out election_private.key
