.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

all: getprcp gettemp getstation

FFLAGS = -O
###FFLAGS = -g -C

FC = gfortran

ersstv3b2dat:	ersstv3b2dat.o Makefile
		$(FC) $(FFLAGS) -o $@ $@.o $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a

ersst2dat:	ersst2dat.o Makefile
		$(FC) $(FFLAGS) -o $@ $@.o $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a

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

ncdc2grads:	ncdc2grads.o
		$(FC) $(FFLAGS) -o $@ ncdc2grads.o $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a

ncdc2grads4:	ncdc2grads4.f90
		$(FC) $(FFLAGS) -o $@ ncdc2grads4.f90 $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a

convert_regression:	convert_regression.o
		$(FC) $(FFLAGS) -o $@ $@.o