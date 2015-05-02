#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddSys9GasFiredWarmAirFurnace < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddSys9GasFiredWarmAirFurnace"
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

    # System Type 9: Gas Fired Warm Air Furnace
    # This measure creates:
    # a constant volume furnace with gas heating and no cooling
    # for each zone in the building
        
    # Make a furnace with gas heating and no cooling for each zone
    always_on = model.alwaysOnDiscreteSchedule
  
    model.getThermalZones.each do |zone|

      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("Gas Furnace")
      sizingSystem = air_loop.sizingSystem
      sizingSystem.setTypeofLoadtoSizeOn("Sensible")
      sizingSystem.autosizeDesignOutdoorAirFlowRate()
      sizingSystem.setMinimumSystemAirFlowRatio(1.0)
      sizingSystem.setPreheatDesignTemperature(7.0)
      sizingSystem.setPreheatDesignHumidityRatio(0.008)
      sizingSystem.setPrecoolDesignTemperature(12.8)
      sizingSystem.setPrecoolDesignHumidityRatio(0.008)
      sizingSystem.setCentralCoolingDesignSupplyAirTemperature(12.8)
      sizingSystem.setCentralHeatingDesignSupplyAirTemperature(40.0)
      sizingSystem.setSizingOption("NonCoincident")
      sizingSystem.setAllOutdoorAirinCooling(false)
      sizingSystem.setAllOutdoorAirinHeating(false)
      sizingSystem.setCentralCoolingDesignSupplyAirHumidityRatio(0.0085)
      sizingSystem.setCentralHeatingDesignSupplyAirHumidityRatio(0.0080)
      sizingSystem.setCoolingDesignAirFlowMethod("DesignDay")
      sizingSystem.setCoolingDesignAirFlowRate(0.0)
      sizingSystem.setHeatingDesignAirFlowMethod("DesignDay")
      sizingSystem.setHeatingDesignAirFlowRate(0.0)
      sizingSystem.setSystemOutdoorAirMethod("ZoneSum") 
      
      fan = OpenStudio::Model::FanConstantVolume.new(model,always_on)
      fan.setPressureRise(500)

      htg_coil = OpenStudio::Model::CoilHeatingGas.new(model,always_on)

      oa_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)

      oa_system = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model,oa_controller)      
      
      # Add the components to the air loop
      # in order from closest to zone to furthest from zone
      supply_inlet_node = air_loop.supplyInletNode
      supply_outlet_node = air_loop.supplyOutletNode    
      fan.addToNode(supply_inlet_node)
      htg_coil.addToNode(supply_inlet_node)
      oa_system.addToNode(supply_inlet_node)    

      # Add a setpoint manager single zone reheat to control the
      # supply air temperature based on the needs of this zone
      setpoint_mgr_single_zone_reheat = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
      setpoint_mgr_single_zone_reheat.setControlZone(zone)
      setpoint_mgr_single_zone_reheat.addToNode(supply_outlet_node)
      
      # Create a diffuser and attach the zone/diffuser pair to the air loop
      diffuser = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model,always_on) 
      air_loop.addBranchForZone(zone,diffuser.to_StraightComponent)  
      
    end

      
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSys9GasFiredWarmAirFurnace.new.registerWithApplication