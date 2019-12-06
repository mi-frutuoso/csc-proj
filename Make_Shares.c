#include "sss.h"
#include "randombytes.h"
#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>

#define MAXCHAR 70000

int main(int argc, char const *argv[])
{
	int NTRUSTEES = atoi(argv[1]);
	int THRESHOLD = atoi(argv[2]);
	uint8_t secret[MAXCHAR];
	sss_Share shares[NTRUSTEES];
	FILE *fp2;
	char nome[20];

	strcpy(secret, argv[3]);

	// Split the secret into 5 shares (with a recombination theshold of 4)
	sss_create_shares(shares, secret, NTRUSTEES, THRESHOLD);

	for (int i = 1; i < NTRUSTEES+1; i++)
	{
		sprintf(nome, "Share%d.txt",i);
		fp2 = fopen(nome, "wb");
		fwrite(shares[i-1],sizeof(shares[i-1]),1,fp2);
		fclose(fp2);
	}
}