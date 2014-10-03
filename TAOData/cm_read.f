      program cm_read
c
c   This program reads TAO anonymous FTP ascii format current meter
c   mooring files, for example 110w.velocity . It creates real time 
c   series arrays which are evenly spaced in time. 
c
c       Current meter mooring files may have several sections of
c	data, each with its own set of header records.  Each section may
c	have data several variables at one depth (eg. u and v currents
c	at 100 meters depth) or one variable at several depths (eg. 
c	temperature at 10, 30, 50, 100... meters depth). Velocity files
c	typically have a section for wind data and then a section for
c	the depth of each current meter.  Temperature files will have
c	more than one section if the number of temperature sensor depths
c	exceeds 12. 
c
c	IMPORTANT NOTE!  This program overwrites output data arrays
c	and decoded header info each time a new set of headers are 
c	encountered.  The user must save (ie., write to an output
c	file or save in a different array) these data before processing
c	a new set of headers!  Suggested place to do so is indicated
c	below.
c
c
c   Output variables and arrays
c
c Programmed by Paul Freitag, NOAA/PMEL/OCRD, January 1996
c
      integer idate(5),ldate(5)
      parameter(maxt = 10000)
      parameter(maxv = 12)
c
c
      real x(maxt,maxv),ydep(maxv)
c
      character*80 infile, header,varnam*50,tunit*8
      character*40 formin,formout
c .......................................................................
c
      write(*,*) ' Enter the input current file name '
      read(*,110) infile
c
      open(1,file=infile,status='old',form='formatted')
c 
c Read headers
c
100      write(6,101)
101	format(//' Header Records')
	do ihead=1,4
	read(1,110,end=900) header
  110 format(a)
	write(6,110) header
c header1
	if(ihead.eq.1) then
	varnam=' '
	ii=index(header,'Time interval =')
	if(ii.eq.0) go to 800
	read (header(ii+15:),111,err=800) tdel,tunit,itime
111	format(f6.1,a,2x,i5)
	i1=index(header,'Depth')
	i2=index(header,'Height')
	if(i1+i2.eq.0) then
	idep=0
	ivar=1
	varnam(1:15)=header(19:)
	else
	idep=1
	if(i1.gt.0) read(header(28:32),*,err=800) ydep(1)
	if(i2.gt.0) read(header(29:32),*,err=800) ydep(1)
	endif
c header2
	elseif(ihead.eq.2) then
	if(idep.eq.0) then
	read(header,*,err=800) idep
	ii=index(header,':')
	read(header(ii+1:),*,err=800) (ydep(i),i=1,idep)
	else
	read(header,*,err=800) ivar
	ii=index(header,':')
	read(header(ii+1:),110,err=800) varnam
	endif
	elseif(ihead.eq.3) then
	read(header,121,err=800) idate,ldate
121	format(14x,2i2,1x,3i3,32x,2i2,1x,3i3)
	elseif(ihead.eq.4) then
	formin=header(11:50) 
	ii=index(formin,',i5)')
	if(ii.eq.0) go to 800
	formin(ii:)=')'
	endif
	enddo
c
c show the decoded header info
c
	write(6,201) itime,tdel,tunit,idate,ldate
201	format(/1x,i5,' time steps of ',f5.1,a/
     1	1x,'From ',2i2,1x,3i2,', to ',2i2,1x,3i2)
	write(6,202) idep,(ydep(id),id=1,idep)
202	format(/1x,i2,' depths: ',12f6.1)
	write(6,203) ivar,varnam
203	format(/1x,i2,' variables: 'a)
c
c Read the data.
c
	if(idep.gt.ivar) then
	read(1,formin) ((x(it,id),id=1,idep),it=1,itime)
	else
	read(1,formin) ((x(it,iv),iv=1,ivar),it=1,itime)
	endif
c
c write out the first and last 5 time steps
c
	write(formout,301) max0(idep,ivar)
301	format('(1x,',i2,'f7.2)')
	write(6,302)
302	format(/1x,'First 5 time steps')
	if(idep.gt.ivar) then
	write(6,formout) ((x(it,id),id=1,idep),it=1,5)
	write(6,303)
303	format(/1x,'Last 5 time steps')
	write(6,formout) ((x(it,id),id=1,idep),it=itime-4,itime)
	else
	write(6,formout) ((x(it,iv),iv=1,ivar),it=1,5)
	write(6,303)
	write(6,formout) ((x(it,iv),iv=1,ivar),it=itime-4,itime)
	endif
c---------------------------------------------------------------------
c
c	!!!!!user must add code here to save data and decoded header info
c
c---------------------------------------------------------------------
	go to 100
c
800	write(6,801)
801	format(' Header format error')
900     close(1)
	stop
      end
      
