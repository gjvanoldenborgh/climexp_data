###FFLAGS = -O
FFLAGS = -g -fbounds-check

FC = gfortran

.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

LIBS = 	$(HOME)/NINO/Fortran/$(PVM_ARCH)/climexp.a \
	$(HOME)/NINO/Fortran/$(PVM_ARCH)/libnr.a

SYSLIBS = -L$(HOME)/lib -L/sw/lib -L/sw/opt/netcdf7/lib -lnetcdff -lnetcdf -lhdf5 -lcurl

scpdsi2nc: scpdsi2nc.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)

update_nao:	update_nao.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)

ts2grads:	ts2grads.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

ts32grads:	ts32grads.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

new2grads:	new2grads.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

makeeuslpindex:	makeeuslpindex.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

sort_data:	sort_data.o $(LIBS)
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

geteuslp:	geteuslp.o newsupport.o
	$(FC) $(FFLAGS) -o $@ $@.o newsupport.o

timeseries:	taveglobal2v.dat tavenorth2v.dat tavesouth2v.dat

taveglobal2v.dat:	tavegl2v.dat dat2dat
			./dat2dat < tavegl2v.dat > $@

tavenorth2v.dat:	tavenh2v.dat dat2dat
			./dat2dat < tavenh2v.dat > $@

tavesouth2v.dat:	tavesh2v.dat dat2dat
			./dat2dat < tavesh2v.dat > $@
