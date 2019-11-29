// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#include "/home/tiago/SEAL/native/examples/examples.h"

using namespace std;
using namespace seal;

void weights_encryptor(int value1);

int main(int argc, char const *argv[])
{
    int num1 = atoi(argv[1]);
    weights_encryptor(num1);
    return 0;
}

void weights_encryptor(int value1)
{
    EncryptionParameters parms(scheme_type::BFV);
    size_t poly_modulus_degree = 4096;
    parms.set_poly_modulus_degree(poly_modulus_degree);
    parms.set_coeff_modulus(CoeffModulus::BFVDefault(poly_modulus_degree));

    parms.set_plain_modulus(512);
    auto context = SEALContext::Create(parms);

    PublicKey public_key;

    ifstream myfile;
    myfile.open("election_public.key");
    public_key.unsafe_load(context, myfile);
    myfile.close();
    
    Encryptor encryptor(context, public_key);

    /*
    We create an IntegerEncoder.
    */
    IntegerEncoder encoder(context);

    /*
    First, we encode two integers as plaintext polynomials. Note that encoding
    is not encryption: at this point nothing is encrypted.
    */
    Plaintext plain1 = encoder.encode(value1);

    /*
    Now we can encrypt the plaintext polynomials.
    */
    Ciphertext encrypted1;
    encryptor.encrypt(plain1, encrypted1);

    ofstream myfile1;
    myfile1.open("encrypted.txt");
    encrypted1.save(myfile1);
    myfile1.close();
}