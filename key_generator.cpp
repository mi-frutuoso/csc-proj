#include "/home/tiago/SEAL/native/examples/examples.h"

using namespace std;
using namespace seal;

void key_generator();

int main(int argc, char const *argv[])
{
    key_generator();
    return 0;
}

void key_generator()
{
    EncryptionParameters parms(scheme_type::BFV);
    size_t poly_modulus_degree = 4096;
    parms.set_poly_modulus_degree(poly_modulus_degree);
    parms.set_coeff_modulus(CoeffModulus::BFVDefault(poly_modulus_degree));

    parms.set_plain_modulus(512);
    auto context = SEALContext::Create(parms);

    KeyGenerator keygen(context);
    PublicKey public_key = keygen.public_key();
    SecretKey secret_key = keygen.secret_key();

    ofstream myfile1;
    myfile1.open("election_private.key");
    secret_key.save(myfile1);
    myfile1.close();

    ofstream myfile2;
    myfile2.open("election_public.key");
    public_key.save(myfile2);
    myfile2.close();
}