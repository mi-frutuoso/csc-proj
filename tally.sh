#!/bin/bash

# Define useful variables
## Number of voters
NVOTERS=0

input="../parameters.txt"
while IFS= read -r line
do
    parameter=$(echo "${line}" | cut -d "=" -f1)
    if [ "${parameter}" = "NVOTERS" ]; then
        value=$(echo "${line}" | cut -d "=" -f2)
        NVOTERS=$value
    fi
done < "$input"


# access ballot box
cd ../BallotBox

## Number of candidates (as perceived from the voters -- which can be wrong)
nCandidates=0

# 1) Check the signature of the vote, if signature fails remove the vote from the tally;
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

    listVoter_j=$(find -name "signature_voter${j}*")
    #echo "$listVoter_j" #debug
    if [ -z "$listVoter_j" ]
    then
        echo "voter${j} has not voted yet." #debug
        continue
    else
        echo "voter${j} has voted." #debug
    fi
    voterPublicKey="voter${j}_public.key"
    for itemList in $listVoter_j
    do
        # find a signature
        signatureName=$(echo "${itemList}" | cut -d "/" -f2)
        #echo "${signatureName}"
        # find the correspondent file to verify signature
        candidate=$(echo "${signatureName}" | cut -d "_" -f3)
        #echo "candidate: ${candidate}"
        signDate_lixo=$(echo "${signatureName}" | cut -d "_" -f4)
        #echo "data ${signDate_lixo}"
        signDate=$(echo "${signDate_lixo}" | cut -d "." -f1)
        #echo "data: ${signDate}"

        filename="crypt_voter${j}_cand${candidate}_${signDate}.txt"
        
        #echo "vou verificar ${filename}"
        # verify signature
        openssl base64 -d -in ${signatureName} -out sign.sha256
        verify=$(openssl dgst -sha256 -verify ${voterPublicKey} -signature sign.sha256 ${filename})
        rm sign.sha256
        if [ "${verify}" = "Verified OK" ]; then
            echo "Verified ${filename} OK"
        else
            echo "Verification Failure - ${filename}"
            rm ${filename}
        fi

        # update perceived number of candidates
        if [ "$candidate" -gt "$nCandidates" ]; then
            nCandidates=$candidate
        fi
    done

    # 2) Check if there is another vote in the tally from the same voter with a date 
    #    previous to the current, if so discards the vote otherwise replaces the vote in the tally
    for ((k=1;k<=${nCandidates};k++))
    do
        if [ "$k" -lt "10" ]; then
            m="00${k}"
        else
            if [ "$k" -lt "100" ]; then
                m="0${k}"
            else
                m=k
            fi
        fi
        # index translation: i->j and j->m
        validVote=0
        listVotesCand_i=$(find -name "crypt_voter${j}_cand${m}*")
        if [ -z "$listVotesCand_i" ]
        then
            echo "No votes from voter${j} to candidate${m}." #debug
            continue
        else
            echo "voter${j} has votes for candidate${m}." #debug
        fi
        #echo "${listVotesCand_i}" #debug
        for vote in $listVotesCand_i
        do
            # find the most recent vote for each candidate
            voteName=$(echo "${vote}" | cut -d "/" -f2)
            #echo "${voteName}" #debug
            candidate=$(echo "${vote}" | cut -d "_" -f3)
            #echo "candidate: ${candidate}" #debug
            signDate_lixo=$(echo "${voteName}" | cut -d "_" -f4)
            #echo "data ${signDate_lixo}" #debug
            signDate=$(echo "${signDate_lixo}" | cut -d "." -f1)
            #echo "data: ${signDate}" #debug
            if [ "$signDate" -gt "$validVote" ]; then
                # remove the oldest vote
                if [ "$validVote" -ne "0" ]; then
                    echo "Removed voter${j}'s vote for candidate{j} on ${validVote}" #debug
                    rm "crypt_voter${j}_cand${m}_${validVote}.txt" 
                    rm "signature_voter${j}_${m}_${validVote}.txt" 
                fi
                validVote=$signDate
                #echo "new max ${validVote}" #debug
            else
                # remove this vote
                echo "Removed voter${j}'s vote for candidate${m} on ${signDate}." #debug
                rm ${voteName}
                rm "signature_voter${j}_${m}_${signDate}.txt"
            fi
        done
    done
done

# 3) Computes homomorphically the checksum for each vote and adds it to an accumulator
# 4) Compute homomorphically the result of the election
# 5) Sends the election results and the checksum accumulator to the counter
