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

# Generate a pair of public and private keys to sign documents
openssl genrsa -des3 -passout pass:tally -out tally_private.key 2048
openssl rsa -in tally_private.key -passin pass:tally -pubout -out tally_public.key
mv tally_public.key ../Counter

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

    # variable to store date of latest vote from voter i (to exclude the older ones)
    lastVoteDate=0

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

        # update latest vote date
        if [ "$signDate" -gt "$lastVoteDate" ]; then
            lastVoteDate=$signDate
        fi

        filename="crypt_voter${j}_cand${candidate}_${signDate}.txt"
        
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
            if [ "$signDate" -ne "$lastVoteDate" ]; then
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

    total_votes="total_votes_cand${j}.txt"
    total_votes_temp="total_votes_cand${j}_temp.txt"

    no_voter_flag=0

    for ((k=1;k<=${NVOTERS};k++))
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

        checksum_voter="checksum_voter${m}.txt"
        checksum_voter_temp="checksum_voter${m}_temp.txt"

        vote=$(find -name "crypt_voter${m}_cand${j}*")
        if [ -z "$vote" ]
        then
            echo "No vote from voter${m} to candidate${j}." #debug
            no_voter_flag=1
            continue
        else
            echo "voter${m} has vote for candidate${j}." #debug
        fi

        voteName=$(echo "${vote}" | cut -d "/" -f2)
        weight_file="../Tally/cryptWeight_voter${m}.txt"
        weightFile_sign="../Tally/sign_cryptWeight_voter${m}.txt"
        weightPublicKeyFile="../Tally/weight_public.key"

        # Verify the signatures of the weights to see if they come from the admin
        openssl base64 -d -in ${weightFile_sign} -out sign.sha256
        verify=$(openssl dgst -sha256 -verify ${weightPublicKeyFile} -signature sign.sha256 ${weight_file})
        rm sign.sha256
        if [ "${verify}" = "Verified OK" ]; then
            echo "Verified ${weight_file} OK"
        else
            echo "Verification Failure - ${weight_file}"
            rm ${weight_file}
            continue
        fi

        if [ "$k" -eq "1" ]
        then
            if [ "$i" -eq "1" ]
            then
                ../Tally/calculator "0" $total_votes $total_votes_temp $voteName $weight_file $checksum_voter $checksum_voter_temp
            else
                cp $checksum_voter $checksum_voter_temp
                rm -r $checksum_voter
                ../Tally/calculator "2" $total_votes $total_votes_temp $voteName $weight_file $checksum_voter $checksum_voter_temp
                rm -r $checksum_voter_temp
            fi
        else
            if [ "$no_voter_flag" -eq "0" ]
            then
                cp $total_votes $total_votes_temp
                rm -r $total_votes
            fi
            if [ "$i" -eq "1" ]
            then
                if [ "$no_voter_flag" -eq "0" ]
                then
                    ../Tally/calculator "1" $total_votes $total_votes_temp $voteName $weight_file $checksum_voter $checksum_voter_temp
                else
                    ../Tally/calculator "0" $total_votes $total_votes_temp $voteName $weight_file $checksum_voter $checksum_voter_temp
                fi
            else
                cp $checksum_voter $checksum_voter_temp
                rm -r $checksum_voter
                if [ "$no_voter_flag" -eq "0" ]
                then
                    ../Tally/calculator "3" $total_votes $total_votes_temp $voteName $weight_file $checksum_voter $checksum_voter_temp
                else
                    ../Tally/calculator "2" $total_votes $total_votes_temp $voteName $weight_file $checksum_voter $checksum_voter_temp
                fi
                rm -r $checksum_voter_temp
            fi
            if [ "$no_voter_flag" -eq "0" ]
            then
                rm -r $total_votes_temp
            else
                no_voter_flag=0
            fi
        fi
    done

    # signs the total votes for a candidate EXTRA FEATURE
    total_votes_sign="sign_total_votes_cand${j}.txt"
    openssl dgst -sha256 -sign ../Tally/tally_private.key -passin pass:tally -out sign.sha256 $total_votes    # binary file
    openssl base64 -in sign.sha256 -out $total_votes_sign                                  # base64 format
    rm sign.sha256
    mv $total_votes ../Counter #Move the results of each candidate to the voter
    mv $total_votes_sign ../Counter

done

no_checksum_flag=1
for ((k=1;k<=${NVOTERS};k++))
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

    checksum_voter="checksum_voter${m}.txt"
    checksum_total="checksum_total.txt"
    checksum_total_temp="checksum_total_temp.txt"

    checksum_exist=$(find -name "checksum_voter${m}.txt")
    if [ -z "$checksum_exist" ]
    then
        echo "No votes from voter${m}." #debug
        continue
    else
        echo "voter${m} has voted." #debug
        if [ "$no_checksum_flag" -eq "1" ]
        then
            no_checksum_flag=0
            ../Tally/sumcheck "0" $checksum_voter $checksum_total $checksum_total_temp
        else
            cp $checksum_total $checksum_total_temp
            rm -r $checksum_total
            ../Tally/sumcheck "1" $checksum_voter $checksum_total $checksum_total_temp
            rm -r $checksum_total_temp
        fi
    fi

done

# 5) Sends the election results and the checksum accumulator to the counter
# signs the checksum EXTRA FEATURE
sign_checksum_total="sign_checksum_total.txt"
openssl dgst -sha256 -sign ../Tally/tally_private.key -passin pass:tally -out sign.sha256 $checksum_total    # binary file
openssl base64 -in sign.sha256 -out $sign_checksum_total                                  # base64 format
rm sign.sha256
mv $checksum_total ../Counter
mv $sign_checksum_total ../Counter