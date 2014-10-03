        program grid
        implicit none
        integer nx,ny
        real dx,dy,x1,y1
        character string*20
        integer iargc

        if ( iargc().ne.2 ) then
            print *,'usage: grid nx ny'
            stop
        endif

        call getarg(1,string)
        read(string,*) nx
        dx = 360./nx
        x1 = -180 + dx/2
        call getarg(2,string)
        read(string,*) ny
        dy = dx
        y1 = -ny*dy/2 + dy/2

        call printaxis('longitude',nx,x1,dx)
        call printaxis('latitude',ny,y1,dy)

        end

        subroutine printaxis(string,nx,x1,dx)
        implicit none
        integer nx
        real x1,dx
        character string*(*)
        integer i,j
        print '(3a)',' '//trim(string)//' = '
        do i=1,nx/10-1
            print '(10(f9.3,a))',(x1 + (10*(i-1) + (j-1))*dx,
     +           ',',j=1,10)
        enddo
        print '(10(f9.3,a))',(x1 + (10*(i-1) + (j-1))*dx,
     +       ',',j=1,nx-10*(i-1)-1),
     +       x1 + (nx-1)*dx,' ;'
        end
