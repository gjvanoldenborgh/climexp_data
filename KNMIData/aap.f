	program aap
	character line*80
	open(1,file='aap')
	read(1,'(a)') line
	print *,trim(line)
        print *,ichar(line(3:3))
	print *,index(line,char(176))
	end
