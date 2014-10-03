#!/bin/sh
# monthly mean global sea level
cp gslJC2006.txt gslJC2006.txt.old
wget -N http://www.psmsl.org/products/reconstructions/gslJC2006.txt
cmp gslJC2006.txt gslJC2006.txt.old
if [ $? != 0 ]; then
  egrep '^%' gslJC2006.txt | fgrep -v gsl_rate | fgrep -v "Time period" | \
    sed -e 's/%/#/' -e 's@PSMSL (www.pol.ac.uk/psmsl)@<a href="http://www.pol.ac.uk/psmsl/" target="_new">PSMSL</a>@' > gsl.dat
  echo "# gsl [mm] global sea level" >> gsl.dat
  egrep -v '^%' gslJC2006.txt | egrep -v '^[[:space:]]$' | awk '{print $1 " " $4}'  >> gsl.dat

  egrep '^%' gslJC2006.txt | fgrep -v gsl_rate | fgrep -v "Time period" | \
    sed -e 's/%/#/' -e 's@PSMSL (www.pol.ac.uk/psmsl)@<a href="http://www.pol.ac.uk/psmsl/" target="_new">PSMSL</a>@' > gsl_err.dat
  echo "# gsl_error  [mm] error on global sea level" >> gsl_err.dat
  egrep -v '^%' gslJC2006.txt | egrep -v '^[[:space:]]$' | awk '{print $1 " " $5}' >> gsl_err.dat
  egrep '^%' gslJC2006.txt | fgrep -v gsl_rate | fgrep -v "Time period" | \
    sed -e 's/%/#/' -e 's@PSMSL (www.pol.ac.uk/psmsl)@<a href="http://www.pol.ac.uk/psmsl/" target="_new">PSMSL</a>@' > gsl_rate.dat
  echo "# gsl_rate [mm/yr] rae of change of global sea level" >> gsl_rate.dat
  egrep -v '^%' gslJC2006.txt | egrep -v '^[[:space:]]$' | awk '{print $1 " " $2}'  >> gsl_rate.dat

  egrep '^%' gslJC2006.txt | fgrep -v gsl_rate | fgrep -v "Time period" | \
    sed -e 's/%/#/' -e 's@PSMSL (www.pol.ac.uk/psmsl)@<a href="http://www.pol.ac.uk/psmsl/" target="_new">PSMSL</a>@' > gsl_rate_err.dat
  echo "# gsl_rate_error [mm/yr] error on rate of change of global sea level" >> gsl_rate_err.dat
  egrep -v '^%' gslJC2006.txt | egrep -v '^[[:space:]]$' | awk '{print $1 " " $3}' >> gsl_rate_err.dat
  $HOME/NINO/copyfiles.sh gsl_*.dat
fi

# annual mean global sea level
cp gslGRL2008.txt gslGRL2008.txt.old
wget -N http://www.psmsl.org/products/reconstructions/gslGRL2008.txt
cmp gslGRL2008.txt gslGRL2008.txt.old
if [ $? != 0 ]; then
  egrep '^%' gslGRL2008.txt | fgrep -v gsl_rate | fgrep -v "Time period" | \
    sed -e 's/%/#/' -e '/Description/,$d' > gsl_ann.dat
  echo '# <a href="http://www.pol.ac.uk/psmsl/author_archive/jevrejeva_etal_1700/">PSMSL</s>' >> gsl_ann.dat
  echo "# gsl [mm] global sea level" >> gsl_ann.dat
  egrep -v '^%' gslGRL2008.txt | egrep -v '^[[:space:]]$' | awk '{print $1 " " $2}'  >> gsl_ann.dat

  egrep '^%' gslGRL2008.txt | fgrep -v gsl_rate | fgrep -v "Time period" | \
    sed -e 's/%/#/' -e '/Description/,$d' > gsl_ann_err.dat
  echo '# <a href="http://www.pol.ac.uk/psmsl/author_archive/jevrejeva_etal_1700/">PSMSL</s>' >> gsl_ann_err.dat
  echo "# gsl_error  [mm] error on global sea level" >> gsl_ann_err.dat
  egrep -v '^%' gslGRL2008.txt | egrep -v '^[[:space:]]$' | awk '{print $1 " " $3}' >> gsl_ann_err.dat
  $HOME/NINO/copyfiles.sh gsl_ann*.dat
fi

exit
# should be updated to the new format...
cp nucat.dat nucat.dat.old
wget -N http://www.pol.ac.uk/psmsl/pub/nucat.dat
cp psmsl.dat psmsl.dat.old
wget -N http://www.pol.ac.uk/psmsl/pub/psmsl.dat
cmp psmsl.dat psmsl.dat.old
if [ $? = 0 ]; then
  exit
fi
make dat2mydat
mv psmsl.mydat psmsl.mydat.old
./dat2mydat

nrec_slv=`wc -l < psmsl.mydat`
nstat_slv=`tail -1 psmsl.mydat | cut -b 1-6`
sed -e "s/NREC_SLV/$nrec_slv/" \
 -e "s/NSTAT_SLV/$nstat_slv/" \
  support_in.f > support.f
make getsealev 

$HOME/NINO/copyfiles.sh nucat.dat psmsl.mydat
scp getsealev bhlclim:climexp/bin/

