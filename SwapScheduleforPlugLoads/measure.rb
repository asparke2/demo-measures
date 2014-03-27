#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SwapScheduleforPlugLoads < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Swap Schedule for Plug Loads"
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
    space_type.setDisplayName("Replace Schedules for Plug Loads in a Specific Space Type or in the Entire Model.")
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
    plug_def.setDisplayName("Choose a Plug Load Type Whose Schedules to Replace.")
    args << plug_def

    #populate choice argument for schedules in the model
    sch_handles = OpenStudio::StringVector.new
    sch_display_names = OpenStudio::StringVector.new

    #putting schedule names into hash
    sch_hash = {}
    model.getScheduleRulesets.each do |sch|
      sch_hash[sch.name.to_s] = sch
    end

    #looping through sorted hash of schedules
    sch_hash.sort.map do |sch_name, sch|
      if not sch.scheduleTypeLimits.empty?
        unitType = sch.scheduleTypeLimits.get.unitType
        if unitType == "Dimensionless"
          sch_handles << sch.handle.to_s
          sch_display_names << sch_name
        end
      end
    end

    #make an argument for new plug schedule
    new_plug_sch = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("new_plug_sch", sch_handles, sch_display_names, true)
    new_plug_sch.setDisplayName("Choose New Plug Load Schedule.")
    args << new_plug_sch      
    
    #make an argument for material and installation cost
    material_and_installation_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost",true)
    material_and_installation_cost.setDisplayName("Material and Installation Cost.")
    material_and_installation_cost.setDefaultValue(0.0)
    args << material_and_installation_cost

    #make an argument for expected life of the measure
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life.")
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
    new_plug_sch_object = runner.getOptionalWorkspaceObjectChoiceValue("new_plug_sch",user_arguments,model)
    material_and_installation_cost = runner.getDoubleArgumentValue("material_and_installation_cost",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)
      
    #check the plug_def argument to make sure it still is in the model
    plug_def = nil
    if plug_def_object.empty?
      handle = runner.getStringArgumentValue("plug_def",user_arguments)
      if handle.empty?
        runner.registerError("No plug definition was chosen.")
      else
        runner.registerError("The selected plug definition with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if plug_def_object.get.to_ElectricEquipmentDefinition.is_initialized
        plug_def = plug_def_object.get.to_ElectricEquipmentDefinition.get
      end
    end

    #check the new_plug_sch argument to make sure it still is in the model
    new_plug_sch = nil
    if new_plug_sch_object.empty?
      handle = runner.getStringArgumentValue("new_plug_sch",user_arguments)
      if handle.empty?
        runner.registerError("No new plug load schedule was chosen.")
      else
        runner.registerError("The selected new plug load schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if new_plug_sch_object.get.to_ScheduleRuleset.is_initialized
        new_plug_sch = new_plug_sch_object.get.to_ScheduleRuleset.get
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
        
    #replace plug schedule for all fixtures of a given type with the new schedule
    number_of_fixtures_affected = 0
    if apply_to_building #apply to the whole building
      model.getElectricEquipments.each do |plug_load|
        if plug_load.electricEquipmentDefinition == plug_def
          plug_load.setSchedule(new_plug_sch)
          number_of_fixtures_affected += plug_load.multiplier
        end
      end
    else #apply to the a specific space type
      #do the plug loads assigned to the space type itself
      space_type.electricEquipment.each do |plug_load|
        if plug_load.electricEquipmentDefinition == plug_def
          plug_load.setSchedule(new_plug_sch)
          number_of_fixtures_affected += plug_load.multiplier
        end
      end
      #do the plug loads in each space of the selected space type
      space_type.spaces.each do |space|
        space.electricEquipment.each do |plug_load|
          if plug_load.electricEquipmentDefinition == plug_def
            plug_load.setSchedule(new_plug_sch)
            number_of_fixtures_affected += plug_load.multiplier
          end
        end      
      end
    end
    
    # add costs
    if material_and_installation_cost != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Added controls to #{number_of_fixtures_affected.round} plug loads", model.getBuilding, material_and_installation_cost, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end
        
    #report initial condition
    runner.registerInitialCondition("The building has a number of #{plug_def.name.get}s, which could be made to save energy if advanced power strips were used to turn them off when not in use.") 
    
    #report final condition
    if apply_to_building
      runner.registerFinalCondition("Added advanced power strip controls to #{number_of_fixtures_affected.round} existing #{plug_def.name.get}s throughout the building.  The total cost to install the advanced power strips is $#{material_and_installation_cost}.")
    else
      runner.registerFinalCondition("Added advanced power strip controls to #{number_of_fixtures_affected.round} existing #{plug_def.name.get}s in #{space_type.name} spaces throughout the building.  The total cost to install the advanced power strips is $#{material_and_installation_cost}.")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SwapScheduleforPlugLoads.new.registerWithApplication