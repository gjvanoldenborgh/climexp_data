	program rrtransmonth
	implicit none 
	! can be used to transform an observed time series in a future one
	! with the help of the wet-day frequency (fwet),
	! the wet-day Qxx (Qxx)
	! and the wet-day mean (mwet)
	! for each of the calendar month

	! syntax : rr-trans-month <parfile> input(STDIN) output(STDOUT)
	! parfile contains the relative changes in % of fwet, mwet and Qxx
	! and is expected to have 4 cols like:
	!
	! 1       -8.7    6.2     11.7 
	! 2       -19.3   0.3     12.3 
	! 3       -8.7    6.2     11.7
	! .......
	! 12       1.9     12.1    11.2 
	!
	! containing monthnr, delta_fwet, delta_mwet, delta_Qxx
	! (Qxx is actually Q99 in the current implementation)
	! Changes default to point zero	and are dumped to STDERR for check 
	!
	! syntax to compile: "g77 rr-trans.f" 
	! for any questions ask Robert Leander
	
	character*(100) regel 
	character*(50) parfile			! name of parameter file 
	character*(*) fmt
	parameter(fmt='10.5')			! format specifier (string) for output 
						! in the form 'spaces.decimals'
	integer im,ivar,instr,j,date,ialpha  
	real*8 value				! temporary rainfall amount
	real*8 chg(12,3)			! relative changes [%], (month,var) 
						! read from parameter file 
	real*8 months(0:31*100,12)		! arrays used for sorting wet days 
	real*8 th 				
	parameter(th=0.05d0)			! wet-day threshold (dependent on the input)
	real*8 XX
	parameter(XX=99.d0)			! quantile to be fitted [%]
	integer cnt(12) 			! general daycounter for each month
	real*8 cnt_wd(12) 
	real*8 fwet_o(12),fwet_f(12)		! wet-day frequency observed and future 
	real*8 dfwet(12),dfdry(12)		! relative change of fwet and fdry (dry-day frequency)
	real*8 mwet_o(12),mwet_f(12)		! mean wet-day amount observed and future 
	real*8 Qxxwet_o(12),Qxxwet_f(12)	! wet-day Qxx observed and future 
	real*8 lastwet(12)			! stored last wet-day amount, used for 
						! wetting dry days 

	real*8 b(12),a(12)			! calculated transform parameters 
	real*8 pwrmean				! real function calculating the mean of P^b
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
     & 	       '# month     delta fwet    delta mwet     delta Qxx'
	do im=1,12
	   write(0,'(a8,3f14.3)') acroniem(im),
     &	                          (chg(im,ivar),ivar=1,3)
	enddo 
	write(0,*)

	! READ THE DATA TO BE TRANSFORMED FROM STDIN, CALCULATE STATISTICS AND 
	! WRITE TO TEMPORARY SCRATCH FILE (13)
	do im=1,12
	   cnt(im)=0
	   fwet_o(im)=0.0d0
	   mwet_o(im)=0.0d0
	   months(0,im)=1E+07
	enddo 

	open(13,status='SCRATCH')			!temporary scratch file 
	do while(.True.)
	   read(*,*,end=666) date, value 
	   write(13,*) date, value 			!store to scratch file 
	   im=mod(date,1000000)/10000
	   cnt(im)=cnt(im)+1
	   if(value.ge.th) then  			! separate the input time series
	      fwet_o(im)=fwet_o(im)+1.d0		! per season 
	      j=int(fwet_o(im))+1
	      do while(value.gt.months(j-1,im)) 
	        months(j,im)=months(j-1,im)		! and sort them
	        j=j-1
	      enddo
	      months(j,im)=value
	      mwet_o(im)=mwet_o(im)+value
	   endif 
	enddo 
 666	continue 

	! DETERMINE THE XX%-QUANTILE OF WET-DAYS IN EACH SEASON
	do im=1,12
	   ialpha=int((1.-XX*0.01)*fwet_o(im))
	   Qxxwet_o(im)=(months(ialpha,im)+months(ialpha+1,im))
     &	                    /(2.+1E-07)
	   mwet_o(im)=mwet_o(im)/fwet_o(im)
	   fwet_o(im)=fwet_o(im)/cnt(im)
	enddo 

	! DERIVE THE REQUIRED VALUES FOR FUTURE CLIMATE 
	do im=1,12
	   fwet_f(im)=fwet_o(im)*(chg(im,1)/100.d0+1.d0)	! 1 = fwet
	   mwet_f(im)=mwet_o(im)*(chg(im,2)/100.d0+1.d0)	! 2 = mwet
	   Qxxwet_f(im)=Qxxwet_o(im)*(chg(im,3)/100.d0+1.d0)	! 3 = Qxxwet
	enddo 

	! PERFORM CORRECTION OF THE NUMBER OF WET DAYS 
	! Transformation of the number of wet days
	do im=1,12
	    dfwet(im)=chg(im,1)/100.d0		
	    dfdry(im) =-dfwet(im)*fwet_o(im)/(1.d0-fwet_o(im))	! relative change of fdry
     &	                        				! derived from the 
	    cnt_wd(im)=0.d0					! wet-day frequency
	    lastwet(im)=th
	enddo

 	open(14,status="SCRATCH")  				! open new scratch file for corrected 
				     				! wet/dry-day frequency
	rewind(13)
 	do while(.True.)
 213      read(13,*,end=113,err=213) date,value 
    	  im=mod(date,1000000)/10000 			
    	  if(dfwet(im).lt.0) then   				! drying some wet days
            if(value.ge.th) then
              cnt_wd(im)=cnt_wd(im)-dfwet(im)
              if(cnt_wd(im).ge.1.d0) then
                cnt_wd(im)=cnt_wd(im)-1.d0
                value=0.000
              endif
            endif
          else      						! wetting some dry days
            if(value.lt.th) then
              cnt_wd(im)=cnt_wd(im)-dfdry(im)
              if(cnt_wd(im).ge.1.d0) then
                cnt_wd(im)=cnt_wd(im)-1.d0
                value=lastwet(im)				! use the last encountered wet-day 
              endif						! for this month as a substitute 
            endif						! for a dry day 
            if(value.gt.th) then
              lastwet(im)=value   				! store last wet-day amount 
            endif
          endif
          write(14,*) date,value   				! write new (altered) value to #14
 	enddo	
 113    continue
       								! the new series with the CORRECTED
       								! wet days is stored in file #14

 	! CALCULATE THE TRANSFORMATION PARAMETERS a AND b FOR EACH MONTH
        !           a*((P-th)**b+th)

	do im=1,12
	   cnt(im)=0
	enddo 

        rewind 14
	do while(.True.)
	   read(14,*,end=514) date, value 
	   value=value-th					! amount over threshold
							
	   if(value.ge.0.0) then  
    	     im=mod(date,1000000)/10000 			
	     cnt(im)=cnt(im)+1
	     j=cnt(im)
	     do while(value.gt.months(j-1,im)) 
	        months(j,im)=months(j-1,im)
	        j=j-1
	     enddo					! sort descending
	     months(j,im)=value
	   endif 
	enddo ! reading from 14 
 514	continue 
							! the array 'months' now contains 
							! P-th for all (P-th)>=0

	do im=1,12 					! Calculate Qxxwet_o of (P-th) after 
           ialpha=int((1.d0-XX*0.01)*cnt(im))		! changing fwet, required 
           Qxxwet_o(im)=(months(ialpha,im)		! to determine b
     &                      + months(ialpha+1,im))
     &                      /(2.+1E-07)
							! The most rudimentary, but stable, 
							! root-finding method is used to solve 
							! b independently of a 		

              call bisect(b(im),               		! exponent b to be solved 
     &                  0.51d0,                		! lower bound 
     &                  1.7d0,                 		! upper bound 
     &                  0.0001d0,              		! relative tolerance 
     &                  th,                    		! wet-day threshold
     &                  months(1,im),          		! data X
     &                  Qxxwet_o(im),          		! observed quantile 
     &                  cnt(im),               		! number of days 
     &                  (Qxxwet_f(im)-th)
     &	                 /(mwet_f(im)-th)      		! requested ratio 
     &	                )

							! The factor a is determined to 
							! get mwet right 
	      a(im)=(mwet_f(im)-th)/
     &	               (pwrmean(months(1,im),b(im),cnt(im)))
	enddo ! im 
	
	write(0,'(a)') '# month            b           a'
	do im=1,12
	   write(0,'(a8,2f12.8)') acroniem(im),b(im),a(im)
	enddo 
	write(0,*) 

	! USE THE FOUND PARAMETERS a AND b TO TRANSFORM WET DAYS 
	rewind(14)
	do while(.True.)
	   read(14,*,end=614) date,value 			! read from scratch #14
    	   im=mod(date,1000000)/10000 				
	   if(value.ge.th) then 
	      value=a(im)*((value-th)**b(im))+th		! ACTUAL TRANSFORMATION 
	   endif 
	   write(*,'(i12,f'//fmt//')') date, value		! write to STDOUT
	enddo 
 614	continue 
	close(14)
	end

C	! OVERVIEW OF DATA FLOW BETWEEN FILES 
C	* STDIN -> #13 		observed stats calculated 		
C	* #13 -> #14		correct fwet 
C	* reread #14		recalculate Qxxwet_o and sort wet-days in months
C	* #14 -> STDOUT		transform and write resulting series 


        real*8 FUNCTION pwrmean(x,b,n)
        ! returns the mean of x**q
        implicit none
        integer                 n,i
        real*8                  b,xqmwd
        real*8       		x(*)
        xqmwd=0.0d0
        do i=1,n
           xqmwd=xqmwd+x(i)**b
        enddo
        pwrmean=xqmwd/n
        end 

        SUBROUTINE bisect(b0,lim1,lim2,tol,th,x,xp,n,ref)
        implicit none
        integer                 n
        integer                 i
        real*8       		x(*),lim1,lim2
        real*8                  b0,b1,b2,tol,th,xp,ref
        real*8                  x0,x1,x2,pwrmean

	b1=lim1
	b2=lim2
	x1=((xp)**b1)/pwrmean(x,b1,n)
	x2=((xp)**b2)/pwrmean(x,b2,n)

        do i=1,10000
          b0=(b1+b2)*0.5
	  x0=((xp)**b0)/pwrmean(x,b0,n)
          if((x2-ref)*(x0-ref).gt.0.d0) then
             b2=b0
             x2=x0
          else
             b1=b0
             x1=x0
          endif
          if(abs(b1-b2).lt.tol) goto 163
        enddo
 163    continue
        b0=(b1+b2)*0.5
        return
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
	
