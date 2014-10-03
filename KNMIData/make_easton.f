	program make_easton
	implicit none
	integer i
	real yr
	print '(a)','# Schuurman jaren'
        do i=0,50
	    yr =2006-i*22.25
	    print '(f7.2,i3)',yr,1
	enddo
	print '(a)'
	print '(a)'
	print '(a)','# mijn jaren'
	do i=0,20
	    yr = 1706 + 20*i + 19.5
	    print '(f7.2,i3)',yr,1
	enddo
	print '(a)'
	print '(a)'
	do i=0,20
	    yr = 1706 + 25*i + 24.5
	    print '(f7.2,i3)',yr,1
	enddo
	end
