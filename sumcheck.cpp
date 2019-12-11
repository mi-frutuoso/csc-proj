// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#include "/home/tiago/SEAL/native/examples/examples.h"

using namespace std;
using namespace seal;

void sumcheck(int flag, char* checksum_voter, char* checksum_total, char* checksum_total_temp);

int main(int argc, char *argv[])
{
    int flag = atoi(argv[1]);
    sumcheck(flag, argv[2], argv[3], argv[4]);
    return 0;
}

void sumcheck(int flag, char* checksum_voter, char* checksum_total, char* checksum_total_temp)
{
    EncryptionParameters parms(scheme_type::BFV);
    size_t poly_modulus_degree = 4096;
    parms.set_poly_modulus_degree(poly_modulus_degree);
    parms.set_coeff_modulus(CoeffModulus::BFVDefault(poly_modulus_degree));

    parms.set_plain_modulus(512);
    auto context = SEALContext::Create(parms);

    Evaluator evaluator(context);

    if (flag == 0) {
        
        Ciphertext checksum_single_voter;

        ifstream checksum_voter_file;
        checksum_voter_file.open(checksum_voter);
        checksum_single_voter.unsafe_load(context, checksum_voter_file);
        checksum_voter_file.close();

        ofstream checksum_total_file;
        checksum_total_file.open(checksum_total);
        checksum_single_voter.save(checksum_total_file);
        checksum_total_file.close();

    } else if (flag == 1) {
    
        Ciphertext checksum_single_voter, checksum_total_votes;

        ifstream checksum_voter_file, checksum_total_temp_file;
        checksum_voter_file.open(checksum_voter);
        checksum_single_voter.unsafe_load(context, checksum_voter_file);
        checksum_voter_file.close();
        checksum_total_temp_file.open(checksum_total_temp);
        checksum_total_votes.unsafe_load(context, checksum_total_temp_file);
        checksum_total_temp_file.close();

        evaluator.add_inplace(checksum_total_votes, checksum_single_voter);

        ofstream checksum_total_file;
        checksum_total_file.open(checksum_total);
        checksum_total_votes.save(checksum_total_file);
        checksum_total_file.close();

    }

}