.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)	 -c $<

FC=gfortran

FFLAGS = -g -fbounds-check

pdsi2dat:	pdsi2dat.o
		$(FC) $(FFLAGS) -o pdsi2dat pdsi2dat.o

ascii2dat: ascii2dat.o
	$(FC) $(FFLAGS) -o  $@ $@.o