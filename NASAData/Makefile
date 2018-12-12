.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

###FFLAGS = -O -I/usr/local/free/include

FC = gfortran
FFLAGS = -g -C -I/usr/local/free/include  -I/sw/include/ -fconvert=big-endian -m64 
LDFLAGS = -L/usr/local/free/lib -L/sw/lib -L/usr/lib/x86_64-linux-gnu

LIBS =  $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
    $(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a  -lnetcdff -lnetcdf

txt2dat:	txt2dat.o Makefile
		$(FC) $(LDFLAGS) -o txt2dat txt2dat.o $(LIBS)

saod2dat:	saod2dat.o Makefile
		$(FC) $(LDFLAGS) -o saod2dat saod2dat.o $(LIBS)

gacp2grads:	gacp2grads.o Makefile
		$(FC) $(LDFLAGS) -o gacp2grads gacp2grads.o $(LIBS)

sbbx2nc:	sbbx2nc.o Makefile
		$(FC) $(LDFLAGS) -o sbbx2nc sbbx2nc.o $(LIBS)
