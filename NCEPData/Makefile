.SUFFIXES: .f90 .o

.f90.o:
		$(FC) $(FFLAGS)  -c $<

###FFLAGS = -g -C
FFLAGS = -O

FC = gfortran

LIBS =  $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
	$(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a -lfgsl -lgsl

update:	nino2.dat nino2_daily.dat nino2_5daily.dat
	scp nino*.dat oldenbor@climexp.knmi.nl:climexp/NCEPData/

nino2.dat:	sstoi.indices
		sstoi2dat

nino2_daily.dat:	wksst.for ./ninoweek2daily
		./ninoweek2daily

nino2_5daily.dat:	nino2_daily.dat ./make5daily.sh
		./make5daily.sh

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
