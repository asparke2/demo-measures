#see the URL below for information on how to write OpenStudio measures
# http:#openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http:#openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http:#openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys8VAVwPFPBoxes < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddSys8VAVwPFPBoxes"
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

    # System Type 8: VAV w/ PFP Boxes and Reheat
    # This measure creates:
    # a single chilled water loop with air cooled chiller for the building
    # a VAV system w/ electric heat, chilled water cooling, and electric reheat
    # in parallel fan powered terminal for each story of the building
    always_on = model.alwaysOnDiscreteSchedule

    # Chilled Water Plant

    chw_loop = OpenStudio::Model::PlantLoop.new(model)
    chw_loop.setName("Chilled Water Loop for VAV with PFP Boxes")
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
    
    # Make a Packaged VAV w/ PFP Boxes for each story of the building
    model.getBuildingStorys.sort.each do |story|    
      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("VAV with PFP Boxes and Reheat")
      sizingSystem = air_loop.sizingSystem
      sizingSystem.setCentralCoolingDesignSupplyAirTemperature(12.8)
      sizingSystem.setCentralHeatingDesignSupplyAirTemperature(12.8)    
      
      fan = OpenStudio::Model::FanVariableVolume.new(model,always_on)
      fan.setPressureRise(500)

      htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model,always_on)

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

      # Make a PFP terminal with electric reheat for each zone
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
    
    end # Next story
    
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSys8VAVwPFPBoxes.new.registerWithApplication