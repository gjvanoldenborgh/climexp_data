program txt2dat
!
! 	convert the txt file obtained from stripping the HTML from Mset.htm
!	into Climate Explorer standard .dat files
!
implicit none
integer yr,mo,ifile
real data(6)
character infile*256,file*256

call getarg(1,infile)
if ( infile.eq.' ' ) then
	write(0,*) 'usage: txt2dat file.txt'
	stop
end if
open(10,file=trim(infile),status='old')

do ifile=1,6
	write(file,'(a,i1,a)') 'M',ifile,'.dat'
	open(ifile,file=trim(file))
	write(ifile,'(a,i1,a)') '# index M',ifile,' from <a href="http://www.mbari.org/bog/GlobalModes/Indices.htm">Mset</a>'
	write(ifile,'(a,i1,a)') '# M',ifile,' [1]'
end do

do
	read(10,*,end=800) yr,mo,data
	do ifile=1,6
		write(ifile,'(2i4,f8.4)') yr,mo,data(ifile)
	end do
end do

800	continue
do ifile=1,6
	close(ifile)
end do

end program txt2dat