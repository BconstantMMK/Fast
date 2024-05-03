
E_Float gam     = param_real[ NoD ][ GAMMA ];
E_Float Rgp     = param_real[ NoD ][ CVINF ]*(gam-1);
E_Float t_inf   = param_real[ NoD ][ TINF  ];
E_Float ro_inf  = param_real[ NoD ][ ROINF ];
E_Float c0_ref  = sqrt(gam*Rgp*t_inf);
E_Float u_scale = sqrt(3.)*c0_ref;

E_Float v1, v2, v3, v4;
E_Float pp, t_from_lbm;

E_Int indR;

for (E_Int noind = pt_deb; noind < pt_fin; noind++)
{

  indR   = rcvPts[noind];

  v1 = vectOfRcvFields[0][indR]; //ro
  v2 = vectOfRcvFields[1][indR]; //vx
  v3 = vectOfRcvFields[2][indR]; //vy
  v4 = vectOfRcvFields[3][indR]; //vz
  // La temperature est modifiee par une BC
  pp = ro_inf*gam*Rgp*t_inf*(-0.4/1.4 + v1 );
  t_from_lbm = pp/(Rgp*v1*ro_inf);
  //cout << t_from_lbm << endl;

  vectOfRcvFields[0][indR] = v1*ro_inf;
  vectOfRcvFields[1][indR] = v2*u_scale;
  vectOfRcvFields[2][indR] = v3*u_scale;
  vectOfRcvFields[3][indR] = 0.;//v4*u_scale;
  //vectOfRcvFields[4][indR] = t_from_lbm;

}
