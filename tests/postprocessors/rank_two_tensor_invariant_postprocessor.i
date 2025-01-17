[Mesh]
  [generated_mesh]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 2
    ny = 2
    nz = 2
  []
  [./subdomain_id]
    type = ElementSubdomainIDGenerator
    input = generated_mesh
    subdomain_ids = '0 0 0 0
                     1 1 1 1'
  []
  [./boundary]
    type = SideSetsBetweenSubdomainsGenerator
    input = subdomain_id
    primary_block = 1
    paired_block = 2
    new_boundary = 'interface'
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Modules]
  [TensorMechanics]
    [Master]
      [all]
        strain = SMALL
        add_variables = true
        new_system = true
        formulation = UPDATED
        volumetric_locking_correction = true
        generate_output = 'cauchy_stress_xx cauchy_stress_yy cauchy_stress_zz cauchy_stress_xy '
                          'cauchy_stress_xz cauchy_stress_yz mechanical_strain_xx mechanical_strain_yy mechanical_strain_zz mechanical_strain_xy '
                          'mechanical_strain_xz mechanical_strain_yz'
      []
    []
  []
[] 

[Materials]
  [./stress]
    type = CauchyStressFromNEML
    database = "../test_materials.xml"
    model = "elastic_model"
    large_kinematics = false
  [../]
  [./tensor_rate]
    type = TensorRateMaterial
    rank_two_tensor = cauchy_stress
  []
  [s_vm_aux]
    type = RankTwoInvariant
    rank_two_tensor = cauchy_stress
    invariant =  'VonMisesStress'
    property_name = s_vm
  []
[]

[Functions]
 [./topfunc_x]
   type = PiecewiseLinear
   x = '0 2'
   y = '0 10'
 [../]
 [./topfunc_y]
   type = PiecewiseLinear
   x = '0 2'
   y = '0 20'
 [../]
 [./topfunc_z]
   type = PiecewiseLinear
   x = '0 2'
   y = '0 -30'
 [../]
[]

[BCs]
  [./x_0]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  [../]
  [./y_0]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom'
    value = 0
  [../]
  [./z_0]
    type = DirichletBC
    variable = disp_z
    boundary = 'back'
    value = 0
  [../]
  [./x_1]
    type = FunctionNeumannBC
    variable = disp_x
    boundary = 'right'
    function = topfunc_x
  [../]
  [./y_1]
    type = FunctionNeumannBC
    variable = disp_y
    boundary = 'top'
    function = topfunc_y
  [../]
  [./z_1]
    type = FunctionNeumannBC
    variable = disp_z
    boundary = 'front'
    function = topfunc_z
  [../]
[]

[RankTwoTensorIntegralOnDomain]
  [integral1]
    rank_two_tensor = 'cauchy_stress'
    use_displaced_mesh = true
    base_out_names = 'cauchy_stress'
  []
[]

[Postprocessors]
  [s_mises_new_pp]
    type = RankTwoTensorInvariantPostprocessor
    invariant = 'VonMisesStress'
    rank_two_tensor_base_name = 'cauchy_stress'
    use_displaced_mesh = true
  []
  [sdef_old]
    type = ElementIntegralMaterialProperty
    mat_prop = s_vm
    use_displaced_mesh = true
  []
[]

[Preconditioning]
  [./smp]
    type = SMP
    full = true
  [../]
[]



[Executioner]
  type = Transient

  solve_type = NEWTON
  line_search = none

  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'

  l_max_its = 2
  l_tol = 1e-14
  nl_max_its = 4
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10

  dtmin = 1
  dt = 1
  end_time = 2.0
[]
[Outputs]
  csv = true
[]
