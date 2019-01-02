program convert_regression
!
!   convert the output of the linear regression on the tropical SST on NinoX indices to
!   the factor 1/(1-A) that gives teh correct amplitude. Note that the 3-month running means
!   are dated on the first month, not the central month.
!   Export these factors in a string scaleseries understands.
!   (should really learn python)
!
    implicit none
    integer i,lag,mo,n
    real fac(12),corr,p,a1,da1,a2,da2,regr,dregr
    character file*255
    
    call getarg(1,file)
    open(1,file=trim(file),status='old')
    do mo=1,12
        read(1,*) i,lag,corr,p,n,a1,da1,a2,da2,regr,dregr
        i = 1 + mod(mo,12)
        fac(i) = 1/(1-regr)
    end do
    print '(12(f6.4,a))',(fac(i),';',i=1,11),fac(12)
end program