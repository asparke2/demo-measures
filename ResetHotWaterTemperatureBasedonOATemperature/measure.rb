#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ResetHotWaterTemperatureBasedonOATemperature < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResetHotWaterTemperatureBasedonOATemperature"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #populate choice argument for heating plant loops in the model
    plant_loop_handles = OpenStudio::StringVector.new
    plant_loop_display_names = OpenStudio::StringVector.new
    model.getPlantLoops.each do |plant_loop|
      if plant_loop.sizingPlant.loopType == "Heating"
        plant_loop_handles << plant_loop.handle.to_s
        plant_loop_display_names << plant_loop.name.get
      end
    end

    #make an argument for plant loops
    plant_loop_object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("plant_loop_object", plant_loop_handles, plant_loop_display_names,true)
    plant_loop_object.setDisplayName("Choose a Plant Loop to Control via OA Reset.")
    args << plant_loop_object

    #make an argument for low OA temp
    lo_oat_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("lo_oat_f",true)
    lo_oat_f.setDisplayName("Low OA Temp (F).")
    lo_oat_f.setDefaultValue(20.0)
    args << lo_oat_f    
    
    #make an argument for HTW at low OA temp
    hw_temp_lo_oat_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_temp_lo_oat_f",true)
    hw_temp_lo_oat_f.setDisplayName("Water Temp at Low OA Temp (F).")
    hw_temp_lo_oat_f.setDefaultValue(180.0)
    args << hw_temp_lo_oat_f      
    
    #make an argument for hi OA temp
    hi_oat_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hi_oat_f",true)
    hi_oat_f.setDisplayName("Hi OA Temp (F).")
    hi_oat_f.setDefaultValue(50.0)
    args << hi_oat_f    
    
    #make an argument for HTW at hi OA temp
    hw_temp_hi_oat_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hw_temp_hi_oat_f",true)
    hw_temp_hi_oat_f.setDisplayName("Water Temp at Hi OA Temp (F).")
    hw_temp_hi_oat_f.setDefaultValue(150.0)
    args << hw_temp_hi_oat_f          
    
    #make an argument for material and installation cost
    material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)
    material_cost.setDisplayName("Material and Installation Costs per Plant Loop ($).")
    material_cost.setDefaultValue(0.0)
    args << material_cost

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assume the control strategy will last the full analysis
    expected_life = 25    
    
    #assign the user inputs to variables
    plant_loop_object = runner.getOptionalWorkspaceObjectChoiceValue("plant_loop_object",user_arguments,model)
    lo_oat_f = runner.getDoubleArgumentValue("lo_oat_f",user_arguments)
    hw_temp_lo_oat_f = runner.getDoubleArgumentValue("hw_temp_lo_oat_f",user_arguments)
    hi_oat_f = runner.getDoubleArgumentValue("hi_oat_f",user_arguments)
    hw_temp_hi_oat_f = runner.getDoubleArgumentValue("hw_temp_hi_oat_f",user_arguments)    
    material_cost = runner.getDoubleArgumentValue("material_cost",user_arguments)
 
    #make sure the selected plant loop is still in the model
    plant_loop = nil
    if plant_loop_object.empty?
      runner.registerError("The selected air loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      return false
    else
      if plant_loop_object.get.to_PlantLoop.is_initialized
        plant_loop = plant_loop_object.get.to_PlantLoop.get
      else
        runner.registerError("Script Error - argument not showing up as plant loop.")
        return false
      end
    end
    
    #create the OA reset setpoint manager
    lo_oat_c = OpenStudio::convert(lo_oat_f,"F","C").get
    hw_temp_lo_oat_c = OpenStudio::convert(hw_temp_lo_oat_f,"F","C").get
    hi_oat_c = OpenStudio::convert(hi_oat_f,"F","C").get
    hw_temp_hi_oat_c = OpenStudio::convert(hw_temp_hi_oat_f,"F","C").get
    hw_stpt_manager = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
    hw_stpt_manager.setSetpointatOutdoorLowTemperature(hw_temp_lo_oat_c)
    hw_stpt_manager.setOutdoorLowTemperature(lo_oat_c)
    hw_stpt_manager.setSetpointatOutdoorHighTemperature(hw_temp_hi_oat_c)
    hw_stpt_manager.setOutdoorHighTemperature(hi_oat_c)      
    
    #add the setpoint manager to the plant loop
    plant_loop.supplyOutletNode.addSetpointManager(hw_stpt_manager)
    
    #add the cost to the plant loop
    if material_cost != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Change #{plant_loop.name.get} HW Setpoint to OA Reset", plant_loop, material_cost, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end    
    
    #register the initial condition
    runner.registerInitialCondition("The hot water temperature setpoint for the heating plant loop in this building is controlled by a schedule")
    
    #register the final condition
    runner.registerFinalCondition("The hot water temperature setpoint was changed to be reset based on OA temp.  The setpoint will be #{hw_temp_lo_oat_f}F below #{lo_oat_f}, increasing linearly up to #{hw_temp_hi_oat_f}F when the outdoor air is above #{hi_oat_f}F.  This was accomplished for a cost of $#{material_cost.round}")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResetHotWaterTemperatureBasedonOATemperature.new.registerWithApplication