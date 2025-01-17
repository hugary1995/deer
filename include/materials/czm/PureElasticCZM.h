//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "CZMComputeLocalTractionTotalBase.h"

class PureElasticCZM;
/**
 * Implementation of the non-stateful exponential traction separation law
 * proposed by Salehani, Mohsen Khajeh and Irani, Nilgoon 2018
 **/
class PureElasticCZM : public CZMComputeLocalTractionTotalBase {
public:
  static InputParameters validParams();
  PureElasticCZM(const InputParameters &parameters);

protected:
  virtual void computeInterfaceTractionAndDerivatives() override;

  virtual RealVectorValue computeTraction();

  virtual RankTwoTensor computeTractionDerivatives();

  virtual void ComputeNormalTraction(RealVectorValue &traction);
  virtual void
  ComputeNormalTractionDerivatives(RankTwoTensor &traction_derivatives);
  virtual void ComputeShearTraction(RealVectorValue &traction);
  virtual void
  ComputeShearTractionDerivatives(RankTwoTensor &traction_derivatives);

  virtual Real ComputeNormalStiffness();
  virtual RealVectorValue ComputeNormalStiffnessDerivatives();

  virtual Real ComputeShearStiffness();
  virtual RankTwoTensor ComputeShearStiffnessDerivatives();

  /// interface normal stiffness [Pressure]
  const Real _E;
  /// interface shear stiffness  [Pressure]
  const Real _G;

  const Real _interface_thickness;
  const Real _penetration_penalty;
};
