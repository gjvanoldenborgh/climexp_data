.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC=gfortran
###FC = g95

###FFLAGS = -fast -Wl,-Bstatic
###FFLAGS = -O -Wl,-Bstatic
FFLAGS = -O -m64

LIBS = $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a

all:		serieslist.dat ecadata

serieslist.dat: stamap/serieslist.dat.gz
		gunzip -c stamap/serieslist.dat.gz > serieslist.dat

ecadata:	ecadata.o support.o $(LIBS)
		$(FC) $(FFLAGS) -o $@ $@.o support.o $(LIBS)

txt2dat:	txt2dat.o $(LIBS)
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

ecadata.tar:	
		(cd dataset; cd ..; tar cf /tmp/ecadat.tar stamap dataset)
