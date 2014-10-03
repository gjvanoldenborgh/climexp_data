	program checkfile
	implicit none
	character*256 line
	integer n,llen,iargc
	external iargc,llen,getarg
	if ( iargc().ne.1 ) then
		print *,'usage: checkfile n'
		print *,'checks that all lines have length n'
		stop
	endif
	call getarg(1,line)
	read(line,*) n
  100	continue
	read(*,'(a)',end=800) line
	if ( llen(line).ne.n ) print '(a)',line(1:llen(line))
	goto 100
  800	continue
	end
        integer function llen(a)
        character*(*) a
        do 10 i=len(a),1,-1
            if(a(i:i).ne.'?' .and. a(i:i).ne.' ')goto 20
   10   continue
        llen=len(a)
   20   continue
        llen = i
        end
