        program tele2dat
*
*       convert the CPC teleconnection index table to a couple of dat files
*
        implicit none
        integer npat
        parameter(npat=12)
        integer year,month,i,j,k,yrbeg,yrend,state,status
        parameter (yrbeg=1950,yrend=2020)
        real data(12,yrbeg:yrend,npat)
        character*130 string
        character*43 names(3:npat)
        data names 
     $       /'North Atlantic Oscillation (NAO)           '
     $       ,'East Atlantic Pattern (EA)                 '
     $       ,'West Pacific Pattern (WP)                  '
     $       ,'East Pacific / North PAcific Pattern (EP)  '
     $       ,'Pacific/North American Pattern (PNA)       '
     $       ,'East Atlantic/Western Russia Patern (EA/WR)'
     $       ,'Scandinavia Pattern (SCA)                  '
     $       ,'Tropical/Northern Hemisphere attern (TNH)  '
     $       ,'Polar/Eurasia Pattern (POL)                '
     $       ,'Pacific Transition Pattern (PT)            '
     $       /
*       
        do i=3,npat
            do year=yrbeg,yrend
                do month=1,12
                    data(month,year,i) = 3e33
                enddo
            enddo
        enddo
        open(1,file='tele_index.nh',status='old')
        state = 0
  100   continue
        read(1,'(a)',err=900,end=800) string
        if ( string(1:7).eq.'1950  1' ) then
            year = 1950
            month = 1
            state = 1
        else
            month = month + 1
            if ( month.gt.12 ) then
                month = month - 12
                year = year + 1
            endif
        endif
        if ( state.eq.0 ) goto 100
 1000   format(2i4,12f6.2)
        read(string,1000,err=901,end=901) i,j,(data(month,year,k),k=3
     +       ,npat)
        if ( i.ne.year ) then
            write(0,*) 'Error in year ',i,year
            call abort
        endif
        if ( j.ne.month ) then
            write(0,*) 'Error in month ',j,month
            call abort
        endif
        goto 100
  800   continue
        do i=3,npat
            do year=yrbeg,yrend
                do month=1,12
                    if ( data(month,year,i).eq.-99.9 ) 
     +                    data(month,year,i) = 3e33
                enddo
            enddo
        enddo
*       
        call mysystem('rm cpc_nao.dat cpc_ea.dat',status)
        call mysystem('rm cpc_wp.dat cpc_epnp.dat',status)
        call mysystem('rm cpc_pna.dat cpc_ea_wr.dat cpc_sca.dat',status)
        call mysystem('rm cpc_tnh.dat cpc_pol.dat cpc_pt.dat',status)
*
        open(13,file='cpc_nao.dat',status='new')
        open(14,file='cpc_ea.dat',status='new')
        open(15,file='cpc_wp.dat',status='new')
        open(16,file='cpc_epnp.dat',status='new')
        open(17,file='cpc_pna.dat',status='new')
        open(18,file='cpc_ea_wr.dat',status='new')
        open(19,file='cpc_sca.dat',status='new')
        open(20,file='cpc_tnh.dat',status='new')
        open(21,file='cpc_pol.dat',status='new')
        open(22,file='cpc_pt.dat',status='new')
*       
        do i=3,npat
            write(i+10,'(2a)') '# CPC ',names(i)
            write(i+10,'(a)') '# <a href="http://www.cpc.noaa.gov/'//
     +           'data/teledoc/telecontents.shtml" target="new">'//
     +           'CPC teleconnections</a>'
            do j=3,5
                write(i+10,'(a)') '#'
            enddo
            call printdatfile(i+10,data(1,yrbeg,i),12,12,yrbeg,yrend)
        enddo
        stop

 900    write(0,*) 'Error reading ',year,month
        call abort
 901    write(0,*) 'error reading 16 values from ',string
        call abort

        end
