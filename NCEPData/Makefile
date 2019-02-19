.SUFFIXES: .f90 .o

.f90.o:
		$(FC) $(FFLAGS)  -c $<

###FFLAGS = -g -C
FFLAGS = -O 
SYSLIBS=-L$(HOME)/lib -L$(HOME)/lib/$(PVM_ARCH) -L/usr/lib/x86_64-linux-gnu/ -L/usr/lib64/atlas

FC = gfortran

LIBS =  $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
	$(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a $(SYSLIBS)

all: makesoi tele2dat cmap2dat ninoweek2daily mjo2dat

makesoi:	makesoi.o
		$(FC) $(FFLAGS) -o $@ $@.o

spaghetti:	spaghetti.o Makefile
		$(FC) $(FFLAGS) -o $@ spaghetti.o $(LIBS)

tele2dat:	tele2dat.o Makefile
		$(FC) $(FFLAGS) -o $@ tele2dat.o $(LIBS)

cmap2dat:	cmap2dat.o Makefile
		$(FC) $(FFLAGS) -o $@ cmap2dat.o $(LIBS)

ninoweek2daily:	ninoweek2daily.o
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

oiv2week2grads:	oiv2week2grads.o
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

temp2nino:	temp2nino.o
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

mjo2dat:	mjo2dat.o
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

oiv22grads:	oiv22grads.o
		$(FC) $(FFLAGS) -o $@ $@.o
