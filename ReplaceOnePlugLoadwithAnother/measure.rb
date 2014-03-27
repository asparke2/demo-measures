#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReplaceOnePlugLoadwithAnother < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace One Plug Load with Another"
  end
  
  #define the arguments that the user will input
  def arguments(model)
   args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    #looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key,value|
      #only include if space type is used in the model
      if value.spaces.size > 0
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end

    #add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << "*Entire Building*"

    #make a choice argument for space type
    space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_handles, space_type_display_names)
    space_type.setDisplayName("Replace Plug Loads in a Specific Space Type or in the Entire Model.")
    space_type.setDefaultValue("*Entire Building*") #if no space type is chosen this will run on the entire building
    args << space_type    
    
    #make a choice argument for model objects
    plug_def_handles = OpenStudio::StringVector.new
    plug_def_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    model.getElectricEquipmentDefinitions.each do |plug_def|
      plug_def_display_names << plug_def.name.to_s
      plug_def_handles << plug_def.handle.to_s
    end
        
    #make a choice argument for the plug load to replace
    plug_def = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("plug_def", plug_def_handles, plug_def_display_names)
    plug_def.setDisplayName("Choose a Plug Load Type to Replace.")
    args << plug_def

    #make an argument for the name of the new fixture
    new_plug_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("new_plug_name",true)
    new_plug_name.setDisplayName("Name of the New Plug Load.")
    new_plug_name.setDefaultValue("Replacement Plug Load")
    args << new_plug_name    
    
    #make an argument for the power of the new fixture
    power_per_plug = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("power_per_plug",true)
    power_per_plug.setDisplayName("Power of New Plug Load at Full Power (W).")
    args << power_per_plug
      
    #make an argument for the percent of time on
    run_percent = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("run_percent",true)
    run_percent.setDisplayName("Percent of Time at Full Power (%).")
    run_percent.setDefaultValue(100)
    args << run_percent    
    
    #make an argument for material and installation cost per plug load
    material_and_installation_cost_per_plug = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost_per_plug",true)
    material_and_installation_cost_per_plug.setDisplayName("Material and Installation Cost per Item Replaced.")
    material_and_installation_cost_per_plug.setDefaultValue(0.0)
    args << material_and_installation_cost_per_plug

    #make an argument for material and installation cost per plug load
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life of the Items Replaced.")
    expected_life.setDefaultValue(25)
    args << expected_life    
    
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    space_type_object = runner.getOptionalWorkspaceObjectChoiceValue("space_type",user_arguments,model)
    plug_def_object = runner.getOptionalWorkspaceObjectChoiceValue("plug_def",user_arguments,model)
    new_plug_name = runner.getStringArgumentValue("new_plug_name",user_arguments)
    power_per_plug = runner.getDoubleArgumentValue("power_per_plug",user_arguments)
    run_percent = runner.getIntegerArgumentValue("run_percent",user_arguments)
    material_and_installation_cost_per_plug = runner.getDoubleArgumentValue("material_and_installation_cost_per_plug",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)
      
    #check the plug_def argument to make sure it still is in the model
    plug_def = nil
    if plug_def_object.empty?
      handle = runner.getStringArgumentValue("plug_def",user_arguments)
      if handle.empty?
        runner.registerError("No plug load definition was chosen.")
      else
        runner.registerError("The selected plug load definition with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if plug_def_object.get.to_ElectricEquipmentDefinition.is_initialized
        plug_def = plug_def_object.get.to_ElectricEquipmentDefinition.get
      end
    end

    #check the space_type for reasonableness and see if measure should run on space type or on the entire building
    apply_to_building = false
    space_type = nil
    if space_type_object.empty?
      handle = runner.getStringArgumentValue("space_type",user_arguments)
      if handle.empty?
        runner.registerError("No space type was chosen.")
      else
        runner.registerError("The selected space type with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not space_type_object.get.to_SpaceType.empty?
        space_type = space_type_object.get.to_SpaceType.get
      elsif not space_type_object.get.to_Building.empty?
        apply_to_building = true
      else
        runner.registerError("Script Error - argument not showing up as space type or building.")
        return false
      end
    end
    
    #check arguments for reasonableness
    if run_percent > 100 or run_percent < 0
      runner.registerError("Percent on must be between 0 and 100.")
      return false
    end
    
    #make the new plug load
    new_plug_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    new_plug_wattage = power_per_plug * (run_percent/100)
    new_plug_def.setDesignLevel(new_plug_wattage)
    #name format is like this:  "1000W User Defined Name Running 50% of the Time" or "1000W User Defined Name"
    name = nil
    if run_percent == 100
      name = "#{power_per_plug}W #{new_plug_name}"
    else
      name = "#{power_per_plug}W #{new_plug_name} Running #{run_percent} of the Time"
    end
    #set the plug load name
    new_plug_def.setName(name)
    
    #replace all of the plug loads of a given type
    #with the new plug load
    number_of_plugs_replaced = 0
    if apply_to_building #apply to the whole building
      model.getElectricEquipments.each do |plug_load|
        if plug_load.electricEquipmentDefinition == plug_def
          plug_load.setElectricEquipmentDefinition(new_plug_def)
          number_of_plugs_replaced += plug_load.multiplier
        end
      end
    else #apply to the a specific space type
      #do the plug loads assigned to the space type itself
      space_type.electricEquipment.each do |plug_load|
        if plug_load.electricEquipmentDefinition == plug_def
          plug_load.setElectricEquipmentDefinition(new_plug_def)
          number_of_plugs_replaced += plug_load.multiplier
        end
      end
      #do the plug loads in each space of the selected space type
      space_type.spaces.each do |space|
        space.electricEquipment.each do |plug_load|
          if plug_load.electricEquipmentDefinition == plug_def
            plug_load.setElectricEquipmentDefinition(new_plug_def)
            number_of_plugs_replaced += plug_load.multiplier
          end
        end      
      end
    end
    
    # add costs
    if material_and_installation_cost_per_plug != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Replace #{number_of_plugs_replaced.round} #{plug_def.name.get}s with #{new_plug_def.name.get}", new_plug_def, material_and_installation_cost_per_plug, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end
        
    #report initial condition
    runner.registerInitialCondition("The building has a number of #{plug_def.name.get}, which are not the most efficient choice for the application.") 
    
    #report final condition
    if apply_to_building
      runner.registerFinalCondition("Replace #{number_of_plugs_replaced.round} existing #{plug_def.name.get}s with #{new_plug_def.name.get}s throughout the building.  The total cost to replace the equipment is is $#{material_and_installation_cost_per_plug.round} per unit, for a total cost of $#{(material_and_installation_cost_per_plug * number_of_plugs_replaced).round}")
    else
      runner.registerFinalCondition("Replace #{number_of_plugs_replaced.round} existing #{plug_def.name.get}s with #{new_plug_def.name.get}s in #{space_type.name} spaces throughout the building.  The total cost to replace the equipment is $#{material_and_installation_cost_per_plug.round} per unit, for a total cost of $#{(material_and_installation_cost_per_plug * number_of_plugs_replaced).round}")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReplaceOnePlugLoadwithAnother.new.registerWithApplication