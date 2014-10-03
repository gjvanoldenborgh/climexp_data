        program dag2maand
*
*       convert the daily values into monthly means
*
        implicit none
        intgeger yrbeg,yrend
        parameter(yrbeg=1901,yrend=2001)
        integer stn,date,yr,mo,dy,yr0
        character*256 string
        real tg(12),rh(12),dd(12),sp(12)
        integer iargc,llen
        external iargc,getarg,llen
*
        if ( iargc().ne.1 ) then
            print *,'usage: dag2maand stationid'
            stop
        endif
        call getarg(1,string)
        read(string,*) stn
*
        do yr0=yrbeg,yrend,10
            write(string,'(a,i3,a,i4)') 'etmgeg_',stn,'_',yr
            open(1,file=string,status='old',err=901)
  100       continue
            read(1,'(a)',err=902,end=902) string
            if ( string(1:6).ne.'  STN,' ) goto 100
            do yr=yr0,yr0+9
                if ( mod(yr,4).eq.0 ) then
                    if ( mod(yr,100).eq.0 ) then
                        if ( mod(yr,400).eq.0 ) then
                            leap = 2
                        else
                            leap = 1
                        endif
                    else
                        leap = 2
                    endif
                else
                    leap = 1
                endif
                do mo=1,12
                    tg(mo) = 0
                    rh(mo) = 0
                    dd(mo) = 0
                    sp(mo) = 0
                    do dy=1,dpm(mo,leap)
                        read(1,1000) stn,date,
        enddo
@@@@@@@@@@@@@@        
        stop
  901   print *,'error: cannot open file string(1:llen(string))
        call abort
  902   print *,'error: error reading string ',string(1:llen(string))
        call abort
        end
