        program max_forecast
!
!       determine when to make the forecast "tomorrow good weather:
!       as a function of the past number of days with good weather
!       define good weather as >50% sunshine, this is 1/3 of the # of
!       days in summer
!
        implicit none
        integer yrbeg,yrend
        parameter(yrbeg=1901,yrend=2007)
        integer sign,yr,dy,i,j,nperyear,n,m,m1,nn(21)
        real cut,data(366,yrbeg:yrend)
        character string*4,file*255,var*20,units*20
        logical lwrite,lstandardunits
        lwrite = .false.

        call getarg(1,string)
        if ( string.eq.'sun' ) then
            file='sp260.dat'
            cut=0.5
            sign=1
        elseif ( string.eq.'temp' ) then
            file='tx260.dat'
            cut=23
            sign=1
        elseif ( string.eq.'rain' ) then
            file='rh260.dat'
            cut=2
            sign=-1
        else
            print *,'please specify sun|temp|rain, not ',trim(string)
            call abort
        endif
        call readseries(file,data,366,yrbeg,yrend,nperyear,
     +       var,units,lstandardunits,lwrite)
        nn = 0
        do n=1,21
            m = 0
            m1 = 0
            do yr=yrbeg,yrend
                i = 0
                do dy=153,244   ! JJA
                    if ( data(dy,yr).lt.1e33 .and.
     +                   sign*data(dy,yr).gt.sign*cut ) then
                        i = i + 1
                        if ( i.eq.n ) then
                            m = m + 1
                            if ( data(dy+1,yr).lt.1e33 .and.
     +                           sign*data(dy+1,yr).gt.sign*cut ) then
                                m1 = m1 + 1
                                if ( lwrite ) print *,
     +                               'mooie dag voor mooie dag ',yr,dy
     +                               ,data(dy,yr)
                            else
                                if ( lwrite ) print *,
     +                               'laatste mooiweer dag',yr,dy
                                nn(i) = nn(i) + 1
                            endif
                        endif
                    else
                        i = 0
                    endif
                enddo
            enddo
            print *,n,real(m1)/m,m1,m,trim(string)
        enddo
        do i=1,21
            write(0,*) i,nn(i)
        enddo
        end
