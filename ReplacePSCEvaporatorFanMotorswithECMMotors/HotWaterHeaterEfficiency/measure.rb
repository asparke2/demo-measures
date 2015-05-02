#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class HotWaterHeaterEfficiency < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Hot Water Heater Efficiency"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #populate choice argument for water_heaters
    water_heater_handles = OpenStudio::StringVector.new
    water_heater_names = OpenStudio::StringVector.new
    model.getWaterHeaterMixeds.each do |water_heater|
      water_heater_handles << water_heater.handle.to_s
      water_heater_names << water_heater.name.to_s
    end
    building = model.getBuilding
    water_heater_handles << building.handle.to_s
    water_heater_names << "*All Water Heaters*"
    
    #make an argument to select water_heater to modify
    water_heater_object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("water_heater_object", water_heater_handles, water_heater_names,true)
    water_heater_object.setDisplayName("Choose a Water Heater to Alter.")
    water_heater_object.setDefaultValue("*All Water Heaters*") #if no water_heater is chosen this will run on all water heaters
    args << water_heater_object    
    
    #make an argument to add new space true/false
    water_heater_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("water_heater_eff",true)
    water_heater_eff.setDisplayName("Water Heater Efficiency (%).")
    args << water_heater_eff
    
    #make an argument for material and installation cost
    material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)
    material_cost.setDisplayName("Material and Installation Costs per Water Heater ($).")
    material_cost.setDefaultValue(0.0)
    args << material_cost

    #make an argument for expected life
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life (whole years).")
    expected_life.setDefaultValue(20)
    args << expected_life    

    return args
  end #end the arguments method

  #define what happens when the measure is cop
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
       
    #assign the user inputs to variables
    water_heater_object = runner.getOptionalWorkspaceObjectChoiceValue("water_heater_object",user_arguments,model)
    water_heater_eff = runner.getDoubleArgumentValue("water_heater_eff",user_arguments)
    material_cost = runner.getDoubleArgumentValue("material_cost",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)
    
    # Set default for cost to start at year 0
    years_until_costs_start = 0

    #check that the selected water_heater still exists
    apply_to_all_water_heaters = false
    water_heater = nil
    if water_heater_object.empty?
      handle = runner.getStringArgumentValue("water_heater",user_arguments)
      if handle.empty?
        runner.registerError("No water heater was chosen.")
      else
        runner.registerError("The selected water heater with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if water_heater_object.get.to_WaterHeaterMixed.is_initialized
        water_heater = water_heater_object.get.to_WaterHeaterMixed.get
      elsif not water_heater_object.get.to_Building.empty?
        apply_to_all_water_heaters = true
      else
        runner.registerError("Script Error - argument not showing up as water heater.")
        return false
      end
    end
    
    #check the water_heater efficiency for reasonableness
    if water_heater_eff <= 0 or  water_heater_eff >= 100
      runner.registerError("Please enter a number between 0 and 100 for water heater efficiency percentage.")
      return false
    end

    # Check the expected life
    if not expected_life >= 1 and not expected_life <= 100
      runner.registerError("Choose an integer greater than 0 and less than or equal to 100 for Expected Life.")
    end

    # Set the list of water_heaters to modify
    water_heaters = []
    if apply_to_all_water_heaters
      water_heaters = model.getWaterHeaterMixeds
    else
      water_heaters << water_heater #only run on a single water_heater
    end
    
    # Set the efficiency for selected water_heaters and
    # add a first cost for each water_heater
    water_heaters.each do |water_heater|
      water_heater_initial_eff = water_heater.heaterThermalEfficiency.get #TODO error trap this
      water_heater.setHeaterThermalEfficiency(water_heater_eff / 100.0)
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{water_heater.name}", water_heater, material_cost, "CostPerEach", "Construction", expected_life, years_until_costs_start)
      runner.registerInfo("Changed thermal efficiency of water heater '#{water_heater.name}' from #{(water_heater_initial_eff*100).round}% to #{water_heater_eff}% for a cost of $#{material_cost}.")
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
HotWaterHeaterEfficiency.new.registerWithApplication