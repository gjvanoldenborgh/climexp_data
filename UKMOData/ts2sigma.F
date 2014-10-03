        program ts2stabi
!
!       compute potential densities from the potential temperature and
!       salinity of EN3
!
        implicit none
#include "netcdf.inc"
        integer nxmax,nymax,nzmax,yrbeg,yrend,npermax,nvarmax,ntmax
        parameter(nxmax=360,nymax=173,nzmax=42,yrbeg=1950,yrend=2020
     +       ,npermax=12,nvarmax=1,ntmax=npermax*(yrend-yrbeg+1))
        integer ix,iy,iz,nx,ny,nz,nperyear,mo,yr,mens1,mens,ncid1,ncid2
     +       ,ncid3,ncid4,nt,ntvarid,itimeaxis(ntmax),nvars
     +       ,firstyr,firstmo,endian,it,status,start(4),count(4)
     +       ,ivars1(6,nvarmax),ivars2(6,nvarmax),ivars3(6,nvarmax)
     +       ,ivars4(6,nvarmax)
        real undef,xx(nxmax),yy(nymax),zz(nzmax)
        real temp(nxmax,nymax,nzmax),salt(nxmax,nymax,nzmax)
     +       ,stabi(nxmax,nymax,nzmax),sigma(nxmax,nymax,nzmax)
        character tempfile*255,saltfile*255,datfile*255,outfile*255
     +       ,title*1000,history*10000,lz(3)*20,ltime*100,vars(nvarmax)
     +       *40,lvars(nvarmax)*100,svars(nvarmax)*100,units(nvarmax)
     +       *100,cell_methods(nvarmax)*128
        logical lwrite
        lwrite = .false.

        print *,'get metadata'
        tempfile = 'temp_EN3_v2a_ObjectiveAnalysis.nc'
        saltfile = 'salt_EN3_v2a_ObjectiveAnalysis.nc'
!       assume the files are identical in grid
        call getmetadata(tempfile,mens1,mens,ncid1,datfile,nxmax,nx
     +       ,xx,nymax,ny,yy,nzmax,nz,zz,lz,nt,nperyear,firstyr,firstmo
     +       ,ltime,undef,endian,title,history,nvarmax,nvars,vars,ivars1
     +       ,lvars,svars,units,cell_methods,lwrite)
        call getmetadata(saltfile,mens1,mens,ncid2,datfile,nxmax,nx
     +       ,xx,nymax,ny,yy,nzmax,nz,zz,lz,nt,nperyear,firstyr,firstmo
     +       ,ltime,undef,endian,title,history,nvarmax,nvars,vars,ivars2
     +       ,lvars,svars,units,cell_methods,lwrite)

!!!        nt = 12 !!! DEBUG
        print *,'write metadata'
        outfile='stabi_EN3_v2a_ObjectiveAnalysis.nc'
        vars(1) = 'stabi'
        lvars(1) =
     +       'potential density minus potential density of layer above'
        svars(1) = ' '
        units(1) = 'kg/m3'
        ivars3(1,1) = nz
        call enswritenc(outfile,ncid3,ntvarid,itimeaxis,ntmax,nx,xx,ny
     +       ,yy,nz,zz,lz,nt,nperyear,firstyr,firstmo,ltime,3e33,title
     +       ,history,nvars,vars,ivars3,lvars,svars,units,cell_methods,0
     +       ,0)
        outfile='sigma_EN3_v2a_ObjectiveAnalysis.nc'
        vars(1) = 'sigma'
        lvars(1) = 'potential density wrt surface - 1000'
        svars(1) = ' '
        units(1) = 'kg/m3'
        ivars4(1,1) = nz
        call enswritenc(outfile,ncid4,ntvarid,itimeaxis,ntmax,nx,xx,ny
     +       ,yy,nz,zz,lz,nt,nperyear,firstyr,firstmo,ltime,3e33,title
     +       ,history,nvars,vars,ivars4,lvars,svars,units,cell_methods,0
     +       ,0)

        do it=1,nt
            if ( mod(it,12).eq.0 ) print *,'yr ',it/12
            count(1) = nx
            count(2) = ny
            count(3) = nz
            count(4) = 1
            start(1) = 1
            start(2) = 1
            start(3) = 1
            start(4) = it
            status = nf_get_vara_real(ncid1,ivars1(1,1),start,count,temp
     +           )
            if ( status.ne.nf_noerr ) call handle_err(status,' temp: ')
            do iz=1,nz
                do iy=1,ny
                    do ix=1,nx
                        if ( temp(ix,iy,iz).lt.-1000 ) then
                            temp(ix,iy,iz) = 3e33
                        end if
                    end do
                end do
            end do

            status = nf_get_vara_real(ncid2,ivars2(1,1),start,count,salt
     +           )
            if ( status.ne.nf_noerr ) call handle_err(status,' temp: ')
            do iz=1,nz
                do iy=1,ny
                    do ix=1,nx
                        if ( salt(ix,iy,iz).lt.-1000 ) then
                            salt(ix,iy,iz) = 3e33
                        end if
                    end do
                end do
            end do

            call compute_stabi(stabi,sigma,temp,salt,nx,ny,nz,zz)
            call writencslice(ncid3,ntvarid,itimeaxis,ntmax,ivars3,stabi
     +        ,nx,ny,nz,nx,ny,nz,it,0)
            call writencslice(ncid4,ntvarid,itimeaxis,ntmax,ivars4,sigma
     +        ,nx,ny,nz,nx,ny,nz,it,0)
        end do
        status = nf_close(ncid3) ! to flush the cache!!!
        status = nf_close(ncid4) ! to flush the cache!!!

        end

        subroutine compute_stabi(stabie,sigmae,the,sae,ie,je,ke,depth)
!
!       from Sybren (from HOPE)
!
        implicit none
        integer nxmax,nymax,nzmax,yrbeg,yrend,npermax,nvarmax,ntmax
        parameter(nxmax=360,nymax=173,nzmax=42,yrbeg=1950,yrend=2020
     +       ,npermax=12,nvarmax=1,ntmax=npermax*(yrend-yrbeg+1))
        integer ie,je,ke
        real stabie(ie,je,ke),sigmae(ie,je,ke),the(ie,je,ke)
     +       ,sae(ie,je,ke),depth(ke),undef,dz
        integer i,j,k
        real preff(nzmax),shelp(nxmax,nymax),thelp(nxmax,nymax)
     +       ,rhelp(nxmax,nymax),rhuppe(nxmax,nymax),tpo(nxmax,nymax)

        stabie(:,:,1) = 3e33
        DO K=1,KE
            PREFF(k)=0
            DO J=1,JE
                DO I=1,IE
                    SHELP(I,J)=SAE(I,J,K)
                    THELP(I,J)=THE(I,J,K)
                end do
            end do
            CALL RHO1(THELP,SHELP,PREFF(K),RHELP,ie*je)
            DO J=1,JE
                DO I=1,IE
                    if ( rhelp(i,j).lt.1e33 ) then
                        sigmae(i,j,k) = rhelp(i,j) - 1000
                    else
                        sigmae(i,j,k) = 3e33
                    end if
                end do
            end do
            if ( k.eq.1 .or. k.eq.ke ) then
                do j=1,je
                    do i=1,ie
                        stabie(i,j,k) = 3e33
                    end do
                end do
                cycle
            end if

            PREFF(k)=0.1026*DEPTH(k)
            dz = depth(k+1) - depth(k-1)
            DO J=1,JE
                DO I=1,IE
                    SHELP(I,J)=SAE(I,J,K+1)
                    THELP(I,J)=THE(I,J,K+1)
                end do
            end do
            CALL ADISIT(THELP,SHELP,PREFF(K),tpo,ie,je)
            CALL RHO1(THELP,SHELP,PREFF(K),RHELP,ie*je)
            DO J=1,JE
                DO I=1,IE
                    SHELP(I,J)=SAE(I,J,K-1)
                    THELP(I,J)=THE(I,J,K-1)
                end do
            end do
            CALL ADISIT(THELP,SHELP,PREFF(K),tpo,ie,je)
            CALL RHO1(THELP,SHELP,PREFF(K),RHUPPE,ie*je)
            DO J=1,JE
                DO I=1,IE
                    if ( rhelp(i,j).lt.1e33 .and. rhuppe(i,j).lt.1e33 )
     +                   then
                        STABIE(I,J,K) = (RHELP(I,J) - RHUPPE(I,J))/dz
                    else
                        stabie(i,j,k) = 3e33
                    end if
                end do
            end do
        end do
        end subroutine


        SUBROUTINE RHO1(T,S,P,RH,ieje)
C********************************************************
C ZUSTANDSGLEICHUNG
C UNTERPROGRAMM NACH ADRIAN GILL (ANHANG)
C+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
C
        DIMENSION S(IEJE),T(IEJE),RH(IEJE),S3H(IEJE)
        DATA B0,B1,B2,B3,B4/8.24493E-1,-4.0899E-3,7.6438E-5,
     ,       -8.2467E-7,5.3875E-9/
        DATA C0,C1,C2/-5.72466E-3,1.0227E-4,-1.6546E-6/
        DATA D0/4.8314E-4/
        DATA A0,A1,A2,A3,A4,A5/999.842594,6.793952E-2,
     ,       -9.095290E-3,1.001685E-4,-1.120083E-6,6.536332E-9/
        DATA F0,F1,F2,F3/54.6746,-0.603459,
     ,       1.09987E-2,-6.1670E-5/
        DATA G0,G1,G2/7.944E-2,1.6483E-2,-5.3009E-4/
        DATA AI0,AI1,AI2/2.2838E-3,-1.0981E-5,-1.6078E-6/
        DATA AJ0/1.91075E-4/
        DATA AM0,AM1,AM2/-9.9348E-7,2.0816E-8,9.1697E-10/
        DATA E0,E1,E2,E3,E4/19652.21,148.4206,-2.327105,
     ,       1.360477E-2,-5.155288E-5/
        DATA H0,H1,H2,H3/3.239908,1.43713E-3,
     ,       1.16092E-4,-5.77905E-7/
        DATA AK0,AK1,AK2/8.50935E-5,-6.12293E-6,5.2787E-8/
C

        NH=IEJE
C
C
        DO 100 N=1,NH
            if ( s(n).lt.1e33 ) then
                S3H(N)=SQRT(S(N)**3)
            end if
 100    CONTINUE
        DO 200 N=1,NH
            if ( s(n).gt.1e33 .or. t(n).gt.1e33 ) then
                rh(n) = 3e33
            else
                RH(N)=(A0+T(N)*(A1+T(N)
     1               *(A2+T(N)*(A3+T(N)*(A4+T(N)*A5))))
     1               +S(N)*(B0+T(N)*(B1+T(N)
     1               *(B2+T(N)*(B3+T(N)*B4))))+D0*S(N)**2
     +               +S3H(N)*(C0+T(N)*(C1+C2*T(N))) )
     1               /(1.-P/(P*(
     1               H0+T(N)*(H1+T(N)*(H2+T(N)*H3))
     1               +S(N)*(AI0+T(N)*(AI1+AI2*T(N)))+AJ0*S3H(N)
     1               +(AK0+T(N)*(AK1+T(N)*AK2)
     1               +S(N)*(AM0+T(N)*(AM1+T(N)*AM2)))*P)+
     1               E0+T(N)*(E1+T(N)*(E2+T(N)*(E3+T(N)*E4)))
     1               +S(N)*(F0+T(N)*(F1+T(N)*(F2+T(N)*F3)))
     1               +S3H(N)*(G0+T(N)*(G1+G2*T(N)))))
!!!                print *,'T,S,rho = ',t(n),s(n),rh(n)
            end if
 200    CONTINUE

        RETURN
        END

        SUBROUTINE ADISIT(TH,SH,PA,tpo,ie,je)
        DIMENSION TH(IE,JE),SH(IE,JE),TPO(IE,JE)
C       TRANSFORMATION FROM POTENTIAL TO IN SITU DENSITY
C       ACCORDING BRYDEN DSR 20, 401-408 (GILL P.602)
C       WHICH GIVES THE INVERSE TRANSFORMATION
C       FOR AN APPROXIMATE VALUE, ALL TERMS LINEAR IN T ARE TAKEN
C       AFTER THAT ONE NEWTON STEP
C       FOR THE CHECK VALUE 8.4678516     THE ACCURACY IS 0.2 MIKROKELVIN
CCC***CHANGE BY SSD***
C PA SHOULD NOT BE DIVIDED BY 100 IN THE PRESENT VERSION
        PR=PA
        A1=3.6504 E-4
        A2=8.3198 E-5
        A3=5.4065E-7
        A4=4.0274 E-9
        B1=1.7439E-5
        B2=2.9778E-7
        C1=8.9309E-7
        C2=3.1628 E-8
        C3=2.1987E-10
        D=4.1057 E-9
        E1=1.6056 E-10
        E2=5.0484 E-12

C       TH(1,1)=8.4678516
C       SH(1,1)= 25.
C       PR=1000.


        DO 1 J=1,JE
            DO 1 I=1,IE
                if ( sh(i,j).lt.1e33 .and. th(i,j).lt.1e33 ) then
                    S=SH(I,J)
                    TPO(I,J)=TH(I,J)
                    TH(I,J)=(TH(I,J)+A1*PR+B1*PR*(S-35.)+C1*PR**2
     1                   -D*PR**2*(S-35.)-E1*PR**3)
     1                   /(1.-A2*PR+B2*PR*(S-35.)+C2*PR**2-E2*PR**3)
                end if
1       CONTINUE
        DO 2 J=1,JE
            DO 2 I=1,IE
                if ( sh(i,j).lt.1e33 .and. th(i,j).lt.1e33 ) then
                    S = SH(I,J)
                    T=TH(I,J)
                    FNE=T-PR*(A1+A2*T-A3*T**2+A4*T**3)-PR*(S-35.)*(B1-B2
     +                   *T)-PR**2*(C1-C2*T+C3*T**2) +D*(S-35.)*PR**2-PR
     +                   **3*(-E1+E2*T)-TPO(I,J)
                    FST=1.-PR*(A2-2.*A3*T+3.*A4*T**2) +PR*(S-35.)*B2
     1                   +PR**2*(C2-2.*C3*T) -E2*PR**3
                    TH(I,J)=TH(I,J)-FNE/FST
C                   IF(I+J.EQ.2) PRINT*,'NEWTON ', FNE,FST 
!!!                    print *,'th was, is ',tpo(i,j),th(i,j),i,j
                end if
2       CONTINUE
        RETURN
        END
