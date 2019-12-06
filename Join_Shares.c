
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
	uint8_t secret[MAXCHAR], restored[MAXCHAR];
	sss_Share new_shares[NTRUSTEES];
	int tmp;
	FILE *fp2;
	char nome[20];

	for (int i = 1; i < NTRUSTEES+1; i++)
	{
		sprintf(nome, "Share%d.txt",i);
		fp2 = fopen(nome, "rw");
		fread(new_shares[i-1],sizeof(new_shares[i-1]),1,fp2);
		fclose(fp2);
	}

	// Combine some of the shares to restore the original secret
	tmp = sss_combine_shares(restored, new_shares, THRESHOLD);
	assert(tmp == 0);
	/*assert(memcmp(restored, secret, sss_MLEN) == 0);*/

	printf("%s\n", restored);

	int filedesc2 = open("password.txt", O_WRONLY | O_CREAT);
	write(filedesc2,restored,strlen(restored));
}