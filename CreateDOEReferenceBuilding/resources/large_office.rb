
def add_geometry(model)
  
  @runner.registerInfo("started adding geometry")
  
  #load geometry from the saved .osm
  model = safe_load_model("#{@resource_path}/large_office_geometry.osm")
  
  @runner.registerInfo("finished adding geometry")
  
  return model
  
end
 
def add_loads(model)

  #create a new space type generator
  require "#{@resource_path}/SpaceTypeGenerator.rb"
  st_gen = SpaceTypeGenerator.new(path_to_space_type_json, path_to_master_schedules_library, path_to_office_schedules_library)

  #loop through all the space types currently in the model
  #which are placeholders, and replace with actual space types
  #that have loads
  model.getSpaceTypes.each do |old_space_type|

    @runner.registerInfo("replacing #{old_space_type.name}")

    #get the building type
    stds_building_type = nil
    if old_space_type.standardsBuildingType.is_initialized
      stds_building_type = old_space_type.standardsBuildingType.get
      @runner.registerInfo("standards building type = #{stds_building_type}")
    else
      runner.registerError("Warning - space type called '#{old_space_type.name}' has no standards building type")
      return false
    end
    
    #get the space type
    stds_spc_type = nil
    if old_space_type.standardsSpaceType.is_initialized
      stds_spc_type = old_space_type.standardsSpaceType.get
      @runner.registerInfo("standards space type = #{stds_spc_type}")
    else
      runner.registerError("Warning - space type called '#{old_space_type.name}' has no standards space type")
      return false
    end
    
    #generate the new space type
    @runner.registerInfo("generating")
    new_space_type = st_gen.generate_space_type(@building_vintage, @climate_zone, stds_building_type, stds_spc_type)[0]

    #apply the new space type to the building      
    old_space_type.spaces.each do |space|
      space.setSpaceType(new_space_type)
      @runner.registerInfo("applied new space type to #{space.name}")
    end
      
  end
  
  return model

end
   
def add_hvac(model)
 
  @runner.registerInfo("started adding HVAC")
 
  #VAVR system; hot water reheat, water-cooled chiller
  #one AHU per floor

  #hvac operation schedule
  # HVACOperationSchd,On/Off,
  # Through: 12/31,
  # For: Weekdays SummerDesignDay,Until: 06:00,0.0,Until: 22:00,1.0,Until: 24:00,0.0,
  # For: Saturday WinterDesignDay,Until: 06:00,0.0,Until: 18:00,1.0,Until: 24:00,0.0,
  # For: AllOtherDays,Until: 24:00,0.0    
  #weekdays and summer design days
  hvac_op_sch = OpenStudio::Model::ScheduleRuleset.new(model)
  hvac_op_sch.setName("HVAC Operation Schedule")
  hvac_op_sch.defaultDaySchedule.setName("HVAC Operation Schedule Weekdays") 
  hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,6,0,0), 0.0)
  hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,22,0,0), 1.0)
  hvac_op_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
  hvac_op_sch.setSummerDesignDaySchedule(hvac_op_sch.defaultDaySchedule)
  #saturdays and winter design days
  saturday_rule = OpenStudio::Model::ScheduleRule.new(hvac_op_sch)
  saturday_rule.setName("HVAC Operation Schedule Saturday Rule")
  saturday_rule.setApplySaturday(true)   
  saturday = saturday_rule.daySchedule  
  saturday.setName("HVAC Operation Schedule Saturday")
  saturday.addValue(OpenStudio::Time.new(0,6,0,0), 0.0)
  saturday.addValue(OpenStudio::Time.new(0,18,0,0), 1.0)
  saturday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
  hvac_op_sch.setWinterDesignDaySchedule(saturday)
  #sundays
  sunday_rule = OpenStudio::Model::ScheduleRule.new(hvac_op_sch)
  sunday_rule.setName("HVAC Operation Schedule Sunday Rule")
  sunday_rule.setApplySunday(true)   
  sunday = sunday_rule.daySchedule  
  sunday.setName("HVAC Operation Schedule Sunday")
  sunday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
  
  #motorized oa damper schedule
  # MinOA_MotorizedDamper_Sched,Fraction,
  # Through: 12/31,
  # For: Weekdays SummerDesignDay,Until: 07:00,0.0,Until: 22:00,1.0,Until: 24:00,0.0,
  # For: Saturday WinterDesignDay,Until: 07:00,0.0,Until: 18:00,1.0,Until: 24:00,0.0,
  # For: AllOtherDays,Until: 24:00,0.0
  #weekdays and summer design days
  motorized_oa_damper_sch = OpenStudio::Model::ScheduleRuleset.new(model)
  motorized_oa_damper_sch.setName("Motorized OA Damper Schedule")
  motorized_oa_damper_sch.defaultDaySchedule.setName("Motorized OA Damper Schedule Weekdays") 
  motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,7,0,0), 0.0)
  motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,22,0,0), 1.0)
  motorized_oa_damper_sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
  motorized_oa_damper_sch.setSummerDesignDaySchedule(motorized_oa_damper_sch.defaultDaySchedule)
  #saturdays and winter design days
  saturday_rule = OpenStudio::Model::ScheduleRule.new(motorized_oa_damper_sch)
  saturday_rule.setName("Motorized OA Damper Schedule Saturday Rule")
  saturday_rule.setApplySaturday(true)   
  saturday = saturday_rule.daySchedule  
  saturday.setName("Motorized OA Damper Schedule Saturday")
  saturday.addValue(OpenStudio::Time.new(0,7,0,0), 0.0)
  saturday.addValue(OpenStudio::Time.new(0,18,0,0), 1.0)
  saturday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)
  motorized_oa_damper_sch.setWinterDesignDaySchedule(saturday)
  #sundays
  sunday_rule = OpenStudio::Model::ScheduleRule.new(motorized_oa_damper_sch)
  sunday_rule.setName("Motorized OA Damper Schedule Sunday Rule")
  sunday_rule.setApplySunday(true)   
  sunday = sunday_rule.daySchedule  
  sunday.setName("Motorized OA Damper Schedule Sunday")
  sunday.addValue(OpenStudio::Time.new(0,24,0,0), 0.0)    
  
  #hot water loop
  hot_water_loop = OpenStudio::Model::PlantLoop.new(model)
  hot_water_loop.setName("Hot Water Loop")

  #hot water loop controls
  hw_temp_f = 180 #HW setpoint 180F 
  hw_delta_t_r = 20 #20F delta-T    
  hw_temp_c = OpenStudio::convert(hw_temp_f,"F","C").get
  hw_delta_t_k = OpenStudio::convert(hw_delta_t_r,"R","K").get
  hw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
  hw_temp_sch.setName("Hot Water Loop Temp - #{hw_temp_f}F")
  hw_temp_sch.defaultDaySchedule().setName("Hot Water Loop Temp - #{hw_temp_f}F Default")
  hw_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),hw_temp_c)
  hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,hw_temp_sch)    
  hw_stpt_manager.addToNode(hot_water_loop.supplyOutletNode)
  sizing_plant = hot_water_loop.sizingPlant
  sizing_plant.setLoopType("Heating")
  sizing_plant.setDesignLoopExitTemperature(hw_temp_c)
  sizing_plant.setLoopDesignTemperatureDifference(hw_delta_t_k)         
  
  #hot water pump
  hw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
  hw_pump.setName("Hot Water Loop Pump")
  hw_pump_head_ft_h2o = 60.0
  hw_pump_head_press_pa = OpenStudio::convert(hw_pump_head_ft_h2o, "ftH_{2}O","Pa").get
  hw_pump.setRatedPumpHead(hw_pump_head_press_pa)
  hw_pump.setMotorEfficiency(0.875)
  hw_pump.setPumpControlType("Intermittent")
  hw_pump.addToNode(hot_water_loop.supplyInletNode)
  
  #boiler
  boiler = OpenStudio::Model::BoilerHotWater.new(model)
  boiler.setName("Hot Water Loop Boiler")
  boiler.setDesignWaterOutletTemperature(hw_temp_c)
  boiler.setNominalThermalEfficiency(0.76)
  boiler.setBoilerFlowMode("LeavingSetpointModulated")
  hot_water_loop.addSupplyBranchForComponent(boiler)   
  
  #hot water looop pipes
  boiler_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  hot_water_loop.addSupplyBranchForComponent(boiler_bypass_pipe)
  coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  hot_water_loop.addDemandBranchForComponent(coil_bypass_pipe)
  supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  supply_outlet_pipe.addToNode(hot_water_loop.supplyOutletNode)    
  demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  demand_inlet_pipe.addToNode(hot_water_loop.demandInletNode) 
  demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  demand_outlet_pipe.addToNode(hot_water_loop.demandOutletNode) 

  #chilled water loop
  chilled_water_loop = OpenStudio::Model::PlantLoop.new(model)
  chilled_water_loop.setName("Chilled Water Loop")

  #chilled water loop controls
  chw_temp_f = 44 #CHW setpoint 44F 
  chw_delta_t_r = 12 #12F delta-T    
  chw_temp_c = OpenStudio::convert(chw_temp_f,"F","C").get
  chw_delta_t_k = OpenStudio::convert(chw_delta_t_r,"R","K").get
  chw_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
  chw_temp_sch.setName("Chilled Water Loop Temp - #{chw_temp_f}F")
  chw_temp_sch.defaultDaySchedule().setName("Chilled Water Loop Temp - #{chw_temp_f}F Default")
  chw_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),chw_temp_c)
  chw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,chw_temp_sch)    
  chw_stpt_manager.addToNode(chilled_water_loop.supplyOutletNode)
  sizing_plant = chilled_water_loop.sizingPlant
  sizing_plant.setLoopType("Cooling")
  sizing_plant.setDesignLoopExitTemperature(chw_temp_c)
  sizing_plant.setLoopDesignTemperatureDifference(chw_delta_t_k)         
  
  #chilled water pump
  chw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
  chw_pump.setName("Chilled Water Loop Pump")
  chw_pump_head_ft_h2o = 60.0
  chw_pump_head_press_pa = OpenStudio::convert(chw_pump_head_ft_h2o, "ftH_{2}O","Pa").get
  chw_pump.setRatedPumpHead(chw_pump_head_press_pa)
  chw_pump.setMotorEfficiency(0.9)
  chw_pump.setPumpControlType("Intermittent")
  chw_pump.addToNode(chilled_water_loop.supplyInletNode)   
  
  #chiller
  #TODO change chillers to match ref model
  #ref model has 2 chillers in parallel
  #uses Chiller:Electric:Reformulated, which OS doesn't have
  ccFofT = OpenStudio::Model::CurveBiquadratic.new(model)
  ccFofT.setName("Water Cooled Chiller ccFofT")
  ccFofT.setCoefficient1Constant(1.0215158)
  ccFofT.setCoefficient2x(0.037035864)
  ccFofT.setCoefficient3xPOW2(0.0002332476)
  ccFofT.setCoefficient4y(-0.003894048)
  ccFofT.setCoefficient5yPOW2(-6.52536e-005)
  ccFofT.setCoefficient6xTIMESY(-0.0002680452)
  ccFofT.setMinimumValueofx(5.0)
  ccFofT.setMaximumValueofx(10.0)
  ccFofT.setMinimumValueofy(24.0)
  ccFofT.setMaximumValueofy(35.0)

  eirToCorfOfT = OpenStudio::Model::CurveBiquadratic.new(model)
  eirToCorfOfT.setName("Water Cooled Chiller eirToCorfOfT")
  eirToCorfOfT.setCoefficient1Constant(0.70176857)
  eirToCorfOfT.setCoefficient2x(-0.00452016)
  eirToCorfOfT.setCoefficient3xPOW2(0.0005331096)
  eirToCorfOfT.setCoefficient4y(-0.005498208)
  eirToCorfOfT.setCoefficient5yPOW2(0.0005445792)
  eirToCorfOfT.setCoefficient6xTIMESY(-0.0007290324)
  eirToCorfOfT.setMinimumValueofx(5.0)
  eirToCorfOfT.setMaximumValueofx(10.0)
  eirToCorfOfT.setMinimumValueofy(24.0)
  eirToCorfOfT.setMaximumValueofy(35.0)

  eirToCorfOfPlr = OpenStudio::Model::CurveQuadratic.new(model)
  eirToCorfOfPlr.setName("Water Cooled Chiller eirToCorfOfPlr")
  eirToCorfOfPlr.setCoefficient1Constant(0.06369119)
  eirToCorfOfPlr.setCoefficient2x(0.58488832)
  eirToCorfOfPlr.setCoefficient3xPOW2(0.35280274)
  eirToCorfOfPlr.setMinimumValueofx(0.0)
  eirToCorfOfPlr.setMaximumValueofx(1.0)

  chiller = OpenStudio::Model::ChillerElectricEIR.new(model,ccFofT,eirToCorfOfT,eirToCorfOfPlr)
  chiller.setName("Chilled Water Loop Chiller")
  chiller.setReferenceLeavingChilledWaterTemperature(chw_temp_c)
  ref_cond_wtr_temp_f = 95
  ref_cond_wtr_temp_c = OpenStudio::convert(ref_cond_wtr_temp_f,"F","C").get
  #chiller.setReferenceEnteringCondenserFluidTemperature(ref_cond_wtr_temp_c)
  chiller.setReferenceCOP(5.11)
  chiller.setChillerFlowMode("LeavingSetpointModulated")
  chiller.setMinimumUnloadingRatio(0.2)
  chilled_water_loop.addSupplyBranchForComponent(chiller)
  
  #chilled water loop pipes
  chiller_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  chilled_water_loop.addSupplyBranchForComponent(chiller_bypass_pipe)
  coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  chilled_water_loop.addDemandBranchForComponent(coil_bypass_pipe)
  supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  supply_outlet_pipe.addToNode(chilled_water_loop.supplyOutletNode)    
  demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  demand_inlet_pipe.addToNode(chilled_water_loop.demandInletNode) 
  demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  demand_outlet_pipe.addToNode(chilled_water_loop.demandOutletNode)
  
  #condenser water loop
  condenser_water_loop = OpenStudio::Model::PlantLoop.new(model)
  condenser_water_loop.setName("Condenser Water Loop")

  #condenser water loop controls
  cw_dsn_temp_f = 85 #CW design setpoint 85F
  cw_min_temp_f = 41 #CW min setpoint 41F
  cw_max_temp_f = 176 #CW setpoint 176F
  cw_delta_t_r = 10 #10F delta-T    
  cw_dsn_temp_c = OpenStudio::convert(cw_dsn_temp_f,"F","C").get
  cw_min_temp_c = OpenStudio::convert(cw_min_temp_f,"F","C").get
  cw_max_temp_c = OpenStudio::convert(cw_max_temp_f,"F","C").get
  cw_delta_t_k = OpenStudio::convert(cw_delta_t_r,"R","K").get
  cw_stpt_manager = OpenStudio::Model::SetpointManagerFollowOutdoorAirTemperature.new(model)    
  cw_stpt_manager.setControlVariable("Temperature")
  cw_stpt_manager.setReferenceTemperatureType("OutdoorAirWetBulb")
  cw_stpt_manager.setOffsetTemperatureDifference(0.0)
  cw_stpt_manager.setMinimumSetpointTemperature(cw_min_temp_c)
  cw_stpt_manager.setMaximumSetpointTemperature(cw_max_temp_c)
  cw_stpt_manager.addToNode(condenser_water_loop.supplyOutletNode)
  sizing_plant = condenser_water_loop.sizingPlant
  sizing_plant.setLoopType("Condenser")
  sizing_plant.setDesignLoopExitTemperature(cw_dsn_temp_c)
  sizing_plant.setLoopDesignTemperatureDifference(cw_delta_t_k)   
  condenser_water_loop.setMinimumLoopTemperature(cw_min_temp_c)
  condenser_water_loop.setMaximumLoopTemperature(cw_max_temp_c)
  
  #condenser water pump
  cw_pump = OpenStudio::Model::PumpConstantSpeed.new(model)
  cw_pump.setName("Condenser Water Loop Pump")
  cw_pump_head_ft_h2o = 60.0
  cw_pump_head_press_pa = OpenStudio::convert(cw_pump_head_ft_h2o, "ftH_{2}O","Pa").get
  cw_pump.setRatedPumpHead(cw_pump_head_press_pa)
  cw_pump.setMotorEfficiency(0.87)
  cw_pump.setPumpControlType("Intermittent")
  cw_pump.addToNode(condenser_water_loop.supplyInletNode)  
  
  #cooling tower
  cooling_tower = OpenStudio::Model::CoolingTowerSingleSpeed.new(model)
  cooling_tower.setPerformanceInputMethod("UFactorTimesAreaAndDesignWaterFlowRate")
  cooling_tower.setEvaporationLossMode("SaturatedExit")
  cooling_tower.setDriftLossPercent(0.008)
  cooling_tower.setBlowdownCalculationMode("ConcentrationRatio")
  cooling_tower.setBlowdownConcentrationRatio(3)
  cooling_tower.setCapacityControl("FanCycling")
  condenser_water_loop.addSupplyBranchForComponent(cooling_tower)

  #hook the chiiler up to the condenser water loop
  condenser_water_loop.addDemandBranchForComponent(chiller)
  
  #condenser water loop pipes
  cooling_tower_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  condenser_water_loop.addSupplyBranchForComponent(cooling_tower_bypass_pipe)
  coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  condenser_water_loop.addDemandBranchForComponent(coil_bypass_pipe)
  supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  supply_outlet_pipe.addToNode(condenser_water_loop.supplyOutletNode)    
  demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  demand_inlet_pipe.addToNode(condenser_water_loop.demandInletNode) 
  demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
  demand_outlet_pipe.addToNode(condenser_water_loop.demandOutletNode)
  
  #one VAV air handler per floor
  
  #control temps used across all air handlers
  clg_sa_temp_f = 55 #deck temp 55F 
  prehtg_sa_temp_f = 62 #preheat to 62F  #TODO don't understand this setting in ref model
  htg_sa_temp_f = 90 #htg temp 90F
  clg_sa_temp_c = OpenStudio::convert(clg_sa_temp_f,"F","C").get
  prehtg_sa_temp_c = OpenStudio::convert(prehtg_sa_temp_f,"F","C").get
  htg_sa_temp_c = OpenStudio::convert(htg_sa_temp_f,"F","C").get
  sa_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
  sa_temp_sch.setName("Supply Air Temp - #{clg_sa_temp_f}F")
  sa_temp_sch.defaultDaySchedule().setName("Supply Air Temp - #{clg_sa_temp_f}F Default")
  sa_temp_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),clg_sa_temp_c)    
  
  #loop through building stories and add one air handler per floor
  model.getBuildingStorys.each do |floor|
    #air handler
    floor_name = floor.name.get
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName("#{floor_name} VAV Air Handler")
    
    #air handler controls
    hw_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,sa_temp_sch)    
    hw_stpt_manager.addToNode(air_loop.supplyOutletNode)
    sizing_system = air_loop.sizingSystem()
    sizing_system.setAllOutdoorAirinCooling(false)
    sizing_system.setAllOutdoorAirinHeating(false)
    air_loop.setNightCycleControlType("CyleOnAny")
    
    #fan
    fan = OpenStudio::Model::FanVariableVolume.new(model,hvac_op_sch)
    fan.setName("#{floor_name} VAV Fan")
    fan.setFanEfficiency(0.6045)
    fan_static_pressure_in_h2o = 4
    fan_static_pressure_pa = OpenStudio::convert(fan_static_pressure_in_h2o, "inH_{2}O","Pa").get
    fan.setPressureRise(fan_static_pressure_pa)
    fan.addToNode(air_loop.supplyInletNode)
    
    #cooling coil
    clg_coil = OpenStudio::Model::CoilCoolingWater.new(model,model.alwaysOnDiscreteSchedule)
    clg_coil.addToNode(air_loop.supplyInletNode)
    chilled_water_loop.addDemandBranchForComponent(clg_coil)
    
    #heating coil
    htg_coil = OpenStudio::Model::CoilHeatingWater.new(model,model.alwaysOnDiscreteSchedule)
    htg_coil.setRatedInletWaterTemperature(hw_temp_c)
    htg_coil.setRatedInletAirTemperature(prehtg_sa_temp_c)
    htg_coil.setRatedOutletWaterTemperature(hw_temp_c - hw_delta_t_k)
    htg_coil.setRatedOutletAirTemperature(htg_sa_temp_c)
    htg_coil.addToNode(air_loop.supplyInletNode)
    hot_water_loop.addDemandBranchForComponent(htg_coil)
    
    #outdoor air intake system
    oa_intake_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
    oa_intake = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, oa_intake_controller)    
    oa_intake_controller.setEconomizerControlType("NoEconomizer")
    oa_intake_controller.setMinimumLimitType("FixedMinimum")
    oa_intake_controller.setMinimumOutdoorAirSchedule(motorized_oa_damper_sch)
    oa_intake.addToNode(air_loop.supplyInletNode)
    
    #find all zones on this floor
    thermal_zones_on_floor = []
    floor.spaces.each do |space|
      if space.thermalZone.is_initialized
        thermal_zones_on_floor << space.thermalZone.get
      end
    end
    
    #hook the VAV system to each zone
    thermal_zones_on_floor.each do |zone|
    
      #reheat coil
      rht_coil = OpenStudio::Model::CoilHeatingWater.new(model,model.alwaysOnDiscreteSchedule)
      rht_coil.setRatedInletWaterTemperature(hw_temp_c)
      rht_coil.setRatedInletAirTemperature(prehtg_sa_temp_c)
      rht_coil.setRatedOutletWaterTemperature(hw_temp_c - hw_delta_t_k)
      rht_coil.setRatedOutletAirTemperature(htg_sa_temp_c)
      hot_water_loop.addDemandBranchForComponent(rht_coil)        
      
      #vav terminal
      terminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(model,model.alwaysOnDiscreteSchedule,rht_coil)
      terminal.setZoneMinimumAirFlowMethod("Constant")
      terminal.setConstantMinimumAirFlowFraction(0.3)
      terminal.setDamperHeatingAction("Normal")
      air_loop.addBranchForZone(zone,terminal.to_StraightComponent)
    
    end #next zone
    
    #TODO hook up return plenums for each airloop
    
  end #next story
  
  @runner.registerInfo("finished adding HVAC")
  
  return model
  
end #add hvac
