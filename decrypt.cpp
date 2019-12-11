// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#include "/home/tiago/SEAL/native/examples/examples.h"

using namespace std;
using namespace seal;

void decrypt(char* input_file, char* output_file, char* secret_key_file);

int main(int argc, char *argv[])
{
    decrypt(argv[1], argv[2], argv[3]);
    return 0;
}

void decrypt(char* input_file, char* output_file, char* secret_key_file)
{
    int value;

    EncryptionParameters parms(scheme_type::BFV);
    size_t poly_modulus_degree = 4096;
    parms.set_poly_modulus_degree(poly_modulus_degree);
    parms.set_coeff_modulus(CoeffModulus::BFVDefault(poly_modulus_degree));

    parms.set_plain_modulus(512);
    auto context = SEALContext::Create(parms);

    SecretKey secret_key;

    ifstream secret_key_file_open;
    secret_key_file_open.open(secret_key_file);
    secret_key.unsafe_load(context, secret_key_file_open);
    secret_key_file_open.close();

    Decryptor decryptor(context, secret_key);

    Ciphertext input;

    ifstream input_file_open;
    input_file_open.open(input_file);
    input.unsafe_load(context, input_file_open);
    input_file_open.close();

    Plaintext plain_result;
    decryptor.decrypt(input, plain_result);

    IntegerEncoder encoder(context);

    value = encoder.decode_int32(plain_result);

    ofstream output_file_open;
    output_file_open.open(output_file);
    output_file_open << value;
    output_file_open.close();

}