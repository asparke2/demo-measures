#see the URL below for information on how to write OpenStudio measures
# http:#openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http:#openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http:#openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys5PVAVR < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add Sys 5 - PVAVR"
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

    # System Type 5: Packaged VAV w/ Reheat
    # This measure creates:
    # a single hot water loop with a natural gas boiler for the building
    # a VAV system w/ hot water heating, DX cooling, and 
    # hot water reheat for each story of the building
    
    always_on = model.alwaysOnDiscreteSchedule

    # Hot Water Loop

    hw_loop = OpenStudio::Model::PlantLoop.new(model)
    hw_loop.setName("Hot Water Loop for Packaged Rooftop VAV with Reheat")
    sizing_plant = hw_loop.sizingPlant
    sizing_plant.setLoopType("Heating")
    sizing_plant.setDesignLoopExitTemperature(82.0) #TODO units
    sizing_plant.setLoopDesignTemperatureDifference(11.0)

    pump = OpenStudio::Model::PumpVariableSpeed.new(model)

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
        
    supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    
    # Add the components to the hot water loop
    hw_supply_inlet_node = hw_loop.supplyInletNode
    hw_supply_outlet_node = hw_loop.supplyOutletNode
    pump.addToNode(hw_supply_inlet_node)
    hw_loop.addSupplyBranchForComponent(boiler)
    hw_loop.addSupplyBranchForComponent(boiler_bypass_pipe)
    supply_outlet_pipe.addToNode(hw_supply_outlet_node)
    
    # Add a setpoint manager to control the
    # hot water to a constant temperature    
    hw_t_c = OpenStudio::convert(153,"F","C").get
    hw_t_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    hw_t_sch.setName("HW Temp")
    hw_t_sch.defaultDaySchedule().setName("HW Temp Default")
    hw_t_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),hw_t_c)
    hw_t_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,hw_t_sch)
    hw_t_stpt_manager.addToNode(hw_supply_outlet_node)       
    
    # Make a Packaged VAV w/ Reheat for each story of the building
    model.getBuildingStorys.sort.each do |story|
    
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("#{story.name} Packaged Rooftop VAV with Reheat")
      sizingSystem = air_loop.sizingSystem
      sizingSystem.setCentralCoolingDesignSupplyAirTemperature(12.8)
      sizingSystem.setCentralHeatingDesignSupplyAirTemperature(12.8)

      fan = OpenStudio::Model::FanVariableVolume.new(model,always_on)
      fan.setPressureRise(500)

      htg_coil = OpenStudio::Model::CoilHeatingWater.new(model,always_on)
      hw_loop.addDemandBranchForComponent(htg_coil)
      
      clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      clg_cap_f_of_temp.setCoefficient1Constant(0.42415)
      clg_cap_f_of_temp.setCoefficient2x(0.04426)
      clg_cap_f_of_temp.setCoefficient3xPOW2(-0.00042)
      clg_cap_f_of_temp.setCoefficient4y(0.00333)
      clg_cap_f_of_temp.setCoefficient5yPOW2(-0.00008)
      clg_cap_f_of_temp.setCoefficient6xTIMESY(-0.00021)
      clg_cap_f_of_temp.setMinimumValueofx(17.0)
      clg_cap_f_of_temp.setMaximumValueofx(22.0)
      clg_cap_f_of_temp.setMinimumValueofy(13.0)
      clg_cap_f_of_temp.setMaximumValueofy(46.0)

      clg_cap_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      clg_cap_f_of_flow.setCoefficient1Constant(0.77136)
      clg_cap_f_of_flow.setCoefficient2x(0.34053)
      clg_cap_f_of_flow.setCoefficient3xPOW2(-0.11088)
      clg_cap_f_of_flow.setMinimumValueofx(0.75918)
      clg_cap_f_of_flow.setMaximumValueofx(1.13877)

      clg_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      clg_energy_input_ratio_f_of_temp.setCoefficient1Constant(1.23649)
      clg_energy_input_ratio_f_of_temp.setCoefficient2x(-0.02431)
      clg_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(0.00057)
      clg_energy_input_ratio_f_of_temp.setCoefficient4y(-0.01434)
      clg_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.00063)
      clg_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.00038)
      clg_energy_input_ratio_f_of_temp.setMinimumValueofx(17.0)
      clg_energy_input_ratio_f_of_temp.setMaximumValueofx(22.0)
      clg_energy_input_ratio_f_of_temp.setMinimumValueofy(13.0)
      clg_energy_input_ratio_f_of_temp.setMaximumValueofy(46.0)

      clg_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      clg_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.20550)
      clg_energy_input_ratio_f_of_flow.setCoefficient2x(-0.32953)
      clg_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.12308)
      clg_energy_input_ratio_f_of_flow.setMinimumValueofx(0.75918)
      clg_energy_input_ratio_f_of_flow.setMaximumValueofx(1.13877)

      clg_part_load_ratio = OpenStudio::Model::CurveQuadratic.new(model)
      clg_part_load_ratio.setCoefficient1Constant(0.77100)
      clg_part_load_ratio.setCoefficient2x(0.22900)
      clg_part_load_ratio.setCoefficient3xPOW2(0.0)
      clg_part_load_ratio.setMinimumValueofx(0.0)
      clg_part_load_ratio.setMaximumValueofx(1.0)

      clg_cap_f_of_temp_low_spd = OpenStudio::Model::CurveBiquadratic.new(model)
      clg_cap_f_of_temp_low_spd.setCoefficient1Constant(0.42415)
      clg_cap_f_of_temp_low_spd.setCoefficient2x(0.04426)
      clg_cap_f_of_temp_low_spd.setCoefficient3xPOW2(-0.00042)
      clg_cap_f_of_temp_low_spd.setCoefficient4y(0.00333)
      clg_cap_f_of_temp_low_spd.setCoefficient5yPOW2(-0.00008)
      clg_cap_f_of_temp_low_spd.setCoefficient6xTIMESY(-0.00021)
      clg_cap_f_of_temp_low_spd.setMinimumValueofx(17.0)
      clg_cap_f_of_temp_low_spd.setMaximumValueofx(22.0)
      clg_cap_f_of_temp_low_spd.setMinimumValueofy(13.0)
      clg_cap_f_of_temp_low_spd.setMaximumValueofy(46.0)

      clg_energy_input_ratio_f_of_temp_low_spd = OpenStudio::Model::CurveBiquadratic.new(model)
      clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient1Constant(1.23649)
      clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient2x(-0.02431)
      clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient3xPOW2(0.00057)
      clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient4y(-0.01434)
      clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient5yPOW2(0.00063)
      clg_energy_input_ratio_f_of_temp_low_spd.setCoefficient6xTIMESY(-0.00038)
      clg_energy_input_ratio_f_of_temp_low_spd.setMinimumValueofx(17.0)
      clg_energy_input_ratio_f_of_temp_low_spd.setMaximumValueofx(22.0)
      clg_energy_input_ratio_f_of_temp_low_spd.setMinimumValueofy(13.0)
      clg_energy_input_ratio_f_of_temp_low_spd.setMaximumValueofy(46.0)

      clg_coil = OpenStudio::Model::CoilCoolingDXTwoSpeed.new(model,
                                                      always_on,
                                                      clg_cap_f_of_temp,
                                                      clg_cap_f_of_flow,
                                                      clg_energy_input_ratio_f_of_temp,
                                                      clg_energy_input_ratio_f_of_flow,
                                                      clg_part_load_ratio, 
                                                      clg_cap_f_of_temp_low_spd,
                                                      clg_energy_input_ratio_f_of_temp_low_spd)

      clg_coil.setRatedLowSpeedSensibleHeatRatio(OpenStudio::OptionalDouble.new(0.69))
      clg_coil.setBasinHeaterCapacity(10)
      clg_coil.setBasinHeaterSetpointTemperature(2.0)

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
AddSys5PVAVR.new.registerWithApplication