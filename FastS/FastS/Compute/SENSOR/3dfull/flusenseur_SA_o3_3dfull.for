c***********************************************************************
c     $Date: 2013-08-26 16:00:23 +0200 (lun. 26 août 2013) $
c     $Revision: 64 $
c     $Author: IvanMary $
c***********************************************************************
      subroutine flusenseur_SA_o3_3dfull(ndom, ithread,
     &                 param_int, param_real,
     &                 ind_dm, ind_loop, ijkv_bloc, ijkv_cache,
     &                 synchro_send_sock, synchro_send_th,
     &                 synchro_receive_sock, synchro_receive_th,
     &                 ibloc , jbloc , kbloc ,
     &                 icache, jcache, kcache,
     &                 rop, drodm, wig,
     &                 venti, ventj, ventk,
     &                 ti, tj, tk, vol, xmut)
c***********************************************************************
c_U   USER : PECHIER
c
c     ACT
c_A    Appel du calcul des flux explicites
c
c     VAL
c_V    gaz parfait monoespece
c_V    processeur domaine
c_V    steady/unsteady
c
c     INP
c_I    tijk     : vecteur normale aux facettes des mailles
c_I    ventijk     : vitesses d entrainement aux facettes preced.
c_I    qm,qp    : etats droit et gauche aux interfaces d une maille
c
c     LOC
c_L    flu      : flux convectifs dans une direction de maillage
c
c     I/O
c_/    drodm    : increment de la solution
c***********************************************************************
      implicit none

      real souszero
      parameter(souszero=-1e-12)

#include "FastS/param_solver.h"

      INTEGER_E ndom, ithread, nptpsi,
     & icache, jcache, kcache,
     & ibloc, jbloc, kbloc, 
     & ijkv_bloc(3), ijkv_cache(3),ind_loop(6),ind_dm(6),
     & synchro_send_sock(3),synchro_send_th(3),
     & synchro_receive_sock(3), synchro_receive_th(3), param_int(0:*)

      REAL_E  xmut( param_int(NDIMDX) )
      REAL_E   rop( param_int(NDIMDX)     * param_int(NEQ)     )
      REAL_E drodm( param_int(NDIMDX)     * param_int(NEQ)     )
      REAL_E   wig( param_int(NDIMDX)     * 3                  )
      REAL_E venti( param_int(NDIMDX_VENT)* param_int(NEQ_VENT))
      REAL_E ventj( param_int(NDIMDX_VENT)* param_int(NEQ_VENT))
      REAL_E ventk( param_int(NDIMDX_VENT)* param_int(NEQ_VENT))

      REAL_E  ti( param_int(NDIMDX_MTR) * param_int(NEQ_IJ) ),
     &        tj( param_int(NDIMDX_MTR) * param_int(NEQ_IJ) ),
     &        tk( param_int(NDIMDX_MTR) * param_int(NEQ_K ) )
      REAL_E vol( param_int(NDIMDX_MTR) )

      REAL_E param_real(0:*)

C Var loc
      INTEGER_E inc,incmax,l,lt,i,j,k,incmax2,nm,nm2,np,
     & l0,lt0,inci,incj,inck,ci,cj,lij,ltij,inci_mtr, incj_mtr,
     & inck_mtr,icorr,jcorr,ls,v1,v2,v3,v4,v5,v6,wig_i,wig_j,wig_k,
     & lt200,lt100,lt010,lt210,lt020,lt110,lt002,lt012,lt102,lt001,
     & lt021,lt201,lt120,lvo,lvo200,lvo020,lvo002,vslp,lvol,lvor,ir,il,
     & l200,l100,l010,l020,l110,l101,l011,v1mtr,v2mtr,v3mtr,
     & l001,l002,l210,l220,l201,l202,l021,l022,l120,l102,l012

      REAL_E c1,c2,c3,c4,c5,c6,c4sa,c5sa,c6sa,si,sj,sk,qm,qp,
     & tcx,tcy,tcz,tc,r1,h1,rou1,rov1,row1,r2,h2,rou2,rov2,row2,
     & gam,gam1,gam2,gam3,gam4,qn1,qn2,u,tdu,p1p2,roref,uref,tam,tam1,
     & qm1,qm2,qm3,qm4,qm5,qm6,qp1,qp2,qp3,qp4,qp5,qp6,mut1,mut2,
     & flu1,flu2,flu3,flu4,flu5,flu6,p1,p2,qen,sigma_1,ck_vent,
     & div,f1,f2,f3,f4,f5,f6,fv,fv5,volinv,test,cmus1,temp01,coesut,
     & tix,tiy,tiz,tix1,tiy1,tiz1,tjx,tjy,tjz,tjx1,tjy1,tjz1,tkx,
     & tky,tkz,tkx1,tky1,tkz1,xmutvol,cvisq,rgp,son,c,opt0,
     & gradU_nx,gradU_ny,gradU_nz, gradV_nx,gradV_ny,gradV_nz,
     & gradW_nx,gradW_ny,gradW_nz, gradT_nx,gradT_ny,gradT_nz,
     & delp,delm,delq,slq,slp,roff,tmin_1,du,dv,dw,dp,dqn,s_1,nx,ny,nz,
     & qn,r,v,w,h,q,r_1,psiroe, xktvol, xmulam, xmutur, xmutot

#include "FastS/formule_param.h"
#include "FastS/formule_mtr_param.h"

      !limiteur 'minmod'

CC!DIR$ ASSUME_ALIGNED xmut: CACHELINE

      if(ind_loop(1).gt.ind_loop(2)) return 
      if(ind_loop(3).gt.ind_loop(4)) return 
      if(ind_loop(5).gt.ind_loop(6)) return

      inci = 1
      incj = param_int(NIJK)
      inck = param_int(NIJK)*param_int(NIJK+1)

      inci_mtr = param_int(NIJK_MTR)
      incj_mtr = param_int(NIJK_MTR+1)
      inck_mtr = param_int(NIJK_MTR+2)

      !metric
      lt  = indmtr(1 , 1, 1)
      lvo = lt
      tcx = ti(lt)
      tcy = tj(lt)
      tcz = tk(lt) 
      si      = abs (tcx)
      sj      = abs (tcy)
      sk      = abs (tcz)
      volinv  = 0.5/vol(lvo)

      !-----Variables physiques
      gam    = param_real( GAMMA )
      rgp    = param_real( CVINF )*(gam-1.)  !Cv(gama-1)= R (gas parfait)
      gam1   = gam/(gam-1.)
      gam2   = 1./gam
      gam3    = gam1/ param_real( PRANDT )*rgp
      gam4    = gam1/ param_real( PRANDT_TUR )*rgp

      cmus1  =    param_real( CS )
      temp01 = 1./param_real( TEMP0)
      coesut =    param_real( XMUL0) * (1.+cmus1*temp01)
      sigma_1 =1./SA_SIGMA

      roref= param_real( ROINF)
      uref = param_real( VINF )

      psiroe= param_real( PSIROE )
      tmin_1= 100./param_real( TINF )!!si T< 0.01Tinf, alors limiteur null

      c1     = 0.02*uref         ! modif suite chant metrique et suppression tc dans flux final
      c2     = 0.02/(uref*roref) ! modif suite chant metrique et suppression tc dans flux final
      c3     = -2.
      opt0   = param_int(SENSORTYPE)

      !    roff MUSCL
      c6     = 1./6.
      c4     = 5.*c6
      c5     = 2.*c6
      c6     =-1.*c6

c      c7     = c4/c5

      cvisq = 1./3

      icorr = 0 !correction indice boucle i pour traiter l'interface ind_loop(2)+1 si necessaire
      jcorr = 0 
      If(ibloc .eq.ijkv_bloc(1) .and.synchro_receive_sock(1).eq.0.and.
     &   icache.eq.ijkv_cache(1).and.synchro_receive_th(1).eq.0) icorr=1
      If(jbloc.eq.ijkv_bloc(2).and.synchro_receive_sock(2).eq.0.and.
     &   jcache.eq.ijkv_cache(2).and.synchro_receive_th(2).eq.0) jcorr=1

      v1 = 0
      v2 =   param_int(NDIMDX)
      v3 = 2*param_int(NDIMDX)
      v4 = 3*param_int(NDIMDX)
      v5 = 4*param_int(NDIMDX)
      v6 = 5*param_int(NDIMDX)

      v1mtr =   0
      v2mtr =   param_int(NDIMDX_MTR)
      v3mtr = 2*param_int(NDIMDX_MTR)

      wig_i = v1
      wig_j = v2
      wig_k = v3



#include "FastS/Compute/pragma_align.for"

      DO k = ind_loop(5), ind_loop(6)
       DO j = ind_loop(3), ind_loop(4)

#include "FastS/Compute/loopI_begin.for"                  
            l0= l  - inck                   
#include    "FastS/Compute/SENSOR/3dfull/fluFaceEuler_o3_3dfull_k.for"  
#include    "FastS/Compute/SENSOR/3dfull/fluFaceSA_o3_3dfull_k.for"   
#include    "FastS/Compute/SA/fluvisq_3dfull_k.for"          
#include    "FastS/Compute/SA/fluvisq_SA_3dfull_k.for"             
#include    "FastS/Compute/SA/assemble_drodm_plus_vec1.for"  
          enddo                             

#include  "FastS/Compute/loopI_begin.for"
            l0= l  - incj 
#include    "FastS/Compute/SENSOR/3dfull/fluFaceEuler_o3_3dfull_j.for"
#include    "FastS/Compute/SENSOR/3dfull/fluFaceSA_o3_3dfull_j.for"
#include    "FastS/Compute/SA/fluvisq_3dfull_j.for"
#include    "FastS/Compute/SA/fluvisq_SA_3dfull_j.for"
#include    "FastS/Compute/SA/assemble_drodm_plus_vec1.for"
          enddo

#include "FastS/Compute/loopI_begin.for"
            l0= l  - inci
#include    "FastS/Compute/SENSOR/3dfull/fluFaceEuler_o3_3dfull_i.for"
#include    "FastS/Compute/SENSOR/3dfull/fluFaceSA_o3_3dfull_i.for"
#include    "FastS/Compute/SA/fluvisq_3dfull_i.for"
#include    "FastS/Compute/SA/fluvisq_SA_3dfull_i.for"
#include    "FastS/Compute/SA/assemble_drodm_plus_vec1.for"
          enddo

          if(icorr.eq.1) then !flux manquant en I
             i   = ind_loop(2) + 1
             l   = inddm(  i, j, k)
             lt  = indmtr( i, j, k)
#include    "FastS/Compute/SENSOR/3dfull/fluFaceEuler_o3_3dfull_i.for"
#include    "FastS/Compute/SENSOR/3dfull/fluFaceSA_o3_3dfull_i.for"
#include    "FastS/Compute/SA/fluvisq_3dfull_i.for"
#include    "FastS/Compute/SA/fluvisq_SA_3dfull_i.for"
              ls = l -inci
#include    "FastS/Compute/SA/flu_send_scater_vec1.for"
          endif !
       ENDDO !do j

       !Complement fluj en Jmax
       If(jcorr.eq.1) then

         j    = ind_loop(4)+1

#include "FastS/Compute/loopI_begin.for"

#include       "FastS/Compute/SENSOR/3dfull/fluFaceEuler_o3_3dfull_j.for"
#include       "FastS/Compute/SENSOR/3dfull/fluFaceSA_o3_3dfull_j.for"
#include       "FastS/Compute/SA/fluvisq_3dfull_j.for"
#include       "FastS/Compute/SA/fluvisq_SA_3dfull_j.for"
               ls = l -incj
#include       "FastS/Compute/SA/flu_send_scater_vec1.for"
         enddo
        Endif

      ENDDO !do k
                                                                       
                                                                       
      !Complement fluk en Kmax                                         
      If( kbloc.eq.ijkv_bloc(3).and.synchro_receive_sock(3).eq.0.and.  
     &   kcache.eq.ijkv_cache(3).and.synchro_receive_th(3).eq.0) then  
                                                                       
        k    = ind_loop(6)+1               
        do j = ind_loop(3),ind_loop(4)     
                                           
#include "FastS/Compute/loopI_begin.for"                 
                                           
#include   "FastS/Compute/SENSOR/3dfull/fluFaceEuler_o3_3dfull_k.for"  
#include   "FastS/Compute/SENSOR/3dfull/fluFaceSA_o3_3dfull_k.for"   
#include   "FastS/Compute/SA/fluvisq_3dfull_k.for"          
#include   "FastS/Compute/SA/fluvisq_SA_3dfull_k.for"             
            ls = l -inck                   
#include    "FastS/Compute/SA/flu_send_scater_vec1.for"     
          enddo                            
        enddo                              
      Endif                                
      end

