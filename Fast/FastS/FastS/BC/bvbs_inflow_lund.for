c***********************************************************************
c     $Date: 2013-08-26 16:00:23 +0200 (lun. 26 août 2013) $
c     $Revision: 35 $
c     $Author: IvanMary $
c***********************************************************************
      subroutine bvbs_inflow_lund(idir,lrhs, neq_mtr,
     &                            param_int, ind_loop,
     &                            param_real, c4,c5,c6,
     &                            ventijk, tijk, rop,
     &                            ro_inflow, ro_planlund, lund_param,
     &                            size_data, inc_bc, size_work) 
c***********************************************************************
c_U   USER : PECHIER
c
c     ACT
c     Paroi glissante
c     VAL
c_V    Optimisation NEC
c
c     COM
c_C    MODIFIER bvas3.f (passage de ird1,ird2a,ird2b ?????)
c***********************************************************************
      implicit none


#include "FastS/param_solver.h"

      INTEGER_E idir,lrhs, neq_mtr, ind_loop(6), param_int(0:*)
      INTEGER_E size_data,inc_bc(3), size_work

      REAL_E ro_inflow(  size_data , param_int(NEQ) )
      REAL_E ro_planlund(size_data , param_int(NEQ) )

      REAL_E rop    (param_int(NDIMDX     ), param_int(NEQ)      )
      REAL_E ventijk(param_int(NDIMDX_VENT), param_int(NEQ_VENT) )
      REAL_E tijk   (param_int(NDIMDX_MTR ), neq_mtr             )
      REAL_E state(param_int(NEQ))
      REAL_E c4,c5,c6, param_real(0:*), lund_param(5)

C...  Contient les donnees CGNS pour l injection subsonique:
      REAL_E d0x(size_data),d0y(size_data),d0z(size_data),pa(size_data),
     & ha(size_data),nue(size_data)

C Var local
      INTEGER_E l,lij,lr,lp,i,j,k,l1,l2,ic,jc,kc,kc_vent,ldp,lmtr,l0,
     & incj, inck,indbci,li,ijkplanrec,idirlund,ijk_amor,kshift,jshift,
     & ishift,ci_amor,cj_amor,ck_amor,nijk,iamor,jamor

      REAL_E ro,u,v,w,t,nut,c6inv,c0,c1,c2,c3,roe,rue,rve,rwe,ete,
     & ci_mtr,cj_mtr,ck_mtr,ck_vent,c_ale,tcx,tcy,tcz,
     & qref1,qref2,qref3,qref4,qref5,r,p,c,ci,snorm, gamm1,
     & gamm1_1, cvinv,
     & sni,tn,qn,qen,eigv1,eigv2,eigv3,eigv4,
     & eigv5,qvar1,qvar2,qvar3,qvar4,qvar5,svar1,svar2,svar3,
     & svar4,svar5,rvar1,rvar2,rvar3,rvar4,rvar5,
     & roext,ruext,rvext,rwext,etext,roint,ruint,rvint,rwint,etint,
     & s_1,roi,rui,rvi,rwi,eti, tnx,tny, ri, roinv, sn, roe_inv,
     & mach, pref, roi0, ru,clund,amor

#include "FastS/formule_param.h"
#include "FastS/formule_mtr_param.h"
#include "FastS/formule_vent_param.h"

      indbci(j_1,k_1) = 1 + (j_1-inc_bc(2)) + (k_1-inc_bc(3))*inc_bc(1)

c......determine la forme des tableuz metrique en fonction de la nature du domaine
      !Seule la valeur de k_vent et ck_vent a un sens dans cet appel
      call shape_tab_mtr(neq_mtr, param_int, idir,
     &                   ic,jc,kc,kc_vent,
     &                   ci_mtr,cj_mtr,ck_mtr,ck_vent,c_ale)

c      write(*,*)'idir=', idir,nijk(4),nijk(5),ndimdx
c      write(*,*)'nijk=', nijk
c      write(*,*)'loop=', ind_loop


      gamm1   = param_real(GAMMA) - 1.
      gamm1_1 = 1./gamm1
      cvinv   = 1./param_real(CVINF)

      snorm =-1.
      if(mod(idir,2).eq.0) snorm = 1.

      ijkplanrec= int(lund_param(2))
      clund     = lund_param(3)
      if( int(lund_param(1)).eq.0) clund =0.

      jamor     = int(lund_param(4))

      idirlund  = int(lund_param(5))  ! direction normal paroi

      if(jamor.eq.-1) jamor   = max(param_int(IJKV),param_int(IJKV+1),
     &                              param_int(IJKV+2))

      if (idirlund.eq.1) then
          ijk_amor = param_int(IJKV)
          ci_amor  = 1
          if(idir.eq.3.or.idir.eq.4) then 
             nijk    = param_int(IJKV+2)
             kshift  = 1.
          endif
          if(idir.eq.5.or.idir.eq.6) then
             nijk   = param_int(IJKV+1)
             jshift = 1.
          endif
      elseif(idirlund.eq.2) then
          ijk_amor = param_int(IJKV+1)
          cj_amor  = 1
          if(idir.eq.1.or.idir.eq.2) then 
                nijk   = param_int(IJKV+2)
                kshift = 1.
          endif
          if(idir.eq.5.or.idir.eq.6) then 
                nijk   = param_int(IJKV)
                ishift = 1.
          endif
      else
          ijk_amor = param_int(IJKV+2)
          ck_amor  = 1
          if(idir.eq.1.or.idir.eq.2) then 
                nijk   = param_int(IJKV+1)
                jshift = 1.
          endif
          if(idir.eq.3.or.idir.eq.4) then 
                nijk   = param_int(IJKV)
                ishift = 1.
          endif
      endif



      c0   = 1./c6
      c1   =-(c4 + c5)*c0
      c2   =- c6*c0
      c3   = (2.- c5- c4)*c0

      IF (idir.eq.1) THEN

          if(param_int(NEQ).eq.5) then

             do  k = ind_loop(5), ind_loop(6)
             do  j = ind_loop(3), ind_loop(4)

               l    = inddm( ind_loop(2)    , j,  k )
               lr   = inddm( ijkplanrec     , j,  k )
               lmtr = indmtr(ind_loop(2)+1  , j,  k )
               ldp  = indven(ind_loop(2)+1  , j,  k )
               l1   = l + 1
               li   = indbci(j,  k )

#include       "FastS/BC/BCInflow_lund_firstrank.for"

               l0   = l
               l2   = l + 2
               do i = ind_loop(1), ind_loop(2)-1

                  l    = inddm( i , j,  k ) 
#include          "FastS/BC/BC_nextrank.for"
               enddo
             enddo
             enddo


          else

             do k = ind_loop(5), ind_loop(6)
             do j = ind_loop(3), ind_loop(4)

               l    = inddm( ind_loop(2)    , j,  k )
               lr   = inddm( ijkplanrec     , j,  k )
               lmtr = indmtr(ind_loop(2)+1  , j,  k )
               ldp  = indven(ind_loop(2)+1  , j,  k )
               l1   = l  + 1
               li   = indbci(j,  k )

#include       "FastS/BC/BCInflow_lund_firstrank_SA.for"

               l0   = l
               l2   = l + 2
               do  i = ind_loop(1), ind_loop(2)-1
 
                 l    = inddm( i , j,  k ) 
#include        "FastS/BC/BC_nextrank_SA.for"
               enddo   
             enddo
             enddo
           endif !param_int(NEQ)

      ELSEIF (idir.eq.2) THEN

          if(param_int(NEQ).eq.5) then


             do k = ind_loop(5), ind_loop(6)
             do j = ind_loop(3), ind_loop(4)

               l    = inddm( ind_loop(1)    , j,  k )
               lr   = inddm( ijkplanrec     , j,  k )
               lmtr = indmtr(ind_loop(1)    , j,  k )
               ldp  = indven(ind_loop(1)    , j,  k )
               l1   = l  - 1
               li   = indbci(j,  k )
#include       "FastS/BC/BCInflow_lund_firstrank.for"

               l0   = l
               l2   = l - 2
                do i = ind_loop(1)+1, ind_loop(2)

                 l    = inddm(  i , j, k ) 
#include        "FastS/BC/BC_nextrank.for"
                enddo   
             enddo
             enddo

          else

             do k = ind_loop(5), ind_loop(6)
             do j = ind_loop(3), ind_loop(4)

               l    = inddm( ind_loop(1)    , j,  k )
               lr   = inddm( ijkplanrec     , j,  k )
               lmtr = indmtr(ind_loop(1)    , j,  k )
               ldp  = indven(ind_loop(1)    , j,  k )
               l1   = l  - 1
               li   = indbci(j,  k )
#include       "FastS/BC/BCInflow_lund_firstrank_SA.for"
 

               l0   = l
               l2   = l - 2
                do i = ind_loop(1)+1, ind_loop(2)

                 l    = inddm(  i , j, k ) 
#include        "FastS/BC/BC_nextrank_SA.for"
                enddo  
             enddo
             enddo
           endif !param_int(NEQ)


      ELSEIF (idir.eq.3) THEN

          incj = param_int(NIJK)

          if(param_int(NEQ).eq.5) then

             do  k = ind_loop(5), ind_loop(6)
!DEC$ IVDEP
                do i = ind_loop(1), ind_loop(2) 

                  l    = inddm( i ,  ind_loop(4)    , k )
                  lr   = inddm( i ,  ijkplanrec     , k )
                  lmtr = indmtr(i ,  ind_loop(4) +1 , k )
                  ldp  = indven(i ,  ind_loop(4) +1 , k )
                  l1   = l +   incj
                  li   = indbci(i,  k )
#include          "FastS/BC/BCInflow_lund_firstrank.for"
                enddo !i

                do  j = ind_loop(3), ind_loop(4)-1
!DEC$ IVDEP
                  do i = ind_loop(1), ind_loop(2) 

                     l    = inddm( i ,    j            , k )
                     l0   = inddm( i ,  ind_loop(4)    , k )
                     l1   = l0 +   incj
                     l2   = l0 + 2*incj
#include             "FastS/BC/BC_nextrank.for"
                  enddo!i
                enddo !j
             enddo !k

          else

             do  k = ind_loop(5), ind_loop(6)
!DEC$ IVDEP
                do i = ind_loop(1), ind_loop(2) 

                  l    = inddm( i ,  ind_loop(4)    , k )
                  lr   = inddm( i ,  ijkplanrec     , k )
                  lmtr = indmtr(i ,  ind_loop(4) +1 , k )
                  ldp  = indven(i ,  ind_loop(4) +1 , k )
                  l1   = l +   incj
                  li   = indbci(i,  k )
#include          "FastS/BC/BCInflow_lund_firstrank_SA.for"
                enddo !i

                do  j = ind_loop(3), ind_loop(4)-1
!DEC$ IVDEP
                  do i = ind_loop(1), ind_loop(2) 

                     l    = inddm( i ,    j            , k )
                     l0   = inddm( i ,  ind_loop(4)    , k )
                     l1   = l0 +   incj
                     l2   = l0 + 2*incj
#include             "FastS/BC/BC_nextrank_SA.for"
                  enddo!i
                enddo !j
             enddo !k

          endif !param_int(NEQ)

      ELSEIF (idir.eq.4) THEN

          incj = -param_int(NIJK)

          if(param_int(NEQ).eq.5) then

             do  k = ind_loop(5), ind_loop(6)
!DEC$ IVDEP
                do i = ind_loop(1), ind_loop(2) 

                  l    = inddm( i ,  ind_loop(3)  , k )
                  lr   = inddm( i ,  ijkplanrec     , k )
                  lmtr = indmtr(i ,  ind_loop(3)  , k )
                  ldp  = indven(i ,  ind_loop(3)  , k )
                  l1   = l +   incj
                  li   = indbci(i,  k )
#include          "FastS/BC/BCInflow_lund_firstrank.for"
                enddo !i

                do  j = ind_loop(3)+1, ind_loop(4)
!DEC$ IVDEP
                  do i = ind_loop(1), ind_loop(2) 

                     l    = inddm( i ,    j          , k )
                     l0   = inddm( i ,  ind_loop(3)  , k )
                     l1   = l0 +   incj
                     l2   = l0 + 2*incj
#include             "FastS/BC/BC_nextrank.for"
                  enddo!i
                enddo !j
             enddo !k

          else

             do  k = ind_loop(5), ind_loop(6)
!DEC$ IVDEP
                do i = ind_loop(1), ind_loop(2) 

                  l    = inddm( i ,  ind_loop(3)  , k )
                  lr   = inddm( i ,  ijkplanrec     , k )
                  lmtr = indmtr(i ,  ind_loop(3)  , k )
                  ldp  = indven(i ,  ind_loop(3)  , k )
                  l1   = l +   incj
                  li   = indbci(i,  k )
#include          "FastS/BC/BCInflow_lund_firstrank_SA.for"
                enddo !i

                do  j = ind_loop(3)+1, ind_loop(4)
!DEC$ IVDEP
                  do i = ind_loop(1), ind_loop(2) 

                     l    = inddm( i ,    j          , k )
                     l0   = inddm( i ,  ind_loop(3)  , k )
                     l1   = l0 +   incj
                     l2   = l0 + 2*incj
#include             "FastS/BC/BC_nextrank_SA.for"
                  enddo!i
                enddo !j
             enddo !k

          endif !param_int(NEQ)


      ELSEIF (idir.eq.5) THEN

          inck = param_int(NIJK)*param_int(NIJK+1)

          if(param_int(NEQ).eq.5) then

             do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
               do  i = ind_loop(1), ind_loop(2)

                  l    = inddm( i , j,  ind_loop(6)   )
                  lr   = inddm( i , j,  ijkplanrec    )
                  lmtr = indmtr(i , j,  ind_loop(6)+1 )
                  ldp  = indven(i , j,  ind_loop(6)+1 )
                  l1   = l +   inck
                  li   = indbci(i,  j )
#include        "FastS/BC/BCInflow_lund_firstrank.for"
               enddo
             enddo

             do  k = ind_loop(5), ind_loop(6)-1
                do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
                   do  i = ind_loop(1), ind_loop(2)

                     l    = inddm( i , j,  k          )
                     l0   = inddm( i , j, ind_loop(6) )
                     l1   = l0 +   inck
                     l2   = l0 + 2*inck
#include             "FastS/BC/BC_nextrank.for"
                   enddo
               enddo
             enddo

          else

             do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
               do  i = ind_loop(1), ind_loop(2)

                  l    = inddm( i , j,  ind_loop(6)   )
                  lr   = inddm( i , j,  ijkplanrec    )
                  lmtr = indmtr(i , j,  ind_loop(6)+1 )
                  ldp  = indven(i , j,  ind_loop(6)+1 )
                  l1   = l +   inck
                  li   = indbci(i,  j )
#include        "FastS/BC/BCInflow_lund_firstrank_SA.for"
               enddo
             enddo

             do  k = ind_loop(5), ind_loop(6)-1
                do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
                   do  i = ind_loop(1), ind_loop(2)

                     l    = inddm( i , j,  k          )
                     l0   = inddm( i , j, ind_loop(6) )
                     l1   = l0 +   inck
                     l2   = l0 + 2*inck
#include             "FastS/BC/BC_nextrank_SA.for"
                   enddo
               enddo
             enddo

          endif !param_int(NEQ)


      ELSE 

          inck = -param_int(NIJK)*param_int(NIJK+1)

          if(param_int(NEQ).eq.5) then

             do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
               do  i = ind_loop(1), ind_loop(2)

                  l    = inddm( i , j,  ind_loop(5)   )
                  lr   = inddm( i , j,  ijkplanrec    )
                  lmtr = indmtr(i , j,  ind_loop(5)   )
                  ldp  = indven(i , j,  ind_loop(5)   )
                  l1   = l +   inck
                  li   = indbci(i,  j )
#include        "FastS/BC/BCInflow_lund_firstrank.for"
               enddo
             enddo

             do  k = ind_loop(5)+1, ind_loop(6)
                do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
                   do  i = ind_loop(1), ind_loop(2)

                     l    = inddm( i , j,  k          )
                     l0   = inddm( i , j, ind_loop(5) )
                     l1   = l0 +   inck
                     l2   = l0 + 2*inck
#include             "FastS/BC/BC_nextrank.for"
                   enddo
               enddo
             enddo

          else

             do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
               do  i = ind_loop(1), ind_loop(2)

                  l    = inddm( i , j,  ind_loop(5)   )
                  lr   = inddm( i , j,  ijkplanrec    )
                  lmtr = indmtr(i , j,  ind_loop(5)   )
                  ldp  = indven(i , j,  ind_loop(5)   )
                  l1   = l +   inck
                  li   = indbci(i,  j )
#include        "FastS/BC/BCInflow_lund_firstrank_SA.for"
               enddo
             enddo

             do  k = ind_loop(5)+1, ind_loop(6)
                do  j = ind_loop(3), ind_loop(4)
!DEC$ IVDEP
                   do  i = ind_loop(1), ind_loop(2)

                     l    = inddm( i , j,  k          )
                     l0   = inddm( i , j, ind_loop(5) )
                     l1   = l0 +   inck
                     l2   = l0 + 2*inck
#include             "FastS/BC/BC_nextrank_SA.for"
                   enddo
               enddo
             enddo

          endif !param_int(NEQ)

      ENDIF !idir

      END
