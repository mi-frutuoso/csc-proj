#!/bin/bash

# Define useful variables
## Number of voters
declare -i NVOTERS=10

## Number of trustees
declare -i NTRUSTEES=5
declare -i THRESHOLD=4

#########################
for ((i=1;i<=${NTRUSTEES};i++))
do
    filename="../Trustees/trustee${i}/Share${i}.txt"
    
    cp $filename .
done

./Join_Shares $NTRUSTEES $THRESHOLD

value=$(<password.txt)
sudo openssl enc -d -aes-256-cbc -in election_private_encrypted.key -k $value -pbkdf2 -out election_private.key