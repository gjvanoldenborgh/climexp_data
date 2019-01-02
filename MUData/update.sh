#!/bin/sh
file=PANGAEA.887593
wget --no-check-certificate -N -O $file https://doi.pangaea.de/10.1594/${file}?format=textfile
# variable
cat <<EOF  > prcp_ireland.dat
# prcp [mm/month] Island of Ireland monthly rainfall
# long reconstruction From <a href="https://www.maynoothuniversity.ie/icarus">ICARUS, Maynooth University</a>
# uncertain whether snow is included pre-1860.
# institution :: ICARUS, Maynooth University
EOF
# metadata
sep=":[ 	] *" # space & tab, not spaces
egrep "($sep)|(DATE/TIME)" $file | tr '*' '\n' | sed \
	-e "s/Coverage$sep//" \
	-e "s/Parameter(s)$sep//" \
	-e "s/$sep/ :: /" \
	-e 's/^[ 	]*/# /' \
	-e 's@ *Supplement to*@ references :: Murphy, C., Broderick, C., Burt, T. P., Curley, M., Duffy, C., Hall, J., Harrigan, S., Matthews, T. K. R., Macdonald, N., McCarthy, G., McCarthy, M. P., Mullan, D., Noone, S., Osborn, T. J., Ryan, C., Sweeney, J., Thorne, P. W., Walsh, S., and Wilby, R. L.: A 305-year continuous monthly rainfall series for the island of Ireland (1711–2016), Clim. Past, 14, 413-440, https://doi.org/10.5194/cp-14-413-2018, 2018.@' \
	-e 's@DATE/TIME START@time_coverage_start@' \
	-e 's@DATE/TIME END@time_coverage_end@' \
	-e 's/Event(s)/event/' \
	| fgrep -v 'GEOCODE' | fgrep -v '[mm]'| fgrep -v 'Date/Time' | uniq >> prcp_ireland.dat
# climexp metadata
cat <<EOF >> prcp_ireland.dat
# source_url :: https://doi.pangaea.de/10.1594/${file}?format=textfile
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?MUData/prcp_ireland
# history :: retrieved `date`
EOF
# data
egrep '^[12]' $file | tr -d '-' >> prcp_ireland.dat
$HOME/NINO/copyfiles.sh prcp_ireland.dat