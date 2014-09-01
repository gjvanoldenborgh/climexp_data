        program makecnt
!
!       make the CNT v6 as defined by Aad in his draft WR
!
        implicit none
        integer yrbeg,yrend,nfiles
        parameter (yrbeg=1906,yrend=2020,nfiles=6)
        integer mo,yr,nperyear,i,j,n
        real cnt(12,yrbeg:yrend),series(12,yrbeg:yrend,nfiles),s
        character file*256,files(nfiles)*16,var*20,units*20,string*10
        logical lwrite
        data lwrite /.false./
        data files /'tg260_mean12.dat','tg283_mean12.dat',
     +       'tg350_mean12.dat','tg375_mean12.dat',
     +       'tg275_mean12.dat','tg370_mean12.dat'/

        call getarg(1,string)
        if ( string.eq.' ' .or. string.eq.'1.0' .or. string.eq.'1' )
     +       then
            file = 'CNT4_6.dat'
        else if ( string.eq.'1.1' ) then
            file = 'cnt_record_adjusted.txt'
        else
            write(0,*) 'usage: makecnt [1.0|1.1]'
            call abort
        end if
        call readseries(trim(file),cnt,12,yrbeg,yrend,nperyear,
     +       var,units,.false.,lwrite)
        do i=1,nfiles
            !!!print '(2a)','# reading ',trim(files(i))
            call readseries(files(i),series(1,yrbeg,i),12,yrbeg,yrend
     +           ,nperyear,var,units,.false.,lwrite)
        end do
        do yr=2000,yrend
            do mo=1,12
                s = 0
                n = 0
                do i=1,nfiles
                    if ( series(mo,yr,i).lt.1e33 ) then
                        s = s + series(mo,yr,i)
                        n = n + 1
                    end if
                end do
                s = s/n
                if ( cnt(mo,yr).lt.1e33 ) then
!                   check
                    if ( abs(cnt(mo,yr) - s).gt.0.06 ) then
                        write(0,*) 'makecnt: error: CNT not correct: '
     +                       ,cnt(mo,yr),s,cnt(mo,yr)-s,yr,mo
                    end if
                else
!                   fill in
                    cnt(mo,yr) = s
                end if
            end do
        end do
        call copyheader(trim(file),6)
        call printdatfile(6,cnt,12,nperyear,yrbeg,yrend)
        end
