#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys1PTACResidential < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add Sys 1 - PTAC Residential"
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

    # System Type 1: PTAC, Residential
    # This measure creates:
    # a single hot water loop with natural gas boiler for the building
    # a constant volume packaged terminal A/C unit with hot water heat 
    # and DX cooling for each zone in the building
    
    # How water loop
    hot_water_plant = OpenStudio::Model::PlantLoop.new(model)
    hot_water_plant.setName("Hot Water Loop")
    sizing_plant = hot_water_plant.sizingPlant
    sizing_plant.setLoopType("Heating")
    sizing_plant.setDesignLoopExitTemperature(82.0) # TODO units
    sizing_plant.setLoopDesignTemperatureDifference(11.0) # TODO units

    hot_water_outlet_node = hot_water_plant.supplyOutletNode
    hot_water_inlet_node = hot_water_plant.supplyInletNode

    pump = OpenStudio::Model::PumpVariableSpeed.new(model)

    boiler_htg_eff_f_of_part_load_ratio = OpenStudio::Model::CurveBiquadratic.new(model)
    boiler_htg_eff_f_of_part_load_ratio.setName("Constant Boiler Efficiency")
    boiler_htg_eff_f_of_part_load_ratio.setCoefficient1Constant(1.0)
    boiler_htg_eff_f_of_part_load_ratio.setInputUnitTypeforX("Dimensionless")
    boiler_htg_eff_f_of_part_load_ratio.setInputUnitTypeforY("Dimensionless")
    boiler_htg_eff_f_of_part_load_ratio.setOutputUnitType("Dimensionless")

    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setNormalizedBoilerEfficiencyCurve(boiler_htg_eff_f_of_part_load_ratio)
    boiler.setEfficiencyCurveTemperatureEvaluationVariable("LeavingBoiler")
    
    boiler_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    
    hot_water_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    
    # Add the equipment to the hot water plant loop
    pump.addToNode(hot_water_inlet_node)

    hot_water_plant.addSupplyBranchForComponent(boiler)

    hot_water_plant.addSupplyBranchForComponent(boiler_bypass_pipe)

    hot_water_outlet_pipe.addToNode(hot_water_outlet_node)

    # Add temperature setpoint control for the loop
    
    # Make the hot water schedule
    twenty_four_hrs = OpenStudio::Time.new(0,24,0,0)
    hot_water_temp = 67 # TODO units
    hot_water_temp_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    hot_water_temp_sch.setName("Hot Water Temp")
    hot_water_temp_schWinter = OpenStudio::Model::ScheduleDay.new(model)
    hot_water_temp_sch.setWinterDesignDaySchedule(hot_water_temp_schWinter)
    hot_water_temp_sch.winterDesignDaySchedule().setName("Hot Water Temp Winter Design Day")
    hot_water_temp_sch.winterDesignDaySchedule().addValue(twenty_four_hrs,hot_water_temp)
    hot_water_temp_schSummer = OpenStudio::Model::ScheduleDay.new(model)
    hot_water_temp_sch.setSummerDesignDaySchedule(hot_water_temp_schSummer)
    hot_water_temp_sch.summerDesignDaySchedule().setName("Hot Water Temp Summer Design Day")
    hot_water_temp_sch.summerDesignDaySchedule().addValue(twenty_four_hrs,hot_water_temp)  
    hot_water_temp_sch.defaultDaySchedule().setName("Hot Water Temp Default")
    hot_water_temp_sch.defaultDaySchedule().addValue(twenty_four_hrs,hot_water_temp)

    hot_water_setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,hot_water_temp_sch)

    hot_water_setpoint_manager.addToNode(hot_water_outlet_node)
    
    always_on = model.alwaysOnDiscreteSchedule
  
    # Make a PTAC with hot water heating and DX cooling for each zone
    # and connect the hot water coil to the hot water plant loop
    model.getThermalZones.each do |zone|
  
      fan = OpenStudio::Model::FanConstantVolume.new(model,always_on)
      fan.setPressureRise(500) #TODO units

      htg_coil = OpenStudio::Model::CoilHeatingWater.new(model,always_on)

      clg_cap_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      clg_cap_f_of_temp.setCoefficient1Constant(0.942587793)
      clg_cap_f_of_temp.setCoefficient2x(0.009543347)
      clg_cap_f_of_temp.setCoefficient3xPOW2(0.000683770)
      clg_cap_f_of_temp.setCoefficient4y(-0.011042676)
      clg_cap_f_of_temp.setCoefficient5yPOW2(0.000005249)
      clg_cap_f_of_temp.setCoefficient6xTIMESY(-0.000009720)
      clg_cap_f_of_temp.setMinimumValueofx(17.0)
      clg_cap_f_of_temp.setMaximumValueofx(22.0)
      clg_cap_f_of_temp.setMinimumValueofy(13.0)
      clg_cap_f_of_temp.setMaximumValueofy(46.0)

      clg_cap_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      clg_cap_f_of_flow.setCoefficient1Constant(0.8)
      clg_cap_f_of_flow.setCoefficient2x(0.2)
      clg_cap_f_of_flow.setCoefficient3xPOW2(0.0)
      clg_cap_f_of_flow.setMinimumValueofx(0.5)
      clg_cap_f_of_flow.setMaximumValueofx(1.5)

      energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      energy_input_ratio_f_of_temp.setCoefficient1Constant(0.342414409)
      energy_input_ratio_f_of_temp.setCoefficient2x(0.034885008)
      energy_input_ratio_f_of_temp.setCoefficient3xPOW2(-0.000623700)
      energy_input_ratio_f_of_temp.setCoefficient4y(0.004977216)
      energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.000437951)
      energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.000728028)
      energy_input_ratio_f_of_temp.setMinimumValueofx(17.0)
      energy_input_ratio_f_of_temp.setMaximumValueofx(22.0)
      energy_input_ratio_f_of_temp.setMinimumValueofy(13.0)
      energy_input_ratio_f_of_temp.setMaximumValueofy(46.0)

      energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      energy_input_ratio_f_of_flow.setCoefficient1Constant(1.1552)
      energy_input_ratio_f_of_flow.setCoefficient2x(-0.1808)
      energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.0256)
      energy_input_ratio_f_of_flow.setMinimumValueofx(0.5)
      energy_input_ratio_f_of_flow.setMaximumValueofx(1.5)

      part_load_fraction = OpenStudio::Model::CurveQuadratic.new(model)
      part_load_fraction.setCoefficient1Constant(0.85)
      part_load_fraction.setCoefficient2x(0.15)
      part_load_fraction.setCoefficient3xPOW2(0.0)
      part_load_fraction.setMinimumValueofx(0.0)
      part_load_fraction.setMaximumValueofx(1.0)

      clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model,
                                                                 always_on,
                                                                 clg_cap_f_of_temp,
                                                                 clg_cap_f_of_flow,
                                                                 energy_input_ratio_f_of_temp,
                                                                 energy_input_ratio_f_of_flow,
                                                                 part_load_fraction)

      ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model,
                                                                          always_on, 
                                                                          fan,
                                                                          htg_coil,
                                                                          clg_coil)

      ptac.setName("#{zone.name} PTAC")
      ptac.addToThermalZone(zone)

      hot_water_plant.addDemandBranchForComponent(htg_coil)
      
    end

      
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSys1PTACResidential.new.registerWithApplication