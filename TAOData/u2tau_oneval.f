        program u2tau
*
*       rough conversion from wind speed to wind stress
*
        implicit none
        integer i
        real u, alpha, kappa, ustar, u4, u10, z, z0, g, rho
*
        z = 4
        g = 9.82
        kappa = 0.4
        alpha = 0.018
        rho = 1
*
  100   continue
        read *,u4
*       first guess
        ustar = u4/30
*       backsubstitution
        i = 0
  200   continue
        i = i + 1
        u = ustar
        z0 = alpha*ustar**2/g
        ustar = kappa*u4/log(z/z0)
***        print *,'ustar = ',i,ustar
        if ( abs(u-ustar).gt.1e-5 .and. i.lt.30 ) goto 200
        u10 = u4*log(10/z0)/log(z/z0)
*
        print '(a,f10.3)','u4 = ',u4
        print '(a,f10.3)','u* = ',ustar
        print '(a,f10.3)','tau= ',rho*ustar**2
        print '(a,f10.6)','z0 = ',z0
        print '(a,f10.3)','u10= ',u10
        print '(a,f10.6)','CD = ',ustar**2/u10**2
        goto 100
        end
