F90 = gfortran

%.o: %.f90
	$(F90) -c $<

txt2dat: txt2dat.o
	$(F90) $(FFLAGS) -o $@ $@.o $(LIBS)

