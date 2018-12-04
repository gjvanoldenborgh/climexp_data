.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

###FFLAGS = -Ktrap=fp -O3  -Mlarge_arrays
FFLAGS = -g -C # -Ktrap=fp -Mlarge_arrays

FC = gfortran

LIBS = 	$(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
        $(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a

tenday2month:	tenday2month.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) -L$(HOME)/lib -L/sw/lib -lnetcdff -lnetcdf -lfgsl -lgsl
