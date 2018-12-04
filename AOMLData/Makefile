.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

###FFLAGS = -Ktrap=fp -O3  -Mlarge_arrays
FFLAGS = -g -C # -Ktrap=fp -Mlarge_arrays

FC = gfortran

cable2dat:	cable2dat.o
	$(FC) $(FFLAGS) -o $@ $@.o 
