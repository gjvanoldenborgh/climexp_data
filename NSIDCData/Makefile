.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC = gfortran

FFLAGS = -O # -g -fbounds-check

txt2dat:	txt2dat.o
	$(FC) $(FFLAGS) -o $@ txt2dat.o

day2mon:	day2mon.o
	$(FC) $(FFLAGS) -o $@ day2mon.o

bootstrap2grads:    bootstrap2grads.o
	$(FC) $(FFLAGS) -o $@  $@.o

polar2grads:    polar2grads.o
	$(FC) $(FFLAGS) -o $@  $@.o