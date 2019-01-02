.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)	 -c $<

FC = gfortran

FFLAGS = -g -C

txt2dat: txt2dat.f90
	$(FC) $(FFLAGS) -o txt2dat txt2dat.f90