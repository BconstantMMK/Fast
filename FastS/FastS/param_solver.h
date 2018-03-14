/*    
    Copyright 2013-2018 Onera.

    This file is part of Cassiopee.

    Cassiopee is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Cassiopee is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Cassiopee.  If not, see <http://www.gnu.org/licenses/>.
*/
#define GET_TI(pos, metric, para, ti, tj, tk, vol) { ti  = K_NUMPY::getNumpyPtrF( PyList_GetItem(metric, pos ) ); \
                                                     tj  = ti + para[ NDIMDX_MTR]* para[ NEQ_IJ];                 \
                                                     tk  = tj + para[ NDIMDX_MTR]* para[ NEQ_IJ];                 \
                                                     vol = tk + para[ NDIMDX_MTR]* para[ NEQ_K ];                 }

#define GET_VENT(pos, metric, para, vi, vj, vk) { vi  = K_NUMPY::getNumpyPtrF( PyList_GetItem(metric, pos ) ); \
                                                  E_Int c=0; if(para[LALE] == 1){ c=1;}                        \
                                                  vj  = vi + para[ NDIMDX_VENT]* para[ NEQ_VENT]*c;            \
                                                  vk  = vj + para[ NDIMDX_VENT]* para[ NEQ_VENT]*c;            }

#define GET_XYZ(name, zone, x, y, z) { PyObject* sol  = K_PYTREE::getNodeFromName1(zone , name);  \
                                       PyObject* t    = K_PYTREE::getNodeFromName1(sol  , "CoordinateX"    );  \
                                                  x   = K_PYTREE::getValueAF(t, hook);                         \
                                                  t   = K_PYTREE::getNodeFromName1(sol  , "CoordinateY"    );  \
                                                  y   = K_PYTREE::getValueAF(t, hook);                         \
                                                  t   = K_PYTREE::getNodeFromName1(sol  , "CoordinateZ"    );  \
                                                  z   = K_PYTREE::getValueAF(t, hook);                         }



#define BCDEGENERATELINE          0
#define BCEXTRAPOLATE             0
#define BCFARFIELD                1
#define BCINFLOWSUPERSONIC        2
#define BCWALLINVISCID            3
#define BCSYMMETRYPLANE           3
#define BCWALL                    4
#define FAMILYSPECIFIED           5
#define BCWALLVISCOUS             6
#define BCWALLVISCOUS_ISOT_FICH   7
#define BC_FICH                   8
#define NEARMATCH                 9
#define BCOUTFLOW                10
#define BCAUTOPERIOD             11
#define BCWALLVISCOUS_TRANSITION 12
#define BCINFLOW                 13
#define BCEXTRAPOLATERANS        14
#define BCPERIODIC               15
#define BCOUTPRES                16
#define BCINJ1                   17


#if (CACHELINE == 64)
#define VECLENGTH     8
#elif (CACHELINE == 32)
#define VECLENGTH     4
#else 
#define VECLENGTH     4
#endif

#define NBR_SOCKET    1

#define NIJK          0
#define NIJK_MTR      5
#define NIJK_XYZ     10
#define NIJK_VENT    15
#define IJKV         20
#define EFF_LOOP     23   
#define NDIMD_SDM    23
#define MXSSDOM_LU   24
#define ITYPZONE     25
#define ITYPVENT     26
#define IFLOW        27
#define ILES         28
#define ITYPCP       29
#define EFF_I0       29   
#define SIZE_SSDOM   30
#define KFLUDOM      33
#define LALE         34
#define IFLAGFLT     35
#define EFF_NONZ     34   
#define EFF_IDIR     35   
#define EFF_NDF      36   
#define NEQ          36
#define NEQ_IJ       37
#define NEQ_K        38
#define NEQ_COE      39
#define NEQ_VENT     40
#define NDIMDX       41
#define NDIMDX_XYZ   42
#define NDIMDX_MTR   43
#define NDIMDX_VENT  44
#define IO_THREAD    45
#define DTLOC        46   
#define SA_INT       47
                                                  
#define RK	         52
#define LEVEL	       53
#define EXPLOC       54
#define ITEXPLOC     55
#define LEVELG	     56
#define LEVELD	     57
#define NSSITER	     58
#define CACHEBLCKI   59
#define CACHEBLCKJ   60
#define CACHEBLCKK   61
#define SFD          62
#define SFD_INIT_IT  63
#define SLOPE        64
#define NIT_INFLOW   65

#define SHIFTVAR     66
#define EXTRACT_RES  67
#define SA_DEBUG     68
#define BC_NBBC	     69

#define BC_TYPE	      0
#define BC_IDIR       1
#define BC_FEN        2
#define BC_NBDATA     8
   


#define DTC          0
#define STAREF       1
#define GAMMA        1
#define CVINF        2
#define ROINF        3
#define PINF         4
#define VINF         5
#define TINF         6
#define MINF         7
#define RONUTILDEINF 8
#define VISCO        9
#define REYNOLDS     9
#define PRANDT      10
#define XMUL0       11
#define TEMP0       12
#define CS          13
#define EPSI_NEWTON 14  
#define CFL         15  
#define SA_REAL     16  
#define VXINF       19
#define VYINF       20
#define VZINF       21
#define TEMPS       22
#define ROTATION    23
#define ROT_OMEGA   23
#define ROT_CENTER  26
#define ROT_FREQ    29
#define ROT_AMPLI   30
#define ROT_INIT    31
#define ROT_TETA    32
#define ROT_TETAP   33
#define PSIROE      34
#define SFD_CHI     35
#define SFD_DELTA   36
#define EPSI_INFLOW 37  
#define PRANDT_TUR  38  
#define BC_DATA     39


#define SA_CKARM    0.41 
#define SA_CB1      0.1355
#define SA_CB2      0.622
#define SA_CV1      357.911
#define SA_CV2      0.7
#define SA_CV3      0.9
#define SA_CW2      0.3
#define SA_CW3      64.
#define SA_SIGMA    (2./3.)
#define SA_RCTEDES  0.65

#define SA_IDES      1   
#define SA_IDIST     2   
#define SA_ISPAX     3   
#define SA_IZGRIS    4   
#define SA_IPROD     5   
#define SA_AZGRIS    1   
#define SA_ADDES     2   
#define SA_RATIOM    3   

#define METRIC_TI    0   
#define METRIC_TI0   1   
#define METRIC_VENT  2   
#define METRIC_TIDF  3   
#define METRIC_RDM   4   
#define METRIC_INDM  5   
#define METRIC_ITLU  6   

