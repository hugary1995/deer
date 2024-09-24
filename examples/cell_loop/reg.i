load = 150
t0 = 360

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'rve/reg.msh'
  []
  use_displaced_mesh = false
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = FINITE
        new_system = true
        add_variables = true
        formulation = TOTAL
        volumetric_locking_correction = true
        generate_output = 'vonmises_cauchy_stress effective_inelastic_strain'
      []
    []
  []
[]

[Functions]
  [load]
    type = PiecewiseLinear
    x = '0 ${t0}'
    y = '0 ${load}'
  []
[]

[BCs]
  [left]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'left'
  []
  [bottom]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom'
  []
  [right]
    type = FunctionNeumannBC
    variable = disp_x
    function = 'load'
    boundary = 'right'
  []
[]

[Constraints]
  [x]
    type = EqualValueBoundaryConstraint
    variable = disp_x
    secondary = 'right'
    penalty = 1e8
  []
  [y]
    type = EqualValueBoundaryConstraint
    variable = disp_y
    secondary = 'top'
    penalty = 1e8
  []
[]

[UserObjects]
  [euler_angle_file]
    type = PropertyReadFile
    nprop = 3
    prop_file_name = 'texture/${tex}.tex'
    read_type = block
    nblock = 1
    use_zero_based_block_indexing = false
  []
[]

[Materials]
  [stress]
    type = NEMLCrystalPlasticity
    database = '316.xml'
    model = '316'
    large_kinematics = true
    euler_angle_reader = euler_angle_file
  []
[]

[Executioner]
  type = Transient

  solve_type = NEWTON

  petsc_options = '-snes_converged_reason -ksp_converged_reason'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'

  resid_vs_jac_scaling_param = 0.5
  reuse_preconditioner = true
  reuse_preconditioner_max_linear_its = 25

  line_search = none
  automatic_scaling = true
  l_max_its = 300
  nl_max_its = 15
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8
  nl_forced_its = 1
  end_time = 3600000
  dtmax = 1800

  [Predictor]
    type = SimplePredictor
    scale = 1
    skip_after_failed_timestep = true
  []

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 1
    growth_factor = 1.2
    cutback_factor = 0.5
    cutback_factor_at_failure = 0.1
    optimal_iterations = 8
    iteration_window = 1
    linear_iteration_ratio = 1000000000
  []
[]

[Postprocessors]
  [avg_disp]
    type = SideAverageValue
    variable = disp_x
    boundary = 'right'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [disp_rate]
    type = TimeDerivativePostprocessor
    postprocessor = 'avg_disp'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [disp_rate_min]
    type = TimeExtremeValue
    postprocessor = 'disp_rate'
    value_type = min
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[UserObjects]
  [tertiary]
    type = Terminator
    expression = 'disp_rate > 1.05 * disp_rate_min'
    message = 'tertiary creep begins'
  []
[]

[Controls]
  [creep_start]
    type = TimePeriod
    enable_objects = 'Postprocessors::disp_rate_min'
    start_time = '${t0}'
  []
[]

[Outputs]
  file_base = 'output/reg-${tex}'
  print_linear_residuals = false
  exodus = true
  csv = true
[]
