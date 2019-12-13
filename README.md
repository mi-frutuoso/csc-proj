# Homomorphic Vote Tally

The goal of this project is to develop an online voting system using public key cryptography and homomorphic encryption. It was developed under the course `Cryptography and Communications Security` (CSC).

This README file explains first how the acting entities work, incluiding their dependent files, and then how to setup and execute this project.

## Authors

This CSC Project was developed by Group 13, composed by the students:

- [83995 - Ana Rodrigues]

- [84303 - Maria Frutuoso]

- [84349 - Tiago Pires]


## Contents

- [Entity Files](#entity-files)
  - [Administrator](#administrator--adminsh)
  - [Voter](#voter--votersh)
  - [Ballot box](#ballot-box)
  - [Tally official](#tally-official--tallysh)
  - [Counter](#counter--countersh)
  - [Trustees](#trustees)
- [Running the app](#running-the-app)
  - [Step 0: Setup election parameters](#step-0--setup-election-parameters)
  - [Step 1: Run Administrator](#step-1--run-administrator)
  - [Step 2: Run Voter(s)](#step-2--run-voters)
  - [Step 3: Run Tally official](#step-3--run-tally-official)
  - [Step 4: Run Counter](#step-4--run-counter)


## Entity files

Here we define the acting entities and their related files.

### Administrator :: `admin.sh`

Corresponds to the very first steps of the setup of the election tally and builds the skeleton of entire voting system. Performs the following main tasks:

  - creation of all the folders needed for all entities (`mkdir`);

  - generation of the certification authority and certificates and keys for voters (`openssl`);

  - generation of election homomorphic key (`./key_generator`);

    - `./key_generator` is a `C++` executable program based on the `Microsoft SEAL` library. It does not take any input arguments. Outputs an homomorphic key pair;

  - distribution of files among entities (`cp` and `mv`);

  - encryption of election private key using a chosen Key, due to the limitation of Shamir's secret sharing (`openssl`);

  - split and distribution of the previous encryption key using SSS (`./Make_Shares`);
    
    - `./Make_Shares` is a `C` executable program based on the `Shamir's secret sharing` library. It takes three input arguments: number of trustees, number of shares needed to restore a secret and the password key. Outputs the set of shares of the password key;

  - assignment (in a random way), encryption and sign of weigths to each voter (`./weights_encryptor`)(`openssl`);
    
    - `./weights_encryptor` is a `C++` executable program based on the `Microsoft SEAL` library. It takes an integer as input argument. Outputs the homomorphic encryption of that integer;
  - generation of key pairs and corresponding certificate for the Tally (`openssl`).

### Voter :: `voter.sh`

Command line application that determines the voting decision by the voter (user), but also performs these steps:

  - verification of validity of the certificate and the keys received from the Admin (`openssl verify` and `openssl -modulus`);

    - verify the voter certificate based on the CA certificate (`my-ca.crt`) and then verify the public and private keys based on the voter certificate;

  - encryption of the votes (`./weights_encryptor`);

  - attach the day and time of the moment the vote was made (`date`);

  - signature of votes using voter private key (`openssl -sign`);

  - cast of votes to ballot (`cp`);

  - distribution of files among entities (`cp` and `mv`).

This application is prepared for non-ideal voter users, as it only accepts integer numbers as input.

### Ballot box

Folder responsible for storing the votes, containing these files:

  - encrypted votes per candidate per voter (`crypt_voterAAA_candBBB_YYYYmmddHHMMSS.txt`);

  - signatures that sign each vote (`signature_voterAAA_BBB_YYYYmmddHHMMSS.txt`);

  - voter's public keys (`voterAAA_public.key`);

  - voter's certificates (`voterAAA.crt`).

### Tally official :: `tally.sh`

Application that is responsible for:

  - verification of the authenticity of the the certificate, keys and weights received by the admin and the certificate and public key of the voters (`openssl verify` and `openssl -modulus`);

  - checking the signature of the votes, removing from the `/BallotBox` those whose signature fails (`openssl`, `find`, `rm`);

  - filtering the votes inside `/BallotBox` such that, for the same voter, remain only the most recent votes (`find`, `rm`); 

  - computing homomorphically the checksum for each vote, adding it to an accumulator, and the result of the election (`./calculator`);

    - `./calculator` is a `C++` executable program based on the `Microsoft SEAL` library. It takes multiple input arguments:
    
      - a flag (specifies the arithmetic operations and the files that will be updated);
      - the name of the file containing the updated votes for a candidate;
      - the name of a temporary file containing the votes for a candidate (acts as an auxiliary file);
      - the name of the file containing a vote;
      - the name of the file containing the encrypted weight of a voter;
      - the name of the file containing the updated checksum of a voter;
      - the name of the file containing the checksum of a voter (acts as an auxiliary file);

    - Updates the input files with the encrypted arithmetic result of an operation.

  - computing homomorphically the checksum accumulator (`./sumcheck`);

    - `./sumcheck` is a `C++` executable program based on the `Microsoft SEAL` library. It takes as input arguments:
      
      - a flag (which specifies if there is already an accumulator file);
      - the name of the file containing the checksum of a voter;
      - the name of the file containing the updated checksum accumulator value;
      - the name of the file containing the previous checksum accumulator value (acts as an auxiliary file);

  - signing the checksum and the election results with tally's private key (`openssl -sign`);

  - sending the election results, the checksum accumulator and the tally private key to the counter.


### Counter :: `counter.sh`

Bash script that performs these operations:

  - validation of the authenticity of the tally's certificate and public key (`openssl verify` and `openssl -modulus`);

  - rebuild of the election private key (`./Join_Shares`);
    - `./Join_Shares` is a `C` executable program based on the `Shamir's secret sharing` library, dual of `./Make_Shares`. It takes two input arguments: number of trustees and number of shares needed to restore a secret. Outputs the restored password key;

  - restore the election private key by decrypting it with the rebuilt key (`openssl`);

  - validation of the checksum accumulator and election results signatures;

  - decryption of the checksum accumulator (`./decrypt`);
    
    -  `./decrypt` is a `C++` executable program based on the `Microsoft SEAL` library. It takes as input arguments the name of an encrypted input file, the name of the decrypted output file and the election private key restored previously;

  - decryption and announcement of the election results (`./decrypt`).

### Trustees

Set of folders that store encrypted shares of the password that encrypts the election private key. 

# Running the app

Here we explain how to setup the application and expose the commands needed to execute. This implementation is prepared to run all the election steps automatically.

## Step 0 :: Setup election parameters

Before we start, we should decide the number of:

- candidates;

- trustees;

- voters;

- shares needed to restore a key;

- interval of vote weight;

To do so, edit the file `parameters.txt` at parent directory and leave it there. It should look like this example:

````
NCANDIDATES=5
NVOTERS=10
NTRUSTEES=5
THRESHOLD=4
WEIGHTMAX=5
WEIGHTMIN=1
RANDMAX=32767
PASSWORD=password
````

Then we should gather all the source files and move them to a directory where the voting system will be built.

## Step 1 :: Run Administrator

After choosing the folder to place the files, the administrator may be called by:

````
$ sudo bash admin.sh
````

After this, we should have the directory organized in the following way (assuming there are `M` shares and `N` voters):

````
.
├── Admin
│   ├── cryptWeight_voter001.txt
│   ├── ...
│   ├── cryptWeight_voterN.txt
│   ├── election_public.key
│   ├── key_generator                       # executable
│   ├── Make_Shares                         # executable
│   ├── my-ca.crt
│   ├── my-ca.key
│   ├── my-ca.srl
│   ├── tally.crt
│   ├── tally.csr
│   ├── weightlist.txt
│   └── weights_encryptor                   # executable
├── BallotBox
├── Counter
│   ├── counter.sh                          # bash
│   ├── decrypt                             # executable
│   ├── election_private_encrypted.key
│   ├── Join_Shares                         # executable
│   ├── my-ca.crt
│   └── tally.crt
├── Tally
│   ├── calculator                          # executable
│   ├── cryptWeight_voter001.txt
│   ├── ...
│   ├── cryptWeight_voterN.txt
│   ├── my-ca.crt
│   ├── sign_cryptWeight_voter001.txt
│   ├── ...
│   ├── sign_cryptWeight_voterN.txt
│   ├── sumcheck                            # executable
│   ├── tally.crt
│   ├── tally_private.key
│   ├── tally_public.key
│   ├── tally.sh                            # bash
│   └── weight_public.key
├── Trustees
│   ├── trustee1
│   │   └── Share1.txt
│   ├── ...
│   └── trusteeM
│       └── ShareM.txt
└── Voters
    ├── voter001
    │   ├── election_public.key
    │   ├── my-ca.crt
    │   ├── voter001.crt
    │   ├── voter001.csr
    │   ├── voter001.pem
    │   ├── voter001_public.key
    │   ├── voter.sh                        # bash
    │   └── weights_encryptor               # executable
    ├── ... 
    └── voterN
        ├── election_public.key
        ├── my-ca.crt
        ├── voterN.crt
        ├── voterN.csr
        ├── voterN.pem
        ├── voterN_public.key
        ├── voter.sh                        # bash
        └── weights_encryptor               # executable
 ````

You may also notice that inside the `/Admin` folder, there's also a file called `weightlist.txt` containing the list of the generated weights for each voter, only for debug purposes.

## Step 2 :: Run Voter(s)

The voter app is distributed through all folders of voters and each execution of this bash corresponds to a single voter. Running the command below will prompt the user the number of candidates -- let's say `P` -- and the distribution of votes among them, successively from `candidate 1` to `candidate P`.

Should be executed inside each folder `voterX`, where `1<X<N`:

````
$ sudo bash voter.sh
````

After this, `/BallotBox` will have encrypted votes, signatures and public keys of the voters.

Also inside each folder of voters will be the file `votelist.txt` containing the votes from that voter for debug purposes.

## Step 3 :: Run Tally official

Once all votes are done, the tally official may process the votes inside the `/BallotBox` by executing:

````
$ sudo bash tally.sh
````

After this, the number of files inside `/BallotBox` will decrease, as there will only be a single vote file for each candidate per voter.

Also, new files will be created at `/BallotBox` containing the voters' checksum and election results.

## Step 4 :: Run Counter

Finally, to validate the election and possibly reveal the results, we may execute:

````
$ sudo bash counter.sh
````
