c***********************************************************************
c     $Date: 2010-07-12 18:57:35 +0200 (Mon, 12 Jul 2010) $
c     $Revision: 40 $
c     $Author: IvanMary $
c***********************************************************************
      subroutine invlu_l_SA(ndom, param_int, param_real,
     &                      ind_loop,
     &                      drodm_in,drodm_out,rop,
     &                      ti,tj,tk,
     &                      coe)
c***********************************************************************
c                              O N E R A
c
c_D   DATE_C/M : 1996
c
c_U   USER : DARRACQ 
c
c     ACT
c_A    Construction et inversion d une matrice inferieure tetradiagonale par blocs
c      par une methode vectorisable.
c     VAL
c_V    Steady
c_V    Formulation LCI+Jameson-Turkel
c
c     INP
c_I    ndom,neq,drodm,coe
c
c     OUT
c     I/O
c_/    drodm,drodm
c***********************************************************************
      implicit none

#include "FastS/param_solver.h"

      INTEGER_E ndom, ind_loop(6), param_int(0:*)
 
      REAL_E  param_real(0:*)
      REAL_E drodm_in(param_int(NDIMDX),param_int(NEQ)),
     &       drodm_out(param_int(NDIMDX),param_int(NEQ)),
     &       coe(param_int(NDIMDX),param_int(NEQ_COE)),
     &       rop(param_int(NDIMDX),param_int(NEQ))
      REAL_E ti(param_int(NDIMDX_MTR),param_int(NEQ_IJ)),
     &       tj(param_int(NDIMDX_MTR),param_int(NEQ_IJ)),
     &       tk(param_int(NDIMDX_MTR),param_int(NEQ_K))

c Var loc
      INTEGER_E  inci,incj,inck,l,i,j,k,kdmax,kd,lmax,ll,ndo,
     & kddeb,kdfin,ipas,kfin,kdeb,jfin,jdeb,ifin,ideb,
     & l1,l2,lt,lt1,lt2,ls,l1s,incis,incjs,incks,lij,ltij,
     & inci2_mtr,incj2_mtr,inck2_mtr,inci_mtr,incj_mtr,inck_mtr

      REAL_E gam2,gam1,gamm1,cp,xal,diag,
     & b11,b12,b13,b14,b15,b21,b22,b23,b24,b25,b31,b32,b33,b34,b35,b41,
     & b42,b43,b44,b45,b51,b52,b53,b54,b55,
     & b1,b2,b3,b4,b5,b6,
     & signe,r,u,v,w,t,q2,h,ph2,qn,tcx,tcy,tcz

#include "FastS/formule_param.h"
#include "FastS/formule_mtr_param.h"

      gam1    = param_real(GAMMA)
      gamm1   = gam1 - 1.
      cp      = param_real(GAMMA)*param_real(CVINF)
      gam2    = gamm1-1.
 
       inci      = 1
       incj      = param_int(NIJK)
       inck      = param_int(NIJK)*param_int(NIJK+1)
       inci_mtr  = param_int(NIJK_MTR)
       incj_mtr  = param_int(NIJK_MTR+1)
       inck_mtr  = param_int(NIJK_MTR+2)
       inci2_mtr = 0
       incj2_mtr = 0
       inck2_mtr = 0
       ipas      = 1
       signe     = 0.5
      
        kdeb  = ind_loop(5)
        jdeb  = ind_loop(3)
        ideb  = ind_loop(1)
        kfin  = ind_loop(6)
        jfin  = ind_loop(4)
        ifin  = ind_loop(2)

        incis = inci
        incjs = incj
        incks = inck
 
      IF(param_int(ITYPZONE).eq.0) THEN !domaine 3d general


      !!! coin (ideb,jdeb,kdb)
        l = inddm(ideb,jdeb,kdeb)
        ls = l
#include "FastS/Compute/LU/lu_dinv_IO_SA.for"

        !!! ligne (jdeb,kdeb) dans le plan kdeb
        lij  =       inddm( ideb+ipas, jdeb, kdeb) -1
        ltij = lij - indmtr(ideb+ipas, jdeb, kdeb) +1
        do l = lij+1, lij+1 + ifin-ideb -ipas

          ls  = l
          lt  = l  - ltij
          xal = coe(l,1)*signe

#include "FastS/Compute/LU/lu_i_3dfull_SA.for"
#include "FastS/Compute/LU/mjr_drodm_IO_SA.for"
#include "FastS/Compute/LU/lu_dinv_SA.for"
        enddo

        do j= jdeb+ipas,jfin,ipas

          !!! ligne (ideb,kdeb) dans le plan kdeb
          lij  =       inddm( ideb, j, kdeb) -1
          ltij = lij - indmtr(ideb, j, kdeb) +1
!$OMP simd
          do l = lij+1, lij+1 + ifin-ideb
            lt = l  - ltij
            ls = l

            xal    = coe(l,1)*signe
#include "FastS/Compute/LU/lu_j_3dfull_SA.for"
#include "FastS/Compute/LU/mjr_drodm_IO_SA.for"
          enddo

          l  =  inddm(ideb,j,kdeb)
          ls = l
#include  "FastS/Compute/LU/lu_dinv_SA.for"
          lij  =       inddm( ideb+ipas, j, kdeb) -1
          ltij = lij - indmtr(ideb+ipas, j, kdeb) +1
          do l = lij+1, lij+1 + ifin-ideb-ipas
            ls = l
            lt = l  - ltij

            xal    = coe(l,1)*signe

#include    "FastS/Compute/LU/lu_i_3dfull_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_SA.for"
#include    "FastS/Compute/LU/lu_dinv_SA.for"
          enddo
        enddo
        !!! plan kdeb termine

        !!! le domaine sans les mailles du bord
        do  k= kdeb+ipas,kfin,ipas

          lij  =       inddm( ideb, jdeb, k) -1
          ltij = lij - indmtr(ideb, jdeb, k) +1
!$OMP simd
          do l = lij+1, lij+1 + ifin-ideb
             
             lt = l  - ltij
             ls = l
             xal= coe(l,1)*signe

#include    "FastS/Compute/LU/lu_k_3dfull_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_IO_SA.for"
          enddo
          l  =  inddm(ideb,jdeb,k)
          lt = indmtr(ideb,jdeb,k)
          ls = l
          xal= coe(l,1)*signe
#include "FastS/Compute/LU/lu_dinv_SA.for"
          !!! Fin plan jdeb 
          lij  =       inddm( ideb+ipas, jdeb, k) -1
          ltij = lij - indmtr(ideb+ipas, jdeb, k) +1
          do l = lij+1, lij+1 + ifin -ideb-ipas
             
             lt = l  - ltij
             ls = l
             xal= coe(l,1)*signe

#include    "FastS/Compute/LU/lu_i_3dfull_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_SA.for"
#include    "FastS/Compute/LU/lu_dinv_SA.for"
          enddo


          do  j= jdeb+ipas,jfin,ipas

            lij  =       inddm( ideb, j, k) -1
            ltij = lij - indmtr(ideb, j, k) +1
!$OMP simd
            do l = lij+1, lij+1 + ifin-ideb

              lt = l  - ltij
              ls = l
              xal= coe(l,1)*signe

#include      "FastS/Compute/LU/lu_k_3dfull_SA.for"
#include      "FastS/Compute/LU/mjr_drodm_IO_SA.for"
#include      "FastS/Compute/LU/lu_j_3dfull_SA.for"
#include      "FastS/Compute/LU/mjr_drodm_SA.for"
            enddo
            l  =  inddm(ideb,j,k)
            lt = indmtr(ideb,j,k)
            ls = l
            xal= coe(l,1)*signe
#include    "FastS/Compute/LU/lu_dinv_SA.for"

            lij  =       inddm( ideb+ipas, j, k) -1
            ltij = lij - indmtr(ideb+ipas, j, k) +1
            do l = lij+1, lij+1 + ifin-ideb-ipas
              
               lt = l  - ltij
               ls = l
               xal= coe(l,1)*signe

#include       "FastS/Compute/LU/lu_i_3dfull_SA.for"
#include       "FastS/Compute/LU/mjr_drodm_SA.for"
#include       "FastS/Compute/LU/lu_dinv_SA.for"
             enddo
          enddo
        enddo

      ELSEIF(param_int(ITYPZONE).eq.1) THEN !maillage 3d k homogene_SA:

      !!! on parcourt le domaine en 7 passes pour traiter les bord sans mettre a zero le drodm sur maille fictive

      !!! coin (ideb,jdeb,kdb)
        l = inddm(ideb,jdeb,kdeb)
        ls = l
#include "FastS/Compute/LU/lu_dinv_IO_SA.for"

        !!! ligne (jdeb,kdeb) dans le plan kdeb
        lij  =       inddm( ideb+ipas, jdeb, kdeb) -1
        ltij = lij - indmtr(ideb+ipas, jdeb, kdeb) +1
        do l = lij+1, lij+1 + ifin-ideb -ipas

          ls  = l
          lt  = l  - ltij
          xal = coe(l,1)*signe

#include "FastS/Compute/LU/lu_i_3dhomogene_SA.for"
#include "FastS/Compute/LU/mjr_drodm_IO_SA.for"
#include "FastS/Compute/LU/lu_dinv_SA.for"
        enddo

        do j= jdeb+ipas,jfin,ipas

          !!! ligne (ideb,kdeb) dans le plan kdeb
          lij  =       inddm( ideb, j, kdeb) -1
          ltij = lij - indmtr(ideb, j, kdeb) +1
!$OMP simd
          do l = lij+1, lij+1 + ifin-ideb
            lt = l  - ltij
            ls = l

            xal    = coe(l,1)*signe
#include "FastS/Compute/LU/lu_j_3dhomogene_SA.for"
#include "FastS/Compute/LU/mjr_drodm_IO_SA.for"
          enddo

          l  =  inddm(ideb,j,kdeb)
          ls = l
#include  "FastS/Compute/LU/lu_dinv_SA.for"
          lij  =       inddm( ideb+ipas, j, kdeb) -1
          ltij = lij - indmtr(ideb+ipas, j, kdeb) +1
          do l = lij+1, lij+1 + ifin-ideb-ipas
            ls = l
            lt = l  - ltij

            xal    = coe(l,1)*signe

#include    "FastS/Compute/LU/lu_i_3dhomogene_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_SA.for"
#include    "FastS/Compute/LU/lu_dinv_SA.for"
          enddo
        enddo
        !!! plan kdeb termine

        !!! le domaine sans les mailles du bord
        do  k= kdeb+ipas,kfin,ipas

          lij  =       inddm( ideb, jdeb, k) -1
          ltij = lij - indmtr(ideb, jdeb, k) +1
!$OMP simd
          do l = lij+1, lij+1 + ifin-ideb
             
             lt = l  - ltij
             ls = l
             xal= coe(l,1)*signe

#include    "FastS/Compute/LU/lu_k_3dhomogene_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_IO_SA.for"
          enddo
          l  =  inddm(ideb,jdeb,k)
          lt = indmtr(ideb,jdeb,k)
          ls = l
          xal= coe(l,1)*signe
#include "FastS/Compute/LU/lu_dinv_SA.for"
          !!! Fin plan jdeb 
          lij  =       inddm( ideb+ipas, jdeb, k) -1
          ltij = lij - indmtr(ideb+ipas, jdeb, k) +1
          do l = lij+1, lij+1 + ifin -ideb-ipas
             
             lt = l  - ltij
             ls = l
             xal= coe(l,1)*signe

#include    "FastS/Compute/LU/lu_i_3dhomogene_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_SA.for"
#include    "FastS/Compute/LU/lu_dinv_SA.for"
          enddo


          do  j= jdeb+ipas,jfin,ipas

            lij  =       inddm( ideb, j, k) -1
            ltij = lij - indmtr(ideb, j, k) +1
!$OMP simd
            do l = lij+1, lij+1 + ifin-ideb

              lt = l  - ltij
              ls = l
              xal= coe(l,1)*signe

#include      "FastS/Compute/LU/lu_k_3dhomogene_SA.for"
#include      "FastS/Compute/LU/mjr_drodm_IO_SA.for"
#include      "FastS/Compute/LU/lu_j_3dhomogene_SA.for"
#include      "FastS/Compute/LU/mjr_drodm_SA.for"
            enddo
            l  =  inddm(ideb,j,k)
            lt = indmtr(ideb,j,k)
            ls = l
            xal= coe(l,1)*signe
#include    "FastS/Compute/LU/lu_dinv_SA.for"

            lij  =       inddm( ideb+ipas, j, k) -1
            ltij = lij - indmtr(ideb+ipas, j, k) +1
            do l = lij+1, lij+1 + ifin-ideb-ipas
              
               lt = l  - ltij
               ls = l
               xal= coe(l,1)*signe

#include       "FastS/Compute/LU/lu_i_3dhomogene_SA.for"
#include       "FastS/Compute/LU/mjr_drodm_SA.for"
#include       "FastS/Compute/LU/lu_dinv_SA.for"
             enddo
          enddo
        enddo


      ELSEIF(param_int(ITYPZONE).eq.2) THEN !maillage 3d cart_SAesien


       tcx = ti(1,1)
       tcy = tj(1,1)
       tcz = tk(1,1)
      !!! on parcourt le domaine en 7 passes pour traiter les bord sans mettre a zero le drodm sur maille fictive

      !!! coin (ideb,jdeb,kdb)
        l = inddm(ideb,jdeb,kdeb)
        ls = l
#include "FastS/Compute/LU/lu_dinv_IO_SA.for"

        !!! ligne (jdeb,kdeb) dans le plan kdeb
        lij  =       inddm( ideb+ipas, jdeb, kdeb) -1
        ltij = lij - indmtr(ideb+ipas, jdeb, kdeb) +1
        do l = lij+1, lij+1 + ifin-ideb -ipas

          ls  = l
          lt  = l  - ltij
          xal = coe(l,1)*signe

#include "FastS/Compute/LU/lu_i_3dcart_SA.for"
#include "FastS/Compute/LU/mjr_drodm_IO_SA.for"
#include "FastS/Compute/LU/lu_dinv_SA.for"
        enddo

        do j= jdeb+ipas,jfin,ipas

          !!! ligne (ideb,kdeb) dans le plan kdeb
          lij  =       inddm( ideb, j, kdeb) -1
          ltij = lij - indmtr(ideb, j, kdeb) +1
!$OMP simd
          do l = lij+1, lij+1 + ifin-ideb
            lt = l  - ltij
            ls = l

            xal    = coe(l,1)*signe
#include "FastS/Compute/LU/lu_j_3dcart_SA.for"
#include "FastS/Compute/LU/mjr_drodm_IO_SA.for"
          enddo

          l  =  inddm(ideb,j,kdeb)
          ls = l
#include  "FastS/Compute/LU/lu_dinv_SA.for"
          lij  =       inddm( ideb+ipas, j, kdeb) -1
          ltij = lij - indmtr(ideb+ipas, j, kdeb) +1
          do l = lij+1, lij+1 + ifin-ideb-ipas
            ls = l
            lt = l  - ltij

            xal    = coe(l,1)*signe

#include    "FastS/Compute/LU/lu_i_3dcart_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_SA.for"
#include    "FastS/Compute/LU/lu_dinv_SA.for"
          enddo
        enddo
        !!! plan kdeb termine

        !!! le domaine sans les mailles du bord
        do  k= kdeb+ipas,kfin,ipas

          lij  =       inddm( ideb, jdeb, k) -1
          ltij = lij - indmtr(ideb, jdeb, k) +1
!$OMP simd
          do l = lij+1, lij+1 + ifin-ideb
             
             lt = l  - ltij
             ls = l
             xal= coe(l,1)*signe

#include    "FastS/Compute/LU/lu_k_3dcart_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_IO_SA.for"
          enddo
          l  =  inddm(ideb,jdeb,k)
          lt = indmtr(ideb,jdeb,k)
          ls = l
          xal= coe(l,1)*signe
#include "FastS/Compute/LU/lu_dinv_SA.for"
          !!! Fin plan jdeb 
          lij  =       inddm( ideb+ipas, jdeb, k) -1
          ltij = lij - indmtr(ideb+ipas, jdeb, k) +1
          do l = lij+1, lij+1 + ifin -ideb-ipas
             
             lt = l  - ltij
             ls = l
             xal= coe(l,1)*signe

#include    "FastS/Compute/LU/lu_i_3dcart_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_SA.for"
#include    "FastS/Compute/LU/lu_dinv_SA.for"
          enddo


          do  j= jdeb+ipas,jfin,ipas

            lij  =       inddm( ideb, j, k) -1
            ltij = lij - indmtr(ideb, j, k) +1
!$OMP simd
            do l = lij+1, lij+1 + ifin-ideb

              lt = l  - ltij
              ls = l
              xal= coe(l,1)*signe

#include      "FastS/Compute/LU/lu_j_3dcart_SA.for"
#include      "FastS/Compute/LU/mjr_drodm_IO_SA.for"
#include      "FastS/Compute/LU/lu_k_3dcart_SA.for"
#include      "FastS/Compute/LU/mjr_drodm_SA.for"
            enddo
            l  =  inddm(ideb,j,k)
            lt = indmtr(ideb,j,k)
            ls = l
            xal= coe(l,1)*signe
#include    "FastS/Compute/LU/lu_dinv_SA.for"

            lij  =       inddm( ideb+ipas, j, k) -1
            ltij = lij - indmtr(ideb+ipas, j, k) +1
            do l = lij+1, lij+1 + ifin-ideb-ipas
              
               lt = l  - ltij
               ls = l
               xal= coe(l,1)*signe

#include       "FastS/Compute/LU/lu_i_3dcart_SA.for"
#include       "FastS/Compute/LU/mjr_drodm_SA.for"
#include       "FastS/Compute/LU/lu_dinv_SA.for"
             enddo
          enddo
        enddo



      ELSE !2d_SA

        !!! coin (ideb,jdeb,kdb)
        l = inddm(ideb,jdeb,1)
        ls = l
#include "FastS/Compute/LU/lu_dinv_IO_2d_SA.for"

        !!! ligne (jdeb,kdeb) dans le plan kdeb
        lij  =       inddm( ideb+ipas, jdeb, 1) -1
        ltij = lij - indmtr(ideb+ipas, jdeb, 1) +1
        do l = lij+1, lij+1 + ifin- ideb-ipas

          lt = l  - ltij
          ls = l
          xal= coe(l,1)*signe

#include "FastS/Compute/LU/lu_i_2d_SA.for"
#include "FastS/Compute/LU/mjr_drodm_IO_2d_SA.for"
#include "FastS/Compute/LU/lu_dinv_2d_SA.for"
        enddo

        do j= jdeb+ipas,jfin,ipas

          lij  =       inddm( ideb, j, 1) -1
          ltij = lij - indmtr(ideb, j, 1) +1
!$OMP simd
          do l = lij+1, lij+1 +ifin-ideb

            lt = l  - ltij
            ls = l
            xal= coe(l,1)*signe
 
#include    "FastS/Compute/LU/lu_j_2d_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_IO_2d_SA.for"
          enddo
          !!contribution I en imin
          l      =  inddm(ideb,j,1)
          ls     =  l
#include "FastS/Compute/LU/lu_dinv_2d_SA.for"
          lij  =       inddm( ideb+ipas, j, 1) -1
          ltij = lij - indmtr(ideb+ipas, j, 1) +1
          do l = lij+1, lij+1 + ifin-ideb -ipas

            lt = l  - ltij
            ls = l
            xal= coe(l,1)*signe

#include    "FastS/Compute/LU/lu_i_2d_SA.for"
#include    "FastS/Compute/LU/mjr_drodm_2d_SA.for"
#include    "FastS/Compute/LU/lu_dinv_2d_SA.for"
          enddo
        enddo

      ENDIF
 
      end
