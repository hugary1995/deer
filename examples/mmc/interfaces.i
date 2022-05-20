strain_rate = 8.33e-5
strain_max = 0.5
nsteps_max = 20
nsteps_base = 2000
nsteps_min = 2000

# BiLinearMixedModeTraction model parameters for matrix-particle debonding
m_penalty_stiffness = 1e5
m_GI_C = 700
m_GII_C = 175
m_normal_strength = 225
m_shear_strength = 129
m_eta = 0
m_viscosity = 1e-3
m_lag_seperation_state = true
m_alpha = 1e-10
m_normal_strength_scale_factor = 1.0

# Bilinear mixed mode model parameters for fracture in particle phase
p_penalty_stiffness = 1e6
p_GI_C = 70
p_GII_C = 17.5
p_normal_strength = 370
p_shear_strength = 185
p_eta = 0
p_viscosity = 1e-3
p_lag_seperation_state = true
p_alpha = 1e-10 #default 1e-10
p_normal_strength_scale_factor = 1.0

[Mesh]
  [msh]
    type = FileMeshGenerator
    file = debond.exo
  []
  [split]
    type = BreakMeshByBlockGenerator
    input = msh
    split_interface = true
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Functions]
  [stretch]
    type = PiecewiseLinear
    x = '0 ${fparse strain_max / strain_rate}'
    y = '0 ${fparse strain_max * 3}'
  []
[]

[BCs]
  [fix_x]
    type = DirichletBC
    preset = true
    value = 0.0
    boundary = negx
    variable = disp_x
  []
  [fix_y]
    type = DirichletBC
    preset = true
    value = 0.0
    boundary = negy
    variable = disp_y
  []
  [fix_z]
    type = DirichletBC
    preset = true
    value = 0.0
    boundary = negz
    variable = disp_z
  []
  [stretch]
    type = FunctionDirichletBC
    boundary = pullz
    variable = disp_z
    function = stretch
  []
[]

[Constraints]
  [x1]
    type = EqualValueBoundaryConstraint
    variable = disp_x
    secondary = posx
    penalty = 1e6
  []
  [y1]
    type = EqualValueBoundaryConstraint
    variable = disp_y
    secondary = posy
    penalty = 1e6
  []
[]

[Modules]
  [TensorMechanics]
    [Master]
      [all]
        strain = FINITE
        add_variables = true
        new_system = true
        formulation = TOTAL
        volumetric_locking_correction = true
        generate_output = 'cauchy_stress_xx cauchy_stress_yy cauchy_stress_zz cauchy_stress_xy '
                          'cauchy_stress_xz cauchy_stress_yz mechanical_strain_xx '
                          'mechanical_strain_yy mechanical_strain_zz mechanical_strain_xy '
                          'mechanical_strain_xz mechanical_strain_yz'
      []
    []
  []
[]

[Modules/TensorMechanics/CohesiveZoneMaster]
  [czm]
    strain = FINITE
    generate_output = 'traction_x traction_y traction_z normal_traction tangent_traction jump_x '
                      'jump_y jump_z normal_jump tangent_jump'
    boundary = 'Block1_Block9 Block2_Block9 Block3_Block9 Block4_Block9 Block5_Block9 Block6_Block9 '
               'Block7_Block9 Block8_Block9 Block1_Block2 Block1_Block3 Block1_Block6 Block2_Block4 '
               'Block2_Block5 Block3_Block4 Block3_Block8 Block4_Block7 Block5_Block6 Block5_Block7 '
               'Block6_Block8 Block7_Block8'
  []
[]

[Materials]
  [czm_3dc_matrix_particle]
    type = BiLinearMixedModeTraction
    penalty_stiffness = ${m_penalty_stiffness}
    GI_C = ${m_GI_C}
    GII_C = ${m_GII_C}
    normal_strength = ${m_normal_strength}
    shear_strength = ${m_shear_strength}
    displacements = 'disp_x disp_y disp_z'
    eta = ${m_eta}
    viscosity = ${m_viscosity}
    lag_seperation_state = ${m_lag_seperation_state}
    alpha = ${m_alpha}
    mixed_mode_criterion = BK
    normal_strength_scale_factor = ${m_normal_strength_scale_factor}
    boundary = 'Block1_Block9 Block2_Block9 Block3_Block9 Block4_Block9 Block5_Block9 Block6_Block9 '
               'Block7_Block9 Block8_Block9'
  []
  [czm_3dc_particle_particle]
    type = BiLinearMixedModeTraction
    penalty_stiffness = ${p_penalty_stiffness}
    GI_C = ${p_GI_C}
    GII_C = ${p_GII_C}
    normal_strength = ${p_normal_strength}
    shear_strength = ${p_shear_strength}
    displacements = 'disp_x disp_y disp_z'
    eta = ${p_eta}
    viscosity = ${p_viscosity}
    lag_seperation_state = ${p_lag_seperation_state}
    alpha = ${p_alpha}
    mixed_mode_criterion = BK
    normal_strength_scale_factor = ${p_normal_strength_scale_factor}
    boundary = "Block1_Block2 Block1_Block3 Block1_Block6 Block2_Block4 Block2_Block5 Block3_Block4 "
               "Block3_Block8 Block4_Block7 Block5_Block6 Block5_Block7 Block6_Block8 Block7_Block8"
  []
  [stress_particle]
    block = "1 2 3 4 5 6 7 8"
    type = CauchyStressFromNEML
    database = "materials.xml"
    model = "elastic_model"
    large_kinematics = true
  []
  [stress_matrix]
    block = "9"
    type = CauchyStressFromNEML
    database = "materials.xml"
    model = "plastic_model"
    large_kinematics = true
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  solve_type = 'NEWTON'
  petsc_options = '-snes_converged_reason -ksp_converged_reason'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'

  l_max_its = 2
  l_tol = 1e-12
  nl_max_its = 50
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8

  line_search = 'none'
  end_time = '${fparse strain_max / strain_rate}'

  dtmin = '${fparse strain_max / strain_rate / nsteps_min}'
  dtmax = '${fparse strain_max / strain_rate / nsteps_max}'

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = '${fparse strain_max / strain_rate / nsteps_base}'
    cutback_factor = 0.5
    growth_factor = 2
    optimal_iterations = 10
  []
[]

[Outputs]
  csv = true
  console = true
  exodus = true
[]

[Postprocessors]
  [avg_stress_zz]
    type = ElementAverageValue
    variable = cauchy_stress_zz
  []
  [avg_strain_zz]
    type = ElementAverageValue
    variable = mechanical_strain_zz
  []
[]
