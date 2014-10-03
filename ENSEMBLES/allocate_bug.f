        program fail
        integer ix,iy,dy,yr
        integer nx,ny,nperyear,firstyr,lastyr
        real,allocatable :: field(:,:,:,:)

        nx = 464
        ny = 201
        nperyear = 366
        firstyr= 1950
        lastyr = 2012

        allocate(field(nx,ny,nperyear,firstyr:lastyr))

        do yr=firstyr,lastyr
            do dy=1,nperyear
                do iy=1,ny
                    do ix=1,nx
                        field(ix,iy,dy,yr) = 1000*yr + dy +
     +                       iy/1000. + ix/1000000.
                    end do
                end do
            end do
        end do
        do yr=firstyr,lastyr
            do dy=1,nperyear
                do iy=1,ny
                    do ix=1,nx
                        print *,'field(',ix,iy,dy,y,') = ',
     +                       field(ix,iy,dy,yr)
                    end do
                end do
            end do
        end do

        end
