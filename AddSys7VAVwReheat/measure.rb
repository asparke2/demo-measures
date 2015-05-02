#see the URL below for information on how to write OpenStudio measures
# http:#openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http:#openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http:#openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys7VAVR < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add Sys 7 - VAVR"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
        
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # System Type 7: VAV w/ Reheat
    # This measure creates:
    # a single hot water loop with a natural gas boiler for the building
    # a single chilled water loop with water cooled chiller for the building
    # a single condenser water loop for heat rejection from the chiller
    # a VAV system w/ hot water heating, chilled water cooling, and 
    # hot water reheat for each story of the building
    
    always_on = model.alwaysOnDiscreteSchedule

    # Hot Water Plant

    hw_loop = OpenStudio::Model::PlantLoop.new(model)
    hw_loop.setName("Hot Water Loop for VAV with Reheat")
    hw_sizing_plant = hw_loop.sizingPlant
    hw_sizing_plant.setLoopType("Heating")
    hw_sizing_plant.setDesignLoopExitTemperature(82.0) #TODO units
    hw_sizing_plant.setLoopDesignTemperatureDifference(11.0)

    hw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)

    boiler = OpenStudio::Model::BoilerHotWater.new(model)

    boiler_eff_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
    boiler_eff_f_of_temp.setName("Boiler Efficiency")
    boiler_eff_f_of_temp.setCoefficient1Constant(1.0)
    boiler_eff_f_of_temp.setInputUnitTypeforX("Dimensionless")
    boiler_eff_f_of_temp.setInputUnitTypeforY("Dimensionless")
    boiler_eff_f_of_temp.setOutputUnitType("Dimensionless")

    boiler.setNormalizedBoilerEfficiencyCurve(boiler_eff_f_of_temp)
    boiler.setEfficiencyCurveTemperatureEvaluationVariable("LeavingBoiler")

    boiler_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
        
    hw_supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    
    # Add the components to the hot water loop
    hw_supply_inlet_node = hw_loop.supplyInletNode
    hw_supply_outlet_node = hw_loop.supplyOutletNode
    hw_pump.addToNode(hw_supply_inlet_node)
    hw_loop.addSupplyBranchForComponent(boiler)
    hw_loop.addSupplyBranchForComponent(boiler_bypass_pipe)
    hw_supply_outlet_pipe.addToNode(hw_supply_outlet_node)

    # Add a setpoint manager to control the
    # hot water to a constant temperature    
    hw_t_c = OpenStudio::convert(153,"F","C").get
    hw_t_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    hw_t_sch.setName("HW Temp")
    hw_t_sch.defaultDaySchedule().setName("HW Temp Default")
    hw_t_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),hw_t_c)
    hw_t_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,hw_t_sch)
    hw_t_stpt_manager.addToNode(hw_supply_outlet_node)
    
    # Chilled Water Plant

    chw_loop = OpenStudio::Model::PlantLoop.new(model)
    chw_loop.setName("Chilled Water Loop for VAV with Reheat")
    chw_sizing_plant = chw_loop.sizingPlant
    chw_sizing_plant.setLoopType("Cooling")
    chw_sizing_plant.setDesignLoopExitTemperature(7.22) #TODO units
    chw_sizing_plant.setLoopDesignTemperatureDifference(6.67)    

    chw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    
    clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
    clg_cap_f_of_temp.setCoefficient1Constant(1.0215158)
    clg_cap_f_of_temp.setCoefficient2x(0.037035864)
    clg_cap_f_of_temp.setCoefficient3xPOW2(0.0002332476)
    clg_cap_f_of_temp.setCoefficient4y(-0.003894048)
    clg_cap_f_of_temp.setCoefficient5yPOW2(-6.52536e-005)
    clg_cap_f_of_temp.setCoefficient6xTIMESY(-0.0002680452)
    clg_cap_f_of_temp.setMinimumValueofx(5.0)
    clg_cap_f_of_temp.setMaximumValueofx(10.0)
    clg_cap_f_of_temp.setMinimumValueofy(24.0)
    clg_cap_f_of_temp.setMaximumValueofy(35.0)

    eir_f_of_avail_to_nom_cap = OpenStudio::Model::CurveBiquadratic.new(model)
    eir_f_of_avail_to_nom_cap.setCoefficient1Constant(0.70176857)
    eir_f_of_avail_to_nom_cap.setCoefficient2x(-0.00452016)
    eir_f_of_avail_to_nom_cap.setCoefficient3xPOW2(0.0005331096)
    eir_f_of_avail_to_nom_cap.setCoefficient4y(-0.005498208)
    eir_f_of_avail_to_nom_cap.setCoefficient5yPOW2(0.0005445792)
    eir_f_of_avail_to_nom_cap.setCoefficient6xTIMESY(-0.0007290324)
    eir_f_of_avail_to_nom_cap.setMinimumValueofx(5.0)
    eir_f_of_avail_to_nom_cap.setMaximumValueofx(10.0)
    eir_f_of_avail_to_nom_cap.setMinimumValueofy(24.0)
    eir_f_of_avail_to_nom_cap.setMaximumValueofy(35.0)

    eir_f_of_plr = OpenStudio::Model::CurveQuadratic.new(model)
    eir_f_of_plr.setCoefficient1Constant(0.06369119)
    eir_f_of_plr.setCoefficient2x(0.58488832)
    eir_f_of_plr.setCoefficient3xPOW2(0.35280274)
    eir_f_of_plr.setMinimumValueofx(0.0)
    eir_f_of_plr.setMaximumValueofx(1.0)

    chiller = OpenStudio::Model::ChillerElectricEIR.new(model,
                                                        clg_cap_f_of_temp,
                                                        eir_f_of_avail_to_nom_cap,
                                                        eir_f_of_plr)

    chiller_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
        
    chw_supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)                                                    
                                                        
    # Add the components to the chilled water loop
    chw_supply_inlet_node = chw_loop.supplyInletNode
    chw_supply_outlet_node = chw_loop.supplyOutletNode
    chw_pump.addToNode(chw_supply_inlet_node)
    chw_loop.addSupplyBranchForComponent(chiller)
    chw_loop.addSupplyBranchForComponent(chiller_bypass_pipe)
    chw_supply_outlet_pipe.addToNode(chw_supply_outlet_node)

    # Add a setpoint manager to control the
    # chilled water to a constant temperature    
    chw_t_c = OpenStudio::convert(44,"F","C").get
    chw_t_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    chw_t_sch.setName("CHW Temp")
    chw_t_sch.defaultDaySchedule().setName("HW Temp Default")
    chw_t_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),chw_t_c)
    chw_t_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,chw_t_sch)
    chw_t_stpt_manager.addToNode(chw_supply_outlet_node)  
      
    # Condenser System
    
    cw_loop = OpenStudio::Model::PlantLoop.new(model)
    cw_loop.setName("Condenser Water Loop for VAV with Reheat")
    cw_sizing_plant = chw_loop.sizingPlant
    cw_sizing_plant.setLoopType("Condenser")
    cw_sizing_plant.setDesignLoopExitTemperature(29.4) #TODO units
    cw_sizing_plant.setLoopDesignTemperatureDifference(5.6)    

    cw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    
    clg_tower = OpenStudio::Model::CoolingTowerSingleSpeed.new(model)

    clg_tower_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
        
    cw_supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)                                                    
                                                        
    # Add the components to the condenser water loop
    cw_supply_inlet_node = cw_loop.supplyInletNode
    cw_supply_outlet_node = cw_loop.supplyOutletNode
    cw_pump.addToNode(cw_supply_inlet_node)
    cw_loop.addSupplyBranchForComponent(clg_tower)
    cw_loop.addSupplyBranchForComponent(clg_tower_bypass_pipe)
    cw_supply_outlet_pipe.addToNode(cw_supply_outlet_node)
    cw_loop.addDemandBranchForComponent(chiller)

    # Add a setpoint manager to control the
    # condenser water to follow the OA temp    
    cw_t_stpt_manager = OpenStudio::Model::SetpointManagerFollowOutdoorAirTemperature.new(model)
    cw_t_stpt_manager.addToNode(cw_supply_outlet_node)    
    
    # Make a Packaged VAV w/ PFP Boxes for each story of the building
    model.getBuildingStorys.sort.each do |story|
          
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("VAV with Reheat")
      sizingSystem = air_loop.sizingSystem
      sizingSystem.setCentralCoolingDesignSupplyAirTemperature(12.8)
      sizingSystem.setCentralHeatingDesignSupplyAirTemperature(12.8)    
      
      fan = OpenStudio::Model::FanVariableVolume.new(model,always_on)
      fan.setPressureRise(500)

      htg_coil = OpenStudio::Model::CoilHeatingWater.new(model,always_on)
      hw_loop.addDemandBranchForComponent(htg_coil)

      clg_coil = OpenStudio::Model::CoilCoolingWater.new(model,always_on)
      chw_loop.addDemandBranchForComponent(clg_coil)
      
      oa_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)

      oa_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model,oa_controller)      
      
      # Add the components to the air loop
      # in order from closest to zone to furthest from zone
      supply_inlet_node = air_loop.supplyInletNode
      supply_outlet_node = air_loop.supplyOutletNode    
      fan.addToNode(supply_inlet_node)
      htg_coil.addToNode(supply_inlet_node)
      clg_coil.addToNode(supply_inlet_node)
      oa_system.addToNode(supply_inlet_node)    
      
      # Add a setpoint manager to control the
      # supply air to a constant temperature    
      sat_c = OpenStudio::convert(55,"F","C").get
      sat_sch = OpenStudio::Model::ScheduleRuleset.new(model)
      sat_sch.setName("Supply Air Temp")
      sat_sch.defaultDaySchedule().setName("Supply Air Temp Default")
      sat_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),sat_c)
      sat_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,sat_sch)
      sat_stpt_manager.addToNode(supply_outlet_node)

      # Get all zones on this story
      zones = []
      story.spaces.each do |space|
        if space.thermalZone.is_initialized
          zones << space.thermalZone.get
        end      
      end 
      
      # Make a VAV terminal with HW reheat for each zone on this story
      # and hook the reheat coil to the HW loop
      zones.each do |zone|
        reheat_coil = OpenStudio::Model::CoilHeatingWater.new(model,always_on)
        hw_loop.addDemandBranchForComponent(reheat_coil)
        vav_terminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(model,always_on,reheat_coil)
        air_loop.addBranchForZone(zone,vav_terminal.to_StraightComponent)
      end   
      
    end # next story  
      

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSys7VAVR.new.registerWithApplication