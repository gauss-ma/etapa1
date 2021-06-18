FC=gfortran
FCFLAGS=-c -O3 -ffree-line-length-2000000 # -fcheck=bounds -mtune=native
LDFLAGS=

OBJECTS=ETAPA1.o

all:    $(OBJECTS)
	$(FC) $(LDFLAGS) $(OBJECTS) -o ../../exe/ETAPA1.EXE

%.o: %.f90
	$(FC) $(FCFLAGS) $< -o $@

clean:
	rm -rf *.o *.mod *.EXE

