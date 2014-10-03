        program hemi2gloabl
*
*       combine the Jones hemispheric averages (which are up-to-date)
*       into a global one (which is not)
*       
        implicit none
        integer yr,i,p(12),pn(12),ps(12)
        real tn(13),ts(13),t(13)
*       
        open(1,file='tavenh.dat',status='old')
        open(2,file='tavesh.dat',status='old')
        do yr=1856,2020
            read(1,*,end=800) i,tn
            if ( i.ne.yr ) then
                print *,'NH year wrong: ',yr,i
                call abort
            endif
            read(1,*) i,pn
            if ( i.ne.yr ) then
                print *,'NH year wrong: ',yr,i
                call abort
            endif
            read(2,*) i,ts
            if ( i.ne.yr ) then
                print *,'SH year wrong: ',yr,i
                call abort
            endif
            read(2,*) i,ps
            if ( i.ne.yr ) then
                print *,'SH year wrong: ',yr,i
                call abort
            endif
            do i=1,13
                t(i) = (ts(i) + tn(i))/2
            enddo
            do i=1,12
                p(i) = (ps(i) + pn(i))/2
            enddo
            print '(i5,13f7.2)',yr,t
            print '(i5,12i7)',yr,p
        enddo
  800   continue
        end
