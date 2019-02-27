###FFLAGS = -g -fbounds-check
FFLAGS = -O

.SUFFIXES: .f90 .o

.f90.o:
	$(FC) $(FFLAGS)  -c $<

FC = gfortran

LIBS = $(HOME)/climexp_numerical/$(PVM_ARCH)/climexp.a \
       $(HOME)/climexp_numerical/$(PVM_ARCH)/wrappers.a

SYSLIBS = -L/sw/lib -L/usr/local/lib -L$(HOME)/lib -lfgsl -lgsl -lnetcdff -lnetcdf

all: dat2dat_all_new makecnt hourly2maxdaily add_pluim neerslag2dat compute_wetbulb fix_manual_gauges makehom_sd txt2dat_potwind

merge_hom:      merge_hom.o
	$(FC) $(SYSLIBS) $(FFLAGS) -o $@ $@.o $(LIBS)

heatwaves:   heatwaves.o
	$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

sur_day2mon:	sur_day2mon.o
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

max_forecast:	max_forecast.o
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

regen2dat:	regen2dat.o
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

dat2dat_all:	dat2dat_all.o
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

dat2dat_all_new:	dat2dat_all_new.o
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)

makecnt:	makecnt.o
	$(FC) $(FFLAGS) -o $@ $@.o $(LIBS) $(SYSLIBS)

T10hom2dat:	T10hom2dat.o
	$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

add_pluim:	add_pluim.o
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS) 

correct_debilt_jbf: correct_debilt_jbf.o
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

knmi_heatwave: knmi_heatwave.o
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

neerslag2dat:   neerslag2dat.o $(LIBS)
		$(FC) $(FFLAGS) -o $@ $@.o $(LIBS)

compute_wetbulb: compute_wetbulb.o $(LIBS)
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

compute_wetbulb_rh: compute_wetbulb_rh.o $(LIBS)
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

fix_manual_gauges: fix_manual_gauges.o $(LIBS)
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

fix_sd: fix_sd.o $(LIBS)
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

makehom_sd: makehom_sd.o $(LIBS)
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

txt2dat_potwind: txt2dat_potwind.o $(LIBS)
		$(FC) $(FFLAGS) $(SYSLIBS) -o $@ $@.o $(LIBS)

hourly2maxdaily: hourly2maxdaily.o
		$(FC) $(FFLAGS) -o $@ $@.o