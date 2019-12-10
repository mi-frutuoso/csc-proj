// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#include "/home/tiago/SEAL/native/examples/examples.h"

using namespace std;
using namespace seal;

void calculator(int flag, char* total_votes, char* total_votes_temp, char* voteName, char* weight_file, char* checksum_voter, char* checksum_voter_temp);

int main(int argc, char *argv[])
{
    int flag = atoi(argv[1]);
    calculator(flag, argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
    return 0;
}

void calculator(int flag, char* total_votes, char* total_votes_temp, char* voteName, char* weightFile, char* checksum_voter, char* checksum_voter_temp)
{
    EncryptionParameters parms(scheme_type::BFV);
    size_t poly_modulus_degree = 4096;
    parms.set_poly_modulus_degree(poly_modulus_degree);
    parms.set_coeff_modulus(CoeffModulus::BFVDefault(poly_modulus_degree));

    parms.set_plain_modulus(512);
    auto context = SEALContext::Create(parms);

    Evaluator evaluator(context);

    if (flag == 0) {
        
        Ciphertext vote, weight, result;

        ifstream vote_file, weight_file;
        vote_file.open(voteName);
        vote.unsafe_load(context, vote_file);
        vote_file.close();
        weight_file.open(weightFile);
        weight.unsafe_load(context, weight_file);
        weight_file.close();

        ofstream checksum_voter_file;
        checksum_voter_file.open(checksum_voter);
        vote.save(checksum_voter_file);
        checksum_voter_file.close();

        evaluator.multiply(vote, weight, result);

        ofstream total_votes_file;
        total_votes_file.open(total_votes);
        result.save(total_votes_file);
        total_votes_file.close();

    } else if (flag == 1) {
    
        Ciphertext vote, weight, total_votes_sum, result;

        ifstream vote_file, weight_file, total_votes_temp_file;
        vote_file.open(voteName);
        vote.unsafe_load(context, vote_file);
        vote_file.close();
        weight_file.open(weightFile);
        weight.unsafe_load(context, weight_file);
        weight_file.close();
        total_votes_temp_file.open(total_votes_temp);
        total_votes_sum.unsafe_load(context, total_votes_temp_file);
        total_votes_temp_file.close();

        ofstream checksum_voter_file;
        checksum_voter_file.open(checksum_voter);
        vote.save(checksum_voter_file);
        checksum_voter_file.close();

        evaluator.multiply(vote, weight, result);
        evaluator.add_inplace(result, total_votes_sum);

        ofstream total_votes_file;
        total_votes_file.open(total_votes);
        result.save(total_votes_file);
        total_votes_file.close();

    } else if (flag == 2) {
    
        Ciphertext vote, weight, checksum, result;

        ifstream vote_file, weight_file, checksum_voter_temp_file;
        vote_file.open(voteName);
        vote.unsafe_load(context, vote_file);
        vote_file.close();
        weight_file.open(weightFile);
        weight.unsafe_load(context, weight_file);
        weight_file.close();
        checksum_voter_temp_file.open(checksum_voter_temp);
        checksum.unsafe_load(context, checksum_voter_temp_file);
        checksum_voter_temp_file.close();

        evaluator.multiply(vote, weight, result);

        ofstream total_votes_file;
        total_votes_file.open(total_votes);
        result.save(total_votes_file);
        total_votes_file.close();

        evaluator.add_inplace(checksum, vote);

        ofstream checksum_voter_file;
        checksum_voter_file.open(checksum_voter);
        checksum.save(checksum_voter_file);
        checksum_voter_file.close();

    } else if (flag == 3) {

        Ciphertext vote, weight, checksum, total_votes_sum, result;

        ifstream vote_file, weight_file, checksum_voter_temp_file, total_votes_temp_file;
        vote_file.open(voteName);
        vote.unsafe_load(context, vote_file);
        vote_file.close();
        weight_file.open(weightFile);
        weight.unsafe_load(context, weight_file);
        weight_file.close();
        checksum_voter_temp_file.open(checksum_voter_temp);
        checksum.unsafe_load(context, checksum_voter_temp_file);
        checksum_voter_temp_file.close();
        total_votes_temp_file.open(total_votes_temp);
        total_votes_sum.unsafe_load(context, total_votes_temp_file);
        total_votes_temp_file.close();

        evaluator.multiply(vote, weight, result);
        evaluator.add_inplace(result, total_votes_sum);

        ofstream total_votes_file;
        total_votes_file.open(total_votes);
        result.save(total_votes_file);
        total_votes_file.close();

        evaluator.add_inplace(checksum, vote);

        ofstream checksum_voter_file;
        checksum_voter_file.open(checksum_voter);
        checksum.save(checksum_voter_file);
        checksum_voter_file.close();

    }

}