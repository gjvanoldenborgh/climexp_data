all: getprcp gettemp getstation

FFLAGS = -O
###FFLAGS = -g -C

###FC = g95
FC = pgf90

ersstv3b2dat:	ersstv3b2dat.o Makefile
		$(FC) $(FFLAGS) -o $@ $@.o $(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a

ersst2dat:	ersst2dat.o Makefile
		$(FC) $(FFLAGS) -o $@ $@.o $(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a

getprcp:	getprcp.o support.o
		$(FC) $(FFLAGS) -o $@ $@.o support.o

gettemp:	gettemp.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

gettemp_v2:	gettemp_v2.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

getstation:	getstation.o
		$(FC) $(FFLAGS) -o $@ $@.o

makeyearslpindex: makeyearslpindex.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

makeyearslpindex_v2: makeyearslpindex_v2.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

makeyearprecindex: makeyearprecindex.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

makeyearprecindex_v2: makeyearprecindex_v2.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

makeyeartempindex: makeyeartempindex.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

makeyeartempindex_v2: makeyeartempindex_v2.o newsupport.o
		$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

ncdc2grads:	ncdc2grads.F
		$(FC) $(FFLAGS) -o $@ ncdc2grads.F $(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a
