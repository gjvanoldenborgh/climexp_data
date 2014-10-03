	program make_elfsteden
	implicit none
	integer yrbeg,yrend
	parameter (yrbeg=1900,yrend=2004)
	integer mo,yr,nn(12,yrbeg:yrend)

	do yr=yrbeg,yrend
	    do mo=1,12
		nn(mo,yr) = 0
	    enddo
	enddo
	nn(1,1909) = 1
	nn(2,1912) = 1
	nn(1,1917) = 1
	nn(2,1929) = 1
	nn(12,1933)= 1
	nn(1,1940) = 1
	nn(2,1941) = 1
	nn(1,1942) = 1
	nn(2,1947) = 1
	nn(2,1954) = 1
	nn(2,1956) = 1
	nn(1,1963) = 1
	nn(2,1985) = 1
	nn(2,1986) = 1
	nn(1,1997) = 1
	open(1,file="elfsteden.dat')
	write(1,'(a)') '# months with Elfstedentochten (Eleven City Races)'
	write(1,'(a)') '# from the Zenith article by Herman Wessels at'
	write(1,'(a)') '# <a href="http://www.knmi.nl/voorl/nader/'//
     +		'icefrl.htm">KNMI</a>'
	write(1,'(a)') '#'
	write(1,'(a)') '#'
	do yr=yrbeg,yrend
	    write(1, '(i4,12i2)') yr,(nn(mo,yr),mo=1,12)
	enddo
	close(1)
	end
