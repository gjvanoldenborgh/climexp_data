.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)	 -c $<

FC = gfortran

msu2grads:	msu2grads.o
	$(FC) $(FFLAGS) -o $@ $@.o