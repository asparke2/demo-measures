#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddAquaThermSystemtoEachApartment < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddAquaThermSystemtoEachApartment"
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

    #create an aquatherm unit for each zone in the model
    #1 hot water loop with a 50 gallon gas hot water heater
    #1 PTAC with hot water heating coil connected to hot water loop, DX cooling coil, and cycling fan
    #1 shower and 1 sink connected to hot water loop

    #define type limits for schedules to avoid extraneous E+ warnings
    temp_sch_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
    temp_sch_type_limits.setName("Temperature Schedule Type Limits")
    temp_sch_type_limits.setLowerLimitValue(0.0)
    temp_sch_type_limits.setUpperLimitValue(100.0)
    temp_sch_type_limits.setNumericType("Continuous")
    temp_sch_type_limits.setUnitType("Temperature")
    
    #define a mixed water temp schedule for the sinks and showers
    #will be used globally by all sinks and showers
    sink_shower_mixed_water_setpoint_temp = OpenStudio::convert(105.0,"F","C").get
    sink_shower_mixed_water_setpoint_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    sink_shower_mixed_water_setpoint_sch.setName("Sink and Shower Mixed Water Temp - 105F")
    sink_shower_mixed_water_setpoint_sch.defaultDaySchedule().setName("Sink and Shower Mixed Water Temp - 105F Default") 
    sink_shower_mixed_water_setpoint_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),sink_shower_mixed_water_setpoint_temp)
    sink_shower_mixed_water_setpoint_sch.setScheduleTypeLimits(temp_sch_type_limits)         
    
    #define a sink to be used in each apartment
    sink_definition = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    sink_definition.setTargetTemperatureSchedule(sink_shower_mixed_water_setpoint_sch) #mixed water setpoint
    sink_definition.setPeakFlowRate(OpenStudio::convert(0.5,"gal/min","m^3/s").get) #0.5 gpm peak flow rate  
      
    #define a shower to be used in each apartment
    shower_definition = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    shower_definition.setTargetTemperatureSchedule(sink_shower_mixed_water_setpoint_sch) #mixed water setpoint
    shower_definition.setPeakFlowRate(OpenStudio::convert(1.0,"gal/min","m^3/s").get) #1.0 gpm peak flow rate   
    
    #make the setpoint schedule for the hot water heaters (and the plant loops)
    #will be used globally for all aquatherm units
    water_heater_setpoint_temp = OpenStudio::convert(140.0,"F","C").get
    water_heater_temp_setpoint_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    water_heater_temp_setpoint_sch.setName("Water Heater Setpoint Temp - 140F")
    water_heater_temp_setpoint_sch.defaultDaySchedule().setName("Water Heater Setpoint Temp - 140F Default") 
    water_heater_temp_setpoint_sch.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),water_heater_setpoint_temp)
    water_heater_temp_setpoint_sch.setScheduleTypeLimits(temp_sch_type_limits)     
    
    model.getThermalZones.each do |zone|
      
      #make a fan on/off so that the unit cycles
      fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
      
      #make a hot water heating coil for the PTAC
      heating_coil = OpenStudio::Model::CoilHeatingWater.new(model, model.alwaysOnDiscreteSchedule)
       
      #make a DX cooling coil for the PTAC

      #coil cooling dx single speed for PTAC
      #from HVACTemplates.cpp System Type 3 Packaged Rooftop Air Conditioner
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setName("ptac_coil_clg_dx_1spd_clg_curve_f_of_temp")
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setCoefficient1Constant(0.42415)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setCoefficient2x(0.04426)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setCoefficient3xPOW2(-0.00042)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setCoefficient4y(0.00333)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setCoefficient5yPOW2(-0.00008)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setCoefficient6xTIMESY(-0.00021)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setMinimumValueofx(17.0)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setMaximumValueofx(22.0)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setMinimumValueofy(13.0)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_temp.setMaximumValueofy(46.0)

      ptac_coil_clg_dx_1spd_clg_curve_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_flow.setName("ptac_coil_clg_dx_1spd_clg_curve_f_of_flow")
      ptac_coil_clg_dx_1spd_clg_curve_f_of_flow.setCoefficient1Constant(0.77136)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_flow.setCoefficient2x(0.34053)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_flow.setCoefficient3xPOW2(-0.11088)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_flow.setMinimumValueofx(0.75918)
      ptac_coil_clg_dx_1spd_clg_curve_f_of_flow.setMaximumValueofx(1.13877)

      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setName("ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp")
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setCoefficient1Constant(1.23649)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setCoefficient2x(-0.02431)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(0.00057)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setCoefficient4y(-0.01434)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.00063)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.00038)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setMinimumValueofx(17.0)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setMaximumValueofx(22.0)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setMinimumValueofy(13.0)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp.setMaximumValueofy(46.0)

      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow.setName("ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow")
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.20550)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow.setCoefficient2x(-0.32953)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.12308)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow.setMinimumValueofx(0.75918)
      ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow.setMaximumValueofx(1.13877)

      ptac_coil_clg_dx_1spd_part_load_fraction = OpenStudio::Model::CurveQuadratic.new(model)
      ptac_coil_clg_dx_1spd_part_load_fraction.setName("ptac_coil_clg_dx_1spd_part_load_fraction")
      ptac_coil_clg_dx_1spd_part_load_fraction.setCoefficient1Constant(0.77100)
      ptac_coil_clg_dx_1spd_part_load_fraction.setCoefficient2x(0.22900)
      ptac_coil_clg_dx_1spd_part_load_fraction.setCoefficient3xPOW2(0.0)
      ptac_coil_clg_dx_1spd_part_load_fraction.setMinimumValueofx(0.0)
      ptac_coil_clg_dx_1spd_part_load_fraction.setMaximumValueofx(1.0)      
      
      cooling_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model,
                                                                    model.alwaysOnDiscreteSchedule,
                                                                    ptac_coil_clg_dx_1spd_clg_curve_f_of_temp,
                                                                    ptac_coil_clg_dx_1spd_clg_curve_f_of_flow,
                                                                    ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_temp,
                                                                    ptac_coil_clg_dx_1spd_energy_input_ratio_f_of_flow,
                                                                    ptac_coil_clg_dx_1spd_part_load_fraction) 

      
      #make the PTAC terminal itself
      ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model,
                                                                    model.alwaysOnDiscreteSchedule,
                                                                    fan,
                                                                    heating_coil,
                                                                    cooling_coil)
                                                                    
      #add the PTAC to ther zone
      puts "adding ptac to zone = #{ptac.addToThermalZone(zone)}"
    
      #make a small constant speed pump to move water to the heating coil
      pump = OpenStudio::Model::PumpConstantSpeed.new(model)
      pump.setRatedPumpHead(OpenStudio::convert(2.0, "ftH_{2}O","Pa").get) #TODO make pump head realistic
      
      #make a gas-fired hot water heater
      water_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
      water_heater.setTankVolume(OpenStudio::convert(50.0,"gal","m^3").get) #50 gallon tank
      water_heater.setHeaterFuelType("NaturalGas") #natural gas
      water_heater.setHeaterThermalEfficiency(0.70) #70% efficient burner
      water_heater.setSetpointTemperatureSchedule(water_heater_temp_setpoint_sch) #assign the global water heater setpoint sch
      water_heater.setAmbientTemperatureIndicator("ThermalZone")
      water_heater.setAmbientTemperatureThermalZone(zone)
      
      #make the sink
      sink = OpenStudio::Model::WaterUseEquipment.new(sink_definition)
      #TODO set sink flow rate schedule
      #assign the sink to the first space in the thermal zone
      #so that the loads go into the zones      
      sink.setSpace(zone.spaces[0])
      
      #make the shower
      shower = OpenStudio::Model::WaterUseEquipment.new(shower_definition)
      #TODO set shower flow rate schedule    
      #assign the sink to the first space in the thermal zone
      #so that the loads go into the zone
      sink.setSpace(zone.spaces[0])      
      
      #make a water use connections object to connect the sink and shower to the hot water loop
      water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
      water_use_connection.addWaterUseEquipment(sink) #connect the sink
      water_use_connection.addWaterUseEquipment(shower) #connect the shower
      
      #make a hot water plant loop
      hot_water_loop = OpenStudio::Model::PlantLoop.new(model)
      hot_water_loop.setName("Zone #{zone.name.get} Hot Water Loop")
      hot_water_loop.setMaximumLoopTemperature(OpenStudio::convert(212.0,"F","C").get) #max of 212F, obviously
      hot_water_loop.sizingPlant.setLoopType("Heating")
      hot_water_loop.sizingPlant.setDesignLoopExitTemperature(water_heater_setpoint_temp)
      hot_water_loop.sizingPlant.setLoopDesignTemperatureDifference(OpenStudio::convert(20.0,"R","K").get) #20F delta T for sizing
      
      #make a setpoint manager to control the hot water plant loop temp
      #uses the same temp schedule as the hot water heater itself
      hot_water_stpt_manager = OpenStudio::Model::SetpointManagerScheduled.new(model,water_heater_temp_setpoint_sch)
      hot_water_loop.supplyOutletNode.addSetpointManager(hot_water_stpt_manager)
      
      #attach the hot water heater, the hot water coil, the water use connection,
      #and the pump to the hot water loop in this zone
      hot_water_loop.addSupplyBranchForComponent(water_heater)
      hot_water_loop.addDemandBranchForComponent(heating_coil)
      hot_water_loop.addDemandBranchForComponent(water_use_connection)
      pump.addToNode(hot_water_loop.supplyInletNode)
      
    end

    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddAquaThermSystemtoEachApartment.new.registerWithApplication