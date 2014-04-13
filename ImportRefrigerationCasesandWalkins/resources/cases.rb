
def create_case(col, model)
  
  #key to map column names to values
  name_row = 0
  availability_schedule_name_row = 1
  zone_name_row = 2
  rated_ambient_temperature_row = 3
  rated_ambient_relative_humidity_row = 4
  rated_total_cooling_capacity_per_unit_length_row = 5
  rated_latent_heat_ratio_row = 6
  rated_runtime_fraction_row = 7
  case_length_row = 8
  case_operating_temperature_row = 9
  latent_case_credit_curve_type_row = 10
  latent_case_credit_curve_name_row = 11
  standard_case_fan_power_per_unit_length_row = 12
  operating_case_fan_power_per_unit_length_row = 13
  standard_case_lighting_power_per_unit_length_row = 14
  installed_case_lighting_power_per_unit_length_row = 15
  case_lighting_schedule_name_row = 16
  fraction_of_lighting_energy_to_case_row = 17
  case_anti_sweat_heater_power_per_unit_length_row = 18
  minimum_anti_sweat_heater_power_per_unit_length_row = 19
  anti_sweat_heater_control_type_row = 20
  humidity_at_zero_anti_sweat_heater_energy_row = 21
  case_height_row = 22
  fraction_of_anti_sweat_heater_energy_to_case_row = 23
  case_defrost_power_per_unit_length_row = 24
  case_defrost_type_row = 25
  case_defrost_schedule_name_row = 26
  case_defrost_drip_down_schedule_name_row = 27
  defrost_energy_correction_curve_type_row = 28
  defrost_energy_correction_curve_name_row = 29
  under_case_hvac_return_air_fraction_row = 30
  refrigerated_case_restocking_schedule_name_row = 31
  case_credit_fraction_schedule_name_row = 32
  design_evaporator_temperature_or_brine_inlet_temperature_row = 33
  average_refrigerant_charge_inventory_row = 34
  
  #find the defrost schedule for the case
  def_sch_name = col[case_defrost_schedule_name_row]
  def_sch = model.getScheduleCompactByName(def_sch_name)
  if def_sch.is_initialized
    def_sch = def_sch.get
  else
    @runner.registerError("could not find def sch #{def_sch_name} for case #{col[name_row]}, cannot create case")
    return false
  end

  #create the case (a defrost sch is required by the constructor)
  ref_case = OpenStudio::Model::RefrigerationCase.new(model, def_sch)
  
  #name
  ref_case.setName(col[name_row])
  
  #availability schedule for the case
  avail_sch_name = col[availability_schedule_name_row]
  avail_sch = model.getScheduleCompactByName(avail_sch_name)
  if avail_sch.is_initialized
    avail_sch = avail_sch.get
  else
    @runner.registerError("could not find avail sch #{avail_sch_name} for case #{col[name_row]}, cannot create case")
    return false
  end      
  ref_case.setAvailabilitySchedule(avail_sch)
  
  #zone the case is in
  zone_name = col[zone_name_row]
  zone = model.getThermalZoneByName(zone_name)
  if zone.is_initialized
    zone = zone.get
  else
    @runner.registerError("could not find zone #{zone_name} for case #{col[name_row]}, cannot create case")
    return false
  end 
  ref_case.setThermalZone(zone)
  
  #case properties
  ref_case.setRatedAmbientTemperature(col[rated_ambient_temperature_row])
  ref_case.setRatedAmbientRelativeHumidity(col[rated_ambient_relative_humidity_row])
  ref_case.setRatedTotalCoolingCapacityperUnitLength(col[rated_total_cooling_capacity_per_unit_length_row])
  ref_case.setRatedLatentHeatRatio(col[rated_latent_heat_ratio_row])
  ref_case.setRatedRuntimeFraction(col[rated_runtime_fraction_row])
  ref_case.setCaseLength(col[case_length_row])
  ref_case.setCaseOperatingTemperature(col[case_operating_temperature_row])
  ref_case.setLatentCaseCreditCurveType(col[latent_case_credit_curve_type_row])
  
  #latent curve for the case
  latent_curve_name = col[latent_case_credit_curve_name_row]
  latent_curve = model.getCurveCubicByName(latent_curve_name)
  if latent_curve.is_initialized
    latent_curve = latent_curve.get
  else
    @runner.registerError("could not find latent curve #{latent_curve_name} for case #{col[name_row]}, cannot create case")
    return false
  end      
  ref_case.setLatentCaseCreditCurve(latent_curve)      
  
  #more properties
  ref_case.setStandardCaseFanPowerperUnitLength(col[standard_case_fan_power_per_unit_length_row])
  ref_case.setOperatingCaseFanPowerperUnitLength(col[operating_case_fan_power_per_unit_length_row])
  ref_case.setStandardCaseLightingPowerperUnitLength(col[standard_case_lighting_power_per_unit_length_row])
  ref_case.setInstalledCaseLightingPowerperUnitLength(col[installed_case_lighting_power_per_unit_length_row])

  #lighting schedule for the case
  lighting_sch_name = col[case_lighting_schedule_name_row]
  lighting_sch = model.getScheduleCompactByName(lighting_sch_name)
  if lighting_sch.is_initialized
    lighting_sch = lighting_sch.get
  else
    @runner.registerError("could not find lighting sch #{lighting_curve_name} for case #{col[name_row]}, cannot create case")
    return false
  end      
  ref_case.setCaseLightingSchedule(lighting_sch)         
  
  #more properties
  ref_case.setFractionofLightingEnergytoCase(col[fraction_of_lighting_energy_to_case_row])
  ref_case.setCaseAntiSweatHeaterPowerperUnitLength(col[case_anti_sweat_heater_power_per_unit_length_row])
  ref_case.setMinimumAntiSweatHeaterPowerperUnitLength(col[minimum_anti_sweat_heater_power_per_unit_length_row])
  ref_case.setAntiSweatHeaterControlType(col[anti_sweat_heater_control_type_row])
  ref_case.setHumidityatZeroAntiSweatHeaterEnergy(col[humidity_at_zero_anti_sweat_heater_energy_row])
  #ref_case.setCaseHeight(col[case_height_row])
  ref_case.setFractionofAntiSweatHeaterEnergytoCase(col[fraction_of_anti_sweat_heater_energy_to_case_row])
  ref_case.setCaseDefrostPowerperUnitLength(col[case_defrost_power_per_unit_length_row])
  ref_case.setCaseDefrostType(col[case_defrost_type_row])
  
  #dripdown schedule for the case
  dripdown_sch_name = col[case_defrost_drip_down_schedule_name_row]
  dripdown_sch = model.getScheduleCompactByName(dripdown_sch_name)
  if dripdown_sch.is_initialized
    dripdown_sch = dripdown_sch.get
  else
    @runner.registerError("could not find dripdown sch #{dripdown_curve_name} for case #{col[name_row]}, cannot create case")
    return false
  end      
  ref_case.setCaseDefrostDripDownSchedule(dripdown_sch)

  #defrost correction curve
  ref_case.setDefrostEnergyCorrectionCurveType(col[defrost_energy_correction_curve_type_row])
  if not col[defrost_energy_correction_curve_type_row] == "None"
    #def_correction curve for the case
    def_correction_curve_name = col[defrost_energy_correction_curve_name_row]
    def_correction_curve = model.getCurveCubicByName(def_correction_curve_name)
    if def_correction_curve.is_initialized
      def_correction_curve = def_correction_curve.get
      def_correction_curve = def_correction_curve.to_CurveCubic.get
    else
      @runner.registerError("could not find def correction curve #{def_correction_curve_name} for case #{col[name_row]}, cannot create case")
      return false
    end      
    ref_case.setDefrostEnergyCorrectionCurve(def_correction_curve)   
  end
  
  #more properties
  ref_case.setUnderCaseHVACReturnAirFraction(col[under_case_hvac_return_air_fraction_row])
  
  #restocking schedule for the case
  restocking_sch_name = col[refrigerated_case_restocking_schedule_name_row]
  restocking_sch = model.getScheduleCompactByName(restocking_sch_name)
  if restocking_sch.is_initialized
    restocking_sch = restocking_sch.get
  else
    @runner.registerError("could not find restocking sch #{restocking_sch_name} for case #{col[name_row]}, cannot create case")
    return false
  end      
  ref_case.setRefrigeratedCaseRestockingSchedule(restocking_sch)  
  
  #case credit fraction schedule for the case
  case_credit_sch_name = col[case_credit_fraction_schedule_name_row]
  case_credit_sch = model.getScheduleCompactByName(case_credit_sch_name)
  if case_credit_sch.is_initialized
    case_credit_sch = case_credit_sch.get
  else
    @runner.registerError("could not find case_credit sch #{case_credit_sch_name} for case #{col[name_row]}, cannot create case")
    return false
  end      
  ref_case.setCaseCreditFractionSchedule(case_credit_sch)  

  #more properties
  ref_case.setDesignEvaporatorTemperatureorBrineInletTemperature(col[design_evaporator_temperature_or_brine_inlet_temperature_row])
  #ref_case.setAverageRefrigerantChargeInventory(col[average_refrigerant_charge_inventory_row])
  
  #inform the user
  @runner.registerInfo("Created case #{col[name_row]}}")

  return ref_case
  
end    
    