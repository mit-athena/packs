/*
 * $Header: /afs/dev.mit.edu/source/repository/packs/update/upvers.c,v 1.5 1988-08-31 21:40:56 probe Exp $
 * $Source: /afs/dev.mit.edu/source/repository/packs/update/upvers.c,v $
 * $Author: probe $
 */
 
#include	<sys/types.h>
#include	<sys/dir.h>
#include	<ctype.h>

struct	verfile {
	int	mjr;	/* Major Version Number */
	int	mnr; 	/* Minor Version Number */
	int	deg;	/* Version Designation Char */
} vf[20];

#ifndef lint
char	rcsid[] = "$Header: /afs/dev.mit.edu/source/repository/packs/update/upvers.c,v 1.5 1988-08-31 21:40:56 probe Exp $";
#endif

main(argc, argv)
int	argc;
char	*argv[];
{

	DIR	*dp;
	int	n = 0, i;
	int	oldmjr, oldmnr, newmjr, newmnr;
	int	olddeg, newdeg, start, end, vcmp();
	char	file[80];
	extern	int	errno;
	struct	direct	*dirp;

	if (argc < 4) 
		puts("Usage: verup <old-vers> <new-vers> <libdir>"), exit(2);

	if (chdir(argv[3]) == -1) 
		perror(argv[3]), exit(1);
 	oldmjr = atoi(index(argv[1], '.') - 1);
	oldmnr = atoi(rindex(argv[1], '.') + 1);
	if (isalpha(argv[1][strlen(argv[1]) - 1]))
		olddeg = argv[1][strlen(argv[1]) - 1];
		
	newmjr = atoi(index(argv[2], '.') - 1);
	newmnr = atoi(rindex(argv[2], '.') + 1);
	if (isalpha(argv[2][strlen(argv[2]) - 1]))
		newdeg = argv[2][strlen(argv[2]) - 1];
		
	if ((dp = opendir(".")) == NULL)
		puts("Cannot open ."), exit(2);
		
	while (dirp = readdir(dp)) {
		if(isdigit(dirp->d_name[0])) {
			vf[n].mjr = atoi(index(dirp->d_name, '.') - 1);
			vf[n].mnr = atoi(rindex(dirp->d_name, '.') + 1);
			if (isalpha(dirp->d_name[strlen(dirp->d_name) - 1]))
				vf[n].deg = dirp->d_name[strlen(dirp->d_name) - 1];
			n++;
		}
	}
	qsort(vf, n, sizeof(struct verfile), vcmp);
	start = end = n-1;
	for (i = 0; i < n; i++) {
	    if (vf[i].mjr > oldmjr ||
		(vf[i].mjr == oldmjr && vf[i].mnr > oldmnr) ||
		(vf[i].mjr == oldmjr && vf[i].mnr == oldmnr && vf[i].deg >= olddeg))
		if (start == n-1) start = i;
	    if (vf[i].mjr > newmjr ||
		(vf[i].mjr == newmjr && vf[i].mnr > newmnr) ||
		(vf[i].mjr == newmjr && vf[i].mnr == newmnr && vf[i].deg > newdeg))
		if (end == n-1) end = i-1;
	}
	if (n == 0 || end < 0) {
	    printf("No files need to be run.\n");
	    exit(0);
	}
	if (start > end ) {
	    printf("Fatal error: starting version > ending version\n");
	    exit(1);
	}

	for(i = start; i <= end; i++) {
		sprintf(file, "%s/%d.%d%c", argv[3], vf[i].mjr, vf[i].mnr, vf[i].deg);
		printf("Running %s\n", file);
		system(file); 
	}
}
		
vcmp(v1, v2)
struct	verfile	*v1, *v2;
{
	if (v1->mjr == v2->mjr) {
		if (v1->mnr == v2->mnr) {
			if (v1->deg == v2->deg) {
				return 0;
			} else if (v1->deg > v2->deg) {
				return 1;
			} else return -1;
		} else if(v1->mnr > v2->mnr) {
			return 1;
		} else return -1;
	}
	else if(v1->mjr > v2->mjr)
		return 1;
	else return -1;
}
			
				
		
