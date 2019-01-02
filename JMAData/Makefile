FFLAGS = -O # -m64
###FFLAGS = -g -C # -m64

###FC = g95
FC = gfortran

LIBS = 	$(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
	$(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a

SYSLIBS = -L$(HOME)/lib -L/sw/lib -lnetcdf -lnetcdff

dat2grads:	dat2grads.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)
