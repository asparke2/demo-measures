#see the URL below for information on how to write OpenStudio measures
# http:#openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http:#openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http:#openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys6PVAVwPFPBoxes < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add Sys 6 - PVAV w/ PFP Boxes"
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

    # System Type 6: Packaged VAV w/ PFP Boxes
    # This measure creates:
    # a VAV system w/ electric heating, DX cooling, and electric reheat 
    # in a parallel fan powered terminal for each story of the building
    
    always_on = model.alwaysOnDiscreteSchedule

    # Make a Packaged VAV w/ PFP Boxes for each story of the building
    model.getBuildingStorys.sort.each do |story|

      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("#{story.name} Packaged Rooftop VAV with PFP Boxes and Reheat")    

      fan = OpenStudio::Model::FanVariableVolume.new(model,always_on)
      fan.setPressureRise(500)    

      htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model,always_on)
      
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
      
      # Make a PFP terminal with electric reheat for each zone on this story
      zones.each do |zone|
        pfp_fan = OpenStudio::Model::FanConstantVolume.new(model,always_on)
        pfp_fan.setPressureRise(300)
        reheat_coil = OpenStudio::Model::CoilHeatingElectric.new(model,always_on)
        pfp_terminal = OpenStudio::Model::AirTerminalSingleDuctParallelPIUReheat.new(model,
                                                                                    always_on,
                                                                                    pfp_fan,
                                                                                    reheat_coil)
        air_loop.addBranchForZone(zone,pfp_terminal.to_StraightComponent)
      end  
    
    end # next story
    
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSys6PVAVwPFPBoxes.new.registerWithApplication