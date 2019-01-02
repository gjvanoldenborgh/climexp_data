all: getsealevel

FC = gfortran

LD = $(FC)

FFLAGS = -O

getsealevel:	getsealevel.o support.o
		$(LD) $(FFLAGS) -o $@ getsealevel.o support.o
