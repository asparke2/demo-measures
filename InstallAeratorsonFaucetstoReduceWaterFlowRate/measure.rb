#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class InstallAeratorsonFaucetstoReduceWaterFlowRate < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "InstallAeratorsonFaucetstoReduceWaterFlowRate"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make a choice argument for model objects
    water_fixture_def_display_names = OpenStudio::StringVector.new
    water_fixture_def_handles = OpenStudio::StringVector.new
    
    #putting model object and names into hash
    model.getWaterUseEquipmentDefinitions.each do |water_fixture_def|
      water_fixture_def_display_names << water_fixture_def.name.to_s
      water_fixture_def_handles << water_fixture_def.handle.to_s
    end
        
    #make a choice argument for the light fixture to replace
    water_fixture_def = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("water_fixture_def", water_fixture_def_handles, water_fixture_def_display_names)
    water_fixture_def.setDisplayName("Choose a Water Fixture Type to Install Aerators On.")
    args << water_fixture_def

    #make an argument for the number of lamps
    pct_flow_reduction = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pct_flow_reduction",true)
    pct_flow_reduction.setDisplayName("Percent Flow Reduction (%)")
    pct_flow_reduction.setDefaultValue(50.0)
    args << pct_flow_reduction
   
    #make an argument for material and installation cost per fixture
    material_and_installation_cost_per_fixture = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost_per_fixture",true)
    material_and_installation_cost_per_fixture.setDisplayName("Cost to Install Aerators per Fixture ($).")
    material_and_installation_cost_per_fixture.setDefaultValue(0.0)
    args << material_and_installation_cost_per_fixture
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assume the aerator will last the full analysis
    expected_life = 25
    
    #assign the user inputs to variables
    water_fixture_def_object = runner.getOptionalWorkspaceObjectChoiceValue("water_fixture_def",user_arguments,model)
    pct_flow_reduction = runner.getDoubleArgumentValue("pct_flow_reduction",user_arguments)
    material_and_installation_cost_per_fixture = runner.getDoubleArgumentValue("material_and_installation_cost_per_fixture",user_arguments)
      
    #check the water_fixture_def argument to make sure it still is in the model
    water_fixture_def = nil
    if water_fixture_def_object.empty?
      handle = runner.getStringArgumentValue("water_fixture_def",user_arguments)
      if handle.empty?
        runner.registerError("No water fixture definition was chosen.")
      else
        runner.registerError("The selected water fixture definition with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if water_fixture_def_object.get.to_WaterUseEquipmentDefinition.is_initialized
        water_fixture_def = water_fixture_def_object.get.to_WaterUseEquipmentDefinition.get
        runner.registerInfo("Modifying the flow rate of #{water_fixture_def.name.get}.")
      end
    end
    
    #count the number of these fixtures in the building
    num_fixtures_modified = water_fixture_def.instances.size
    original_name = water_fixture_def.name.get
    original_flow_rate_m3_per_sec = water_fixture_def.peakFlowRate
    original_flow_rate_gpm = OpenStudio::convert(original_flow_rate_m3_per_sec, "m^3/s","gal/min").get
    runner.registerInitialCondition("This building has (#{num_fixtures_modified}) #{original_name}s.  These fixtures have a flow rate of #{original_flow_rate_gpm}gpm, which is much higher than necessary for washing.")

    #check to make sure the measure is applicable
    if num_fixtures_modified == 0
      runner.registerAsNotApplicable("This measure is not applicable.  No #{original_name}s could be found in the building.")
      return true
    end
    
    #find the fixture and reduce it's flow rate per the user input
    runner.registerInfo("pct_flow_reduction = #{pct_flow_reduction}")
    pct_flow_reduction_multiplier = (100 - pct_flow_reduction)/100
    new_flow_rate_m3_per_sec = original_flow_rate_m3_per_sec * pct_flow_reduction_multiplier
    runner.registerInfo("original flow rate = #{original_flow_rate_m3_per_sec}m^3/s, multiplier = #{pct_flow_reduction_multiplier}, new flow rate = #{new_flow_rate_m3_per_sec}m^3/s")
    water_fixture_def.setPeakFlowRate(new_flow_rate_m3_per_sec)
    new_flow_rate_gpm = OpenStudio::convert(new_flow_rate_m3_per_sec, "m^3/s","gal/min").get
    water_fixture_def.setName("#{original_name} with Aerator")
    runner.registerInfo("Reduced the peak flow rate of #{original_name} by #{pct_flow_reduction}%, from #{original_flow_rate_gpm}gpm to #{new_flow_rate_gpm}gpm.")
    #add the cost per aerator * number of aerators to the building
    if material_and_installation_cost_per_fixture != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Add Aerators to #{num_fixtures_modified} #{original_name}", model.getBuilding, material_and_installation_cost_per_fixture * num_fixtures_modified, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end      
    
    #report the final condition
    runner.registerFinalCondition("Added aerators to (#{num_fixtures_modified}) #{original_name}s in the building, reducing their peak flow rate by #{pct_flow_reduction}%, from #{original_flow_rate_gpm}gpm down to #{new_flow_rate_gpm}gpm.  This was accomplished at a cost of $#{material_and_installation_cost_per_fixture} per fixture, for a total cost of $#{(material_and_installation_cost_per_fixture * num_fixtures_modified).round}.")
 
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
InstallAeratorsonFaucetstoReduceWaterFlowRate.new.registerWithApplication