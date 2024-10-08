.. FastS documentation master file

:tocdepth: 2

FastS: FAST structured grid Navier-Stokes solver
==================================================

Preamble
########

FastS is an efficient Navier-Stokes solver for use on structured 
grids.

FastS module works on CGNS/python trees (pyTrees) 
containing grid information (coordinates must be defined, boundary conditions and flow solution).

This module is only available for the pyTree interface::

    import FastS.PyTree as FastS


.. py:module:: FastS

List of functions
##################

**-- Computation Preparation**

.. autosummary::
   :nosignatures:

   FastS.PyTree.warmup
   FastS.PyTree._createConvergenceHistory
   FastS.PyTree.createStatNodes
   FastS.PyTree.createStressNodes


**-- Running computation**

.. autosummary::
    :nosignatures:

    FastS.PyTree._compute
    FastS.PyTree.displayTemporalCriteria

**-- Post**

.. autosummary::
    :nosignatures:
    
    FastS.PyTree._computeStats
    FastS.PyTree._computeStress
    FastS.PyTree._computeVariables
    FastS.PyTree._computeGrad
    FastS.PyTree._extractConvergenceHistory

Contents
#########

Preparation
--------------------------

.. py:function:: FastS.PyTree.warmup(t, tc, graph=None, infos_ale=None, tmy=None, verbose=0)

    Compute all necessary pre-requisites for solver:

        1. Metrics (face normales, volume)

        2. Primitive variables initialization and delete of conservative ones
        3. Memory optimimization (Numa access and contiguous access of Density, VelocityX,.. VelocityZ,..., Temperature)

        4. Work array creation (Storage of RHS, Matrix coef for implicit time scheme, lock for openmp,...)
        5. Initialization of grid Velocities (ALE)  
        6. Memory optimimization access for the connectivity tree, tc.
        7. Ghostcell cells filling with BC and connectivity
        8. Init of ViscosityEddy for NSLaminar, LES and SA computations

    :param t: input pyTree
    :type t: pyTree
    :param tc: input tree containing connection information
    :type tc: pyTree
    :param graph: input communication graph
    :type graph: dictionary
    :param infos_ale: input [position angle (rad), angle rotation speed (rad s^1)]
    :type infos_ale: list
    :param tmy: stat tree if any
    :type tmy: pyTree
    :param verbose: if 1, display information about threads distribution
    :param verbose: int (0 or 1)
    :return: (t, tc, metrics)
    :rtype: tuple

    **CAUTION!!!**

    **MUST be called before compute or everytime the solution tree is modified by a non in place function**

    **CAUTION!!!**


    *Example of use:*

    * `Warming up (PyTree) <Examples/FastS/warmupPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/warmupPT.py


-------------------------------------------

.. py:function:: FastS.PyTree._createConvergenceHistory(t, nrec)

    Create a node in each zone with convergence information (residuals)
    MUST be called before _displayTemporalCriteria() and only for steady cases.
    t is a pyTree, nrec is the size of the data arrays to store the residuals.
    The data arrays are stored during the call to  **FastS.displayTemporalCriteria**

    :param t: input pyTree
    :type t: pyTree
    :param nrec: ??
    :type nrec: ??

    *Example of use:*

    * `ConvergenceHistory (PyTree) <Examples/FastS/convergenceHistoryPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/convergenceHistoryPT.py

--------------------------------------------------------------
    
.. py:function:: FastS.PyTree.createStatNodes(t, dir='0')

    Create a tree, tmy, used by FastS._computeStats, to compute and store space and time averaged value of the flowfield. 

    The size of zones in tmy and t differs if space averaging occurs.

    Each zone of tmy has a node, named **'parameter_int'** with contains a numpy. The number of time **samples** is stored in  parameter_int[2]. 

    The averaged fields, computed at the center of the cell, are :

        1. Density
        2. MomentumX
        3. MomentumY
        4. MomentumZ
        5. Pressure 
        6. Pressure² 
        7. ViscosityEddy
        8. MomentumX²/Density
        9. MomentumY²/Density
        10. MomentumZ²/Density
        11. MomentumX * MomentumY / Density
        12. MomentumX * MomentumZ / Density
        13. MomentumY * MomentumZ / Density

    Return a new tree in tmy:

    :param t: input pyTree
    :type t: pyTree
    :param dir: input to determine homogeneous direction in a block structured sense 
    :type dir: character
    :return: tmy
    :rtype: tree

    the **dir** character can have the following values:

        - '0' :  (no space average)
        - 'i' :  space average along the I direction of the structured block
        - 'j' :  space average along the J direction of the structured block
        - 'k' :  space average along the K direction of the structured block
        - 'ij':  space average along the I and J directions of the structured block
        - 'ik':  space average along the I and K directions of the structured block
        - 'jk':  space average along the J and K directions of the structured block

    *Example of use:*

    * `Create Stat Node (pyTree) <Examples/FastS/createStatNodesPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/createStatNodesPT.py

------------------------------------------------

.. py:function:: FastS.PyTree.createStressNodes(t, BC= BCTypes)

    Create a tree, used by FastS._computeStress, to compute and store numerical fluxes, Gradient and Cp  on a list of boundary conditions.
    Return a new tree in teff.

    :param t: input pyTree
    :type t: pyTree
    :param BCTypes: types of BC to extract
    :type BCTypes: list of strings
    :return: tmy
    :rtype: tree

    Default value is BC=None.

    *Example of use:*

    * `Create stress Nodes(pyTree) <Examples/FastS/createStressNodesPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/createStressNodesPT.py


Running computation
---------------------

.. py:function:: FastS.PyTree._compute(t, metrics, nit, tc=None, graph=None)

    Perform one iteration of solver to advance (in place) the solution from t^n to t^(n+1). 

    nit is the current iteration number;  metrics contains normale and volume informations; tc is the connectivity tree (if any):
 
    :param t: input pyTree
    :type t: pyTree
    :param metrics:
    :type metrics: list
    :param nit: current iteration number
    :type nit: int
    :param tc: connecting pyTree 
    :type tc: pyTree
    :param graph: communication graph
    :type graph: dictionary

    *Example of use:*

    * `compute 200 timesteps of Euler Eqs (PyTree) <Examples/FastS/computePT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/computePT.py

-------------------------------------------

.. py:function:: FastS.PyTree.displayTemporalCriteria(t, metrics, nit, format=None)

    Displays CFL and implicit convergence information.

    :param t: input pyTree
    :type t: pyTree
    :param metrics:
    :type metrics:
    :param nit:
    :type nit:
    :param format: format for residual output ('None', 'double', 'store')
    :type format: string

    **format** can take 2 values:

    - None   (display residuals on the stdout with f7.2 Fortran format)
    - 'store' (store residual in the tree if CongergenceHistory node has been created by FastS.createConvergenceHistory)


    *Example of use:*

    * `Display temporal criteria in stdout (PyTree) <Examples/FastS/displayTemporalCriteriaPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/displayTemporalCriteriaPT.py
    


Post
-------


.. py:function:: FastS.PyTree._computeStats(t, tmy, metrics)

    Compute the space/time average of the flowfield in a tree tmy (in place).

    :param t: input pyTree
    :type t: pyTree
    :param tmy: stat tree
    :type tmy: pyTree
    :param metrics: metrics of t
    :type metrics: metrics

    *Example of use:*

    * `Compute flowfield average over 200 timesteps and in the k direction (pyTree) <Examples/FastS/computeStatsPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/computeStatsPT.py

----------------------------------------------------

.. py:function:: FastS.PyTree._computeStress(t, teff, metrics, xyz_ref=(0.,0.,0.))

    Compute in teff (in place) data related to a list of Boundary conditions defined by FastS._createStressNodes.

    :param t: input pyTree
    :type t: pyTree
    :param teff: stress tree
    :type teff: pyTree
    :param metrics: metrics of t
    :type metrics: metrics
    :param xyz_ref: reference point for momentum computation
    :type xyz_ref: tupple of 3 floats
    :return: effort
    :rtype: list

    in the tree **teff**, the following variables are updated in the **FlowSolution#Centers** node thanks to primitive variable of t:

        1. Density     (contains the numerical fluxes linked to the mass conservation: rho (U . n) x S) 
        2. MomentumX   (contains the normalized numerical fluxes linked to the MomentumX conservation minus P_inf*n: (( rho (U . n) Ux + (P-P_inf).nx ) x S ) x 0.5/rho_inf/U_inf^2 
        3. MomentumY...
        4. MomentumZ...
        5. EnergyStagnationDensity  (contains the normalized numerical fluxes of the linked to the energy conservation)
        6. gradxVelocityX (gradient in the x direction of VelocityX at the position of the BC)
        7. gradyVelocityX 
        8. gradzVelocityX 
        9. gradxVelocityY
        10. gradyVelocityY
        11. gradzVelocityY
        12. gradxVelocityZ 
        13. gradyVelocityZ
        14. gradzVelocityZ
        15. gradxTemperature 
        16. gradyTemperature
        17. gradzTemperature
        18. CoefPressure
        19. ViscosityMolecular + ViscosityEddy
        20. Density2: contains density (kg/m^3)
        21. Pressure
    
    Normalized data are normalized by 0.5 rho_inf U_inf^2 defined in the ReferenceState CGNS node

    the return of the function, effort, is a list of 8 items which contains integral over the surface of the BC of different variables of teff:

        1. integral of MomentumX (normalized numerical fluxes linked to the MomentumX conservation) give access to cx (stored in effort[0]) 
        2. integral of MomentumY (normalized numerical fluxes linked to the MomentumY conservation) give access to cy (stored in effort[1])
        3. integral of MomentumZ (normalized numerical fluxes linked to the MomentumZ conservation) give access to cz (stored in effort[2])
        4. give access to cmx (stored in effort[3])
        5. give access to cmy (stored in effort[4])
        6. give access to cmz (stored in effort[5])
        7. give access to surface of the BC (stored in effort[6])
        8. integral of Density   (numerical fluxes linked to the Density conservation) give access to mass flow rate (stored in effort[7]) 
        9. integral of MomemtumX (numerical fluxes linked to the MomentumX conservation) give access to the stress (Newton) in the X direction (stored in effort[8]) 
        10. integral of MomemtumY (numerical fluxes linked to the MomentumY conservation) give access to the stress (Newton) in the Y direction (stored in effort[9]) 
        11. integral of MomemtumZ (numerical fluxes linked to the MomentumZ conservation) give access to the stress (Newton) in the Z direction (stored in effort[10]) 

    For a 2D computation in (x,y) plan, with an angle of attack of theta:

        - drag = eff[0]*cos(theta) + eff[1]*sin(theta)
        - lift = eff[1]*cos(theta) - eff[0]*sin(theta)


    *Example of use:*

    * `Compute load (pyTree) <Examples/FastS/computeStressPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/computeStressPT.py

    * `Compute debit (pyTree) for Inflow BC condition  <Examples/FastS/computeDebitPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/computeDebitPT.py

------------------------------------------------------

.. py:function:: FastS.PyTree._computeVariables(t, metrics, variables)

    Compute specified variables.

    :param t: input/output pyTree
    :type t: pyTree
    :param metrics: input metrics of t
    :type metrics: list
    :param variables: input variables to compute
    :type variables: list of strings


    The available variables are:

        -  QCriterion
        -  QpCriterion = QCriterion* min( 1, abs(dDensitydt) )
        -  Enstrophy

    *Example of use:*

    * `Compute variables (pyTree) <Examples/FastS/computeVariablesPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/computeVariablesPT.py

------------------------------------------------------

.. py:function:: FastS.PyTree._computeGrad(t, metrics, variables, order=2)

    Compute specified variables gradients at cell centers with FV Green Gauss approach.

    :param t: input/output pyTree
    :type t: pyTree
    :param metrics: metrics of t
    :type metrics: list
    :param variables: list of variable names to extract grad
    :type variables: list of strings
    :param order: order for gradients
    :type order: int (2 or 4)

    In case a variable is not in t or in a zone, the computation of the gradients is skipped.

    order can take 2 values:
        - 2: classical flux reconstruction (2nd order)
        - 4: flux reconstruction formula giving 4th order accurate scheme on cartesian grid

    *Example of use:*

    * `Compute grad (pyTree) <Examples/FastS/computeGradPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/computeGradPT.py

--------------------------------------------------------

.. py:function:: FastS.PyTree._extractConvergenceHistory(t, fileout, perZones=True, perBases=True)

    Extract convergence information (residuals) for each zone or/and for each base.

    :param t: input pyTree with ConvergenceHistory computed
    :type t: pyTree
    :param fileout: name of file for resiudal extraction (tp format)
    :type fileout: string
    :param perZones: if True, write residuals for each zones
    :type perZones: Boolean
    :param perBases: if True, write residuals for each bases
    :type perBases: Boolean
    
    *Example of use:*

    * `Extract convergence history (pyTree) <Examples/FastS/extractConvergenceHistoryPT.py>`_:

    .. literalinclude:: ../build/Examples/FastS/extractConvergenceHistoryPT.py



.. toctree::
   :maxdepth: 2


Index
########

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

