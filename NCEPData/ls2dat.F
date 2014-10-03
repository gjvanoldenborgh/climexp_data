        program ls2dat
        implicit none
        integer ls(720,360),i,j
#include "recfac.h"
        
        open (11,file='rtg_sst_ls.dat',status='old')
C
C       Read in land sea tags (0 for ocean; 3 for land)
C
        read (11,'(80i1)') ls
        close(11)
        open(11,file='rtg_sst_ls.grd',access='direct',form='unformatted'
     +       ,recl=720*360*recfa4)
        write(11,rec=1) ((real(ls(i,j)/3),i=1,720),j=1,360)
        close(11)
        end
