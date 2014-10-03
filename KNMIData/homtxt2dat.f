	program homtxt2dat
	implicit none
	character line*255
        integer init

        init = 0
    1   continue
	read(*,'(a)',end=800) line
	if ( len_trim(line).le.1 ) goto 1
	if ( index(line,'=').ne.0 ) goto 1
	if ( index(line,'STN').ne.0 ) goto 1
	if ( line(1:3).ne.'260' ) then
	    print '(2a)','# ',trim(line)
	    goto 1
	endif
        if ( init.eq.0) then
            init = 1
            print '(a)','# Tair [C] at 52.100N,  5.183E, 2.0m'
        endif
        print '(4a)',line(5:8),' ',line(9:10),trim(line(13:))
       	goto 1
  800	continue
	end
