	program tmtransmonth
	implicit none 
	! can be used to transform an observed time series in a future one
	! with the help of the 10% quantile (Q10),
	! the 50% quantile (Q50)
	! and the 90% quantile (Q90)
	! for each of the calendar month

	! syntax : t2m-trans-month <parfile> input(STDIN) output(STDOUT)
	! parfile contains the relative changes in % of Q10, Q50 and Q90
	! and is expected to have 4 cols like:
	!
	! 1       -8.7    6.2     11.7 
	! 2       -19.3   0.3     12.3 
	! 3       -8.7    6.2     11.7
	! .......
	! 12       1.9     12.1    11.2 
	!
	! containing monthnr, dQ10, dQ50 and dQ90
	! Changes default to point zero	and are dumped to STDERR for check 
	!
	! syntax to compile: "g77 t2m-trans-month.f" 
	! for any questions ask Robert Leander
	
	character*(100) regel 
	character*(50) parfile			! name of parameter file 
	character*(*) fmt
	parameter(fmt='10.5')			! format specifier (string) for output 
						! in the form 'spaces.decimals'
	integer im,ivar,instr,j,date,i10alpha,i50alpha,i90alpha  
	real*8 value				! temporary temperature amount
	real*8 chg(12,3)			! absolute changes, (month,var) 
						! read from parameter file
	real*8 months(0:31*100,12) 
	real*8 Q10_o(12),Q10_f(12)		! Q10 observed and future
	real*8 Q50_o(12),Q50_f(12)		! Q50 observed and future
	real*8 Q90_o(12),Q90_f(12)		! Q90 observed and future
	real*8 a(12)				! transformation parameter a
	real*8 b(12)				! transformation parameter b
	real*8 x90
	parameter (x90=90.d0)			! quantile to be fitted [%]
	real*8 x50
	parameter (x50=50.d0)			! quantile to be fitted [%]
	real*8 x10
	parameter (x10=10.d0)			! quantile to be fitted [%]
	integer cnt(12)				! general daycounter per months
	character*3 acroniem(12) 		! acronyms for months 
	data acroniem/'Jan','Feb','Mar','Apr','May','Jun',
     &	              'Jul','Aug','Sep','Oct','Nov','Dec'/


	! SET DEFAULT VALUES FOR RELATIVE CHANGES TO ZERO 
	do im=1,12
	   do ivar=1,3 
	      chg(im,ivar)=0.0d0
	   enddo 
	enddo 
	
	! READ THE RELATIVE CHANGES IN % FROM FILE GIVEN IN ARGV[1]
	call getarg(1,parfile)
	open(22,file=parfile(1:instr(parfile,' ')-1))
	do while(.True.)
 222	   read(22,'(a100)',end=122) regel 
	   read(regel,*,end=222,err=222) 
     &	        im, (chg(im,ivar),ivar=1,3)
	enddo 
 122	continue 
	close(22)

	! AND WRITE THOSE CHANGES ON THE SCREEN
	write(0,'(a)') 
     & 	       '# month     deltaQ10    deltaQ50     deltaQ90'
	do im=1,12
	   write(0,'(a8,3f14.3)') acroniem(im),
     &	                          (chg(im,ivar),ivar=1,3)
	enddo 
	write(0,*)

	! READ THE DATA TO BE TRANSFORMED FROM STDIN, CALCULATE STATISTICS AND 
	! WRITE TO TEMPORARY SCRATCH FILE (13)
	do im=1,12
	   Q10_o(im)=0.0d0
	   Q50_o(im)=0.0d0
	   Q90_o(im)=0.0d0
	   months(0,im)=1E+07
	enddo 

	open(13,status='SCRATCH')			!temporary scratch file 
	do while(.True.)
	   read(*,*,end=666) date, value 
	   write(13,*) date, value 
	   im=mod(date,1000000)/10000
	   cnt(im)=cnt(im)+1
	   j = cnt(im)
	    do while(value.gt.months(j-1,im)) 		! separate the input time series per season
	      months(j,im)=months(j-1,im)		! and sort them
	      j=j-1
	    enddo
	   months(j,im)=value
	enddo 
 666	continue 

	! DETERMINE THE OBSERVED QUANTILE FOR EACH MONTH
	do im=1,12
	   i90alpha=int((1.-x90*0.01)*cnt(im))
	   Q90_o(im)=(months(i90alpha,im)+months(i90alpha+1,im))
     &	                    /(2.+1E-07)
	   i50alpha=int((1.-x50*0.01)*cnt(im))
	   Q50_o(im)=(months(i50alpha,im)+months(i50alpha+1,im))
     &	                    /(2.+1E-07)
	   i10alpha=int((1.-x10*0.01)*cnt(im))
	   Q10_o(im)=(months(i10alpha,im)+months(i10alpha+1,im))
     &	                    /(2.+1E-07)
	enddo 

	! DETERMINE THE QUANTILES FOR THE FUTURE CLIMATE 
	do im=1,12
	   Q10_f(im) = Q10_o(im)+(chg(im,1))	! 1 = Q10
	   Q50_f(im) = Q50_o(im)+(chg(im,2))	! 2 = Q50
	   Q90_f(im) = Q90_o(im)+(chg(im,3))	! 3 = Q90
	enddo 

	! CALCULATE a AND b
	do im=1,12
	   a(im) = (Q90_f(im) - Q50_f(im))/(Q90_o(im) - Q50_o(im))
	   b(im) = (Q10_f(im) - Q50_f(im))/(Q10_o(im) - Q50_o(im))
	enddo
	
	write(0,'(a)')'#month		a		b'
	do im=1,12
	 write(0,'(a8,2f12.8)') acroniem(im),b(im),a(im)
	enddo
	write(0,*)
	
	!CALCULATE NEW DATA FOR THE FUTURE
	rewind(13)
	do while(.TRUE.)
	  read(13,*,end=614) date, value			! read from scratch #13
	  im = mod(date,1000000)/10000
	  if(value.ge.Q50_o(im))then
	   value = a(im)*(value-Q50_o(im))+Q50_f(im)
	  elseif (value.lt.Q50_o(im))then
	   value = b(im)*(value-Q50_o(im))+Q50_f(im)
	  endif
	  write(*,'(i12,f'//fmt//')') date, value		! write to STDOUT
	enddo 
 614	continue 
	close(13)
	end


	integer function instr(s,ssub)
        ! same as 'index'
        ! it returns the position of substring ssub in string s
        ! 0 if not found
        implicit none
        integer j,ls,lsub
        character*(*) s
        character*(*) ssub
        ls=len(s)
        lsub=len(ssub)
        instr=0
        if(lsub.le.ls) then
           instr=0
           do j=1,ls-lsub+1
              if(s(j:j+lsub-1).eq.ssub) then
                 instr=j
                 goto 676
              endif
           enddo
 676       continue
        endif
        return
        end


