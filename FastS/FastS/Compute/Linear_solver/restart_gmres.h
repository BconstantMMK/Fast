  E_Float value = 0., sum_value = 0.; E_Float normL2 = 0., normL2_sum = 0.;
E_Int mjrnewton = 0;
  // norm L2 krylov pour openmp
  for (E_Int th = 0; th < Nbre_thread_actif; th++) { normL2_sum += ipt_norm_kry[th];}

  //Normalisation de V0 + initialisation de G = Beta x e1
  normL2_sum = sqrt(normL2_sum);
  ipt_VectG[0] = normL2_sum;

// Pour verif Ax-b
//E_Float save = normL2_sum;

    //iptkrylov[nd] = iptkrylov[nd] / normL2_sum
    nd_current =0;
    for (E_Int nd = 0; nd < nidom; nd++)
      {
#include "HPC_LAYER/OMP_MODE_BEGIN.h"

	  normalisation_vect_(normL2_sum, param_int[nd], ipt_ind_dm_thread , iptkrylov[nd]);

          nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"
      }

//
//
// Loop sur vectuer krylov
//
//
for (E_Int kr = 0; kr < num_max_vect - 1; kr++)
  {
#pragma omp barrier
    // 2.1) Calcul de V_kr = A * V_kr-1
        shift_coe=0; nd_current=0;
	for (E_Int nd = 0; nd < nidom; nd++)
	  {
	   //A*V_kr-1 tapenade soon   //sur ind_sdm
	   E_Float* krylov_in = iptkrylov[nd] +  kr     *param_int[nd][NEQ] * param_int[nd][NDIMDX];
	   E_Float* krylov_out= iptkrylov[nd] + (kr + 1)*param_int[nd][NEQ] * param_int[nd][NDIMDX];

#include "HPC_LAYER/OMP_MODE_BEGIN.h"

	   invlu_(nd                     , nitcfg      ,nitrun, param_int[nd], param_real[nd],
	   	  ipt_ind_dm_thread      , mjrnewton               ,
	   	  iptrotmp[nd]           , iptro_ssiter[nd]        , krylov_in             , ipt_gmrestmp[nd],
	   	  ipti[nd]               , iptj[nd]                , iptk[nd]              ,
	   	  iptventi[nd]           , iptventj[nd]            , iptventk[nd]          ,
	   	  iptcoe  + shift_coe    , iptssor[nd]             , iptssortmp[nd]);

	   if (param_int[nd][NB_RELAX] != 0)
	     krylov_in = ipt_gmrestmp[nd];
			    
             dp_dw_vect_(param_int[nd], param_real[nd],ipt_ind_dm_thread , iptro_ssiter[nd], krylov_in,  krylov_out);

             nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"
	   shift_coe  = shift_coe  + param_int[nd][ NDIMDX ]*param_int[nd][ NEQ_COE ];

	   //Tableau de pointeur pour les raccords V_kr
	   iptkrylov_transfer[nd] = krylov_out;

	  }//loop zone

#pragma omp barrier
    //Reinitialisation verrou omp
    //
    nd_current=0;
    for (E_Int nd = 0; nd < nidom; nd++)
      {
#include  "HPC_LAYER/OMP_MODE_BEGIN.h"
           E_Int l =  nd_current*mx_synchro*Nbre_thread_actif  + (ithread_loc-1)*mx_synchro;
           for (E_Int i = 0;  i < mx_synchro ; i++) { ipt_lok[ l + i ]  = 0; }
           nd_current +=1;
#include  "HPC_LAYER/OMP_MODE_END.h"
      }//loop zone


    //
    //
    // fillghostCell
    //
    //
#pragma omp master
    { //Raccord V0
      setInterpTransfersFastS(iptkrylov_transfer, ndimdx_transfer, param_int_tc,
			      param_real_tc, param_int_ibc, param_real_ibc, param_real[0][PRANDT],
         		      it_target, nidom, ipt_timecount, mpi);
    }
#pragma omp barrier

    E_Int lrhs = 2; E_Int lcorner = 0; E_Int npass = 0; E_Int ipt_shift_lu[6];
    nd_current=0;
    for (E_Int nd = 0; nd < nidom; nd++)
      {
       E_Int* ipt_ind_CL_thread      = ipt_ind_CL         + (ithread-1)*6;
       E_Int* ipt_ind_CL119          = ipt_ind_CL         + (ithread-1)*6 +  6*Nbre_thread_actif;
       E_Int* ipt_shift_lu           = ipt_ind_CL         + (ithread-1)*6 + 12*Nbre_thread_actif;
       E_Int* ipt_ind_CLgmres        = ipt_ind_CL         + (ithread-1)*6 + 18*Nbre_thread_actif;
#include  "HPC_LAYER/OMP_MODE_BEGIN.h"

            E_Int ierr = BCzone_d(nd, lrhs , lcorner, param_int[nd], param_real[nd], npass,
	           		 ipt_ind_dm_loc, ipt_ind_dm_thread, 
			         ipt_ind_CL_thread, ipt_ind_CL119 ,  ipt_ind_CLgmres, ipt_shift_lu,
			         iptro_ssiter[nd],
		    	         ipti[nd]     , iptj[nd]            , iptk[nd],
			         iptx[nd]     , ipty[nd]            , iptz[nd],
			         iptventi[nd] , iptventj[nd]        , iptventk[nd],
			         iptkrylov_transfer[nd]);

            correct_coins_(nd,  param_int[nd], ipt_ind_dm_thread , iptkrylov_transfer[nd]);

            nd_current +=1;
#include    "HPC_LAYER/OMP_MODE_END.h"
      }//loop zone

#pragma omp barrier

    //
    //
    // produit matrice:vecteur.
    // In: rop_ssiter, rop_ssiter_d
    // Out: drodmd
    shift_zone=0;
    shift_wig =0;
    shift_coe =0;
    nd_current=0;
    for (E_Int nd = 0; nd < nidom; nd++)
      {
       E_Float* krylov_in    = iptkrylov[nd] +  kr    * param_int[nd][NEQ] * param_int[nd][NDIMDX];
       E_Float* rop_ssiter_d = iptkrylov[nd] + (kr+1) * param_int[nd][NEQ] * param_int[nd][NDIMDX];

       E_Int lmin = 10;
       if (param_int[nd][ITYPCP] == 2) lmin = 4;

#include "Compute/Linear_solver/dRdp_tapenade.cpp"

	shift_zone = shift_zone + param_int[nd][ NDIMDX ]*param_int[nd][ NEQ ];
	shift_wig  = shift_wig  + param_int[nd][ NDIMDX ]*3;
	shift_coe  = shift_coe  + param_int[nd][ NDIMDX ]*param_int[nd][ NEQ_COE ];
      }

#pragma omp barrier

    // kry(kr+1) = kry(kr) + drodmd
    shift_zone=0;
    nd_current=0;
    for (E_Int nd = 0; nd < nidom; nd++)
      {
        E_Float* krylov_in = iptkrylov[nd] +  kr    * param_int[nd][NEQ] * param_int[nd][NDIMDX];
        E_Float* krylov_out= iptkrylov[nd] + (kr+1) * param_int[nd][NEQ] * param_int[nd][NDIMDX];
	if (param_int[nd][NB_RELAX] != 0)
	  krylov_in = ipt_gmrestmp[nd];
#include "HPC_LAYER/OMP_MODE_BEGIN.h"
             id_vect_(param_int[nd], ipt_ind_dm_thread, ipt_drodmd + shift_zone, krylov_out, krylov_in);
             nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"

        shift_zone = shift_zone + param_int[nd][ NDIMDX ]*param_int[nd][ NEQ ];
      }


    // 2.2) Orthonormalisation du vecteur V_kr
    //
    //
    for (E_Int i = 0; i < kr + 1; i++)
      {
        // Produit scalaire consecutif de Gram Schmidt modifie
        // de V_0 à V_kr-1
        // value =  V_ki . V_kr-1   sur ind-sdm (pas de dependance i+1)
        //
	sum_value                  = 0.;
	normL2_sum                 = 0.;
        ipt_norm_kry[ithread_loc-1]= 0.;
        nd_current                 = 0;
	for (E_Int nd = 0; nd < nidom; nd++)
	  {
	   E_Float* krylov_i   = iptkrylov[nd] +   i    * param_int[nd][NEQ] * param_int[nd][NDIMDX];
	   E_Float* krylov_krp1= iptkrylov[nd] + (kr+1) * param_int[nd][NEQ] * param_int[nd][NDIMDX];

#include "HPC_LAYER/OMP_MODE_BEGIN.h"

	       scal_prod_(param_int[nd], ipt_ind_dm_thread, krylov_krp1, krylov_i, ipt_norm_kry[ithread_loc-1]);

               nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"
	  }//loop zone

#pragma omp barrier
        // norm L2 krylov pour openmp
        for (E_Int th = 0; th < Nbre_thread_actif; th++) { sum_value += ipt_norm_kry[th];}

        //Affectation des produits scalaires dans la matrice d'Hessenberg
#pragma omp single
        {
  	 E_Float* Hessenberg_i = ipt_Hessenberg + i * (num_max_vect - 1);
	 Hessenberg_i[kr]= sum_value;
        }

        //A chaque produit scalaire (V_kr, V_i) on fait
        //V_kr = V_kr - (V_kr, V_i)V_i
        //V_kr = V_kr - sum_value*V_i   sur ind-sdm (pas de dependance i+1)
        //
        // + calcul de la norme L2^2 mais seulement la derniere est utilisee
        ipt_norm_kry[ithread-1]= 0.;
        nd_current =0;
	for (E_Int nd = 0; nd < nidom; nd++)
	  {
	   E_Float* krylov_i   = iptkrylov[nd] +   i    * param_int[nd][NEQ] * param_int[nd][NDIMDX];
	   E_Float* krylov_krp1= iptkrylov[nd] + (kr+1) * param_int[nd][NEQ] * param_int[nd][NDIMDX];

#include "HPC_LAYER/OMP_MODE_BEGIN.h"
	       vect_rvect_(param_int[nd], ipt_ind_dm_thread, krylov_krp1, krylov_i, sum_value, ipt_norm_kry[ithread-1]);

               nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"
          }
      } // loop i< kr
        //
        //
        //
        //


#pragma omp barrier

    // norm L2 krylov pour openmp
    for (E_Int th = 0; th < Nbre_thread_actif; th++) { normL2_sum += ipt_norm_kry[th];}

    normL2_sum = sqrt(normL2_sum);
    //printf("norm rvect  %f %d  \n",normL2_sum , ithread);

    //Normalisation de V_kr + affectation de la norme sur la sous diagonale d'Hessenberg
#pragma omp single
    {
      E_Float tmp;
      E_Float* Hessenberg_i   = ipt_Hessenberg +  kr     * (num_max_vect - 1);
      E_Float* Hessenberg_ip1 = ipt_Hessenberg + (kr+1)  * (num_max_vect - 1);

      Hessenberg_ip1[ kr ] = normL2_sum;

      for (E_Int i = 0; i < kr; i++)
      	{
      	  Hessenberg_i   = ipt_Hessenberg + i     * (num_max_vect - 1);
      	  Hessenberg_ip1 = ipt_Hessenberg + (i+1) * (num_max_vect - 1);
      	  tmp =  Hessenberg_i[ kr ];

      	  Hessenberg_i[ kr ]   =   ipt_givens[ i ] * tmp + ipt_givens[ i+ num_max_vect - 1 ] * Hessenberg_ip1[ kr ];
      	  Hessenberg_ip1[ kr ] = - ipt_givens[ i+ num_max_vect - 1 ] * tmp + ipt_givens[ i ] * Hessenberg_ip1[ kr ];
      	}

      Hessenberg_i   = ipt_Hessenberg +  kr    * (num_max_vect - 1);
      Hessenberg_ip1 = ipt_Hessenberg + (kr+1) * (num_max_vect - 1);

      tmp = sqrt(Hessenberg_ip1[ kr ]*Hessenberg_ip1[ kr ] + Hessenberg_i[ kr ]*Hessenberg_i[ kr ]);
      ipt_givens[ kr ]  =   Hessenberg_i[ kr ] / tmp;
      ipt_givens[ kr + num_max_vect - 1 ]  = Hessenberg_ip1[ kr ] / tmp;

      tmp =  Hessenberg_i[kr];
      Hessenberg_i[ kr ]   =   ipt_givens[ kr ] * tmp + ipt_givens[ kr + num_max_vect - 1 ] * Hessenberg_ip1[ kr ];
      Hessenberg_ip1[ kr ] = - ipt_givens[ kr + num_max_vect - 1 ] * tmp + ipt_givens[ kr ] * Hessenberg_ip1[ kr ];

      ipt_VectG[ kr + 1 ] = - ipt_givens[ kr + num_max_vect - 1 ] * ipt_VectG[ kr ];
      ipt_VectG[ kr ]     =   ipt_givens[ kr ]                    * ipt_VectG[ kr ];

      //cout << "Residu GMRES = " << abs(ipt_VectG[kr + 1]) << endl;
    }

    nd_current =0;
    ipt_norm_kry[ithread_loc-1]= 0.;
    for (E_Int nd = 0; nd < nidom; nd++)
      {
       E_Float* krylov_krp1= iptkrylov[nd] + (kr+1) * param_int[nd][NEQ] * param_int[nd][NDIMDX];
#include "HPC_LAYER/OMP_MODE_BEGIN.h"
	       normalisation_vect_(normL2_sum, param_int[nd], ipt_ind_dm_thread , krylov_krp1);

               nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"
      }

/*
    // norm L2 pour verrif bug
    for (E_Int th = 0; th < Nbre_thread_actif; th++) { normL2_sum += ipt_norm_kry[th];}

    normL2_sum = sqrt(normL2_sum);
    printf("normvect   %f %d  \n",normL2_sum , ithread);
*/

  }//loop kr
   // fin loop vecteur krylov
   //  
   //
   //



/*
#pragma omp single
  {
    
    for (E_Int i = 0; i < num_max_vect ; i++)
      {
       E_Float* Hessenberg_i   = ipt_Hessenberg + i*(num_max_vect - 1);
       printf("hess avt \n " );
       for (E_Int j = 0; j < num_max_vect - 1; j++) { printf(" %f %d %d ", Hessenberg_i[j], i,j ); }
       printf("G0 %f \n",  ipt_VectG[0] );
      }

  }
*/

#pragma omp single
  {
   /* for (E_Int i = 0; i < num_max_vect ; i++) */
   /*   { */
   /*    E_Float* Hessenberg_i   = ipt_Hessenberg + i     * (num_max_vect - 1); */
   /*    printf("hess apr \n " ); */
   /*    for (E_Int j = 0; j < num_max_vect - 1; j++) { printf(" %f %d %d ", Hessenberg_i[j], i,j ); } */
   /*    printf("\n" ); */
   /*   } */

  //Resolution de Y par remontee
  for (E_Int i = num_max_vect - 2; i >= 0; i--)
    {
     E_Float* Hessenberg_i   = ipt_Hessenberg + i     * (num_max_vect - 1);
     value = 0.;
     for (E_Int j = num_max_vect - 2; j > i; j--) { value -= ipt_VectY[j] * Hessenberg_i[ j ]; }

     ipt_VectY[i] = (ipt_VectG[i] + value) / Hessenberg_i[ i ];
     //printf("VecY  %f %d  \n", ipt_VectY[i], i );
    }

  }//end omp single



  //Calcul de X solution du GMRES, stockage dans drodm
  shift_zone =0; nd_current =0;
  for (E_Int nd = 0; nd < nidom; nd++)
    {
#include "HPC_LAYER/OMP_MODE_BEGIN.h"
       // 
       // inverser les loop et vectoriser avec simd reduction
       // 
       prod_mat_vect_(param_int[nd], ipt_ind_dm_thread, iptkrylov[nd],
                      ipt_VectY, iptdrodm + shift_zone, num_max_vect);
       nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"
     shift_zone  = shift_zone  + param_int[nd][ NDIMDX ]*param_int[nd][ NEQ ];
    }//loop zone

      shift_coe =0; shift_zone =0; nd_current =0;
      for (E_Int nd  = 0; nd < nidom; nd++)
        {
#include "HPC_LAYER/OMP_MODE_BEGIN.h"
 
            E_Float* krylov_in = iptdrodm + shift_zone;
	    E_Float* krylov_out= iptdrodm + shift_zone;

	    invlu_(nd                     , nitcfg      ,nitrun, param_int[nd], param_real[nd],
	    	   ipt_ind_dm_thread      , mjrnewton               ,
	    	   iptrotmp[nd]           , iptro_ssiter[nd]        , krylov_in             , krylov_out            ,
	    	   ipti[nd]               , iptj[nd]                , iptk[nd]              ,
	    	   iptventi[nd]           , iptventj[nd]            , iptventk[nd]          ,
	    	   iptcoe  + shift_coe    , iptssor[nd]             , iptssortmp[nd]);

            nd_current +=1;
#include "HPC_LAYER/OMP_MODE_END.h"
	  shift_zone  = shift_zone  + param_int[nd][ NDIMDX ]*param_int[nd][ NEQ ];
          shift_coe  = shift_coe  + param_int[nd][ NDIMDX ]*param_int[nd][ NEQ_COE ];
         }//loop zone
  //
  //
  //init_gramm schmidt again normL2
  //
  //
  //
  //Include de print de verif

//#include "verif_Ax-b.cpp"
