	real field(19)
	open(1,file='tao_ups_-5:5.dat',form='unformatted',
     +		access='direct',recl=19)
	n=0
	i=1994
	m=0
  100	continue
	n=n+1
	m=m+1
	if ( m.gt.12 ) then
	    m = m-12
	    i = i + 1
	endif
	read(1,rec=n,err=800,end=800) field
	print '(i5,i3,19g12.3)',i,m,field
	goto 100
  800	continue
	end
