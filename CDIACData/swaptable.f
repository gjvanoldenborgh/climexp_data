        program swaptable
        implicit none
        integer i,j,data(12,19)
        character strings(19)*10,line*200

        open(1,file='sres.txt')
        do i=1,19
            read(1,'(a)') line
            strings(i) = line(1:9)
            read(line(10:),*) (data(j,i),j=1,12)
        enddo

        print '(20a)','#     ',strings
        do j=1,12
            print '(19i10)',(data(j,i),i=1,19)
        enddo

        end
