#include "sss.h"
#include "randombytes.h"
#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>

#define MAXCHAR 70000

int main()
{
	uint8_t secret[MAXCHAR], restored[MAXCHAR];
	char testebuffer[MAXCHAR];
	sss_Share shares[5], new_shares[5];
	size_t idx;
	int tmp;
	FILE *fp2;
	char nome[20];

	int filedesc = open("/home/tiago/Desktop/csc-proj/Admin/election_private.key", O_RDONLY);
	read(filedesc,secret,MAXCHAR);

	// Split the secret into 5 shares (with a recombination theshold of 4)
	sss_create_shares(shares, secret, 5, 4);

	for (int i = 1; i < 6; i++)
	{
		sprintf(nome, "Share%d.txt",i);
		fp2 = fopen(nome, "wb");
		fwrite(shares[i-1],sizeof(shares[i-1]),1,fp2);
		fclose(fp2);
	}

	for (int i = 1; i < 6; i++)
	{
		sprintf(nome, "Share%d.txt",i);
		fp2 = fopen(nome, "rw");
		fread(new_shares[i-1],sizeof(new_shares[i-1]),1,fp2);
		fclose(fp2);
	}

	// Combine some of the shares to restore the original secret
	tmp = sss_combine_shares(restored, new_shares, 4);
	assert(tmp == 0);
	assert(memcmp(restored, secret, sss_MLEN) == 0);

	int filedesc2 = open("/home/tiago/Desktop/csc-proj/Admin/election_private.key", O_WRONLY | O_TRUNC);
	write(filedesc2,secret,MAXCHAR);
}