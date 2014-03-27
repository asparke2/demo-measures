#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SwapLightingScheduleforFixtureType < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Swap Lighting Schedule for Fixture Type"
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
    space_type.setDisplayName("Replace Schedules for Light Fixtures in a Specific Space Type or in the Entire Model.")
    space_type.setDefaultValue("*Entire Building*") #if no space type is chosen this will run on the entire building
    args << space_type    
    
    #make a choice argument for model objects
    lighting_def_handles = OpenStudio::StringVector.new
    lighting_def_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    model.getLightsDefinitions.each do |lighting_def|
      lighting_def_display_names << lighting_def.name.to_s
      lighting_def_handles << lighting_def.handle.to_s
    end
        
    #make a choice argument for the light fixture to replace
    light_def = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("light_def", lighting_def_handles, lighting_def_display_names)
    light_def.setDisplayName("Choose a Light Fixture Type Whose Schedules to Replace.")
    args << light_def

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

    #make an argument for new lighting schedule
    new_lighting_sch = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("new_lighting_sch", sch_handles, sch_display_names, true)
    new_lighting_sch.setDisplayName("Choose New Lighting Schedule.")
    args << new_lighting_sch      
    
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
    lights_def_object = runner.getOptionalWorkspaceObjectChoiceValue("light_def",user_arguments,model)
    new_lighting_sch_object = runner.getOptionalWorkspaceObjectChoiceValue("new_lighting_sch",user_arguments,model)
    material_and_installation_cost = runner.getDoubleArgumentValue("material_and_installation_cost",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)
      
    #check the lighting_def argument to make sure it still is in the model
    lights_def = nil
    if lights_def_object.empty?
      handle = runner.getStringArgumentValue("lighting_def",user_arguments)
      if handle.empty?
        runner.registerError("No lighting definition was chosen.")
      else
        runner.registerError("The selected lighting definition with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if lights_def_object.get.to_LightsDefinition.is_initialized
        lights_def = lights_def_object.get.to_LightsDefinition.get
      end
    end

    #check the new_lighting_sch argument to make sure it still is in the model
    new_lighting_sch = nil
    if new_lighting_sch_object.empty?
      handle = runner.getStringArgumentValue("new_lighting_sch",user_arguments)
      if handle.empty?
        runner.registerError("No new lighting schedule was chosen.")
      else
        runner.registerError("The selected new lighting schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if new_lighting_sch_object.get.to_ScheduleRuleset.is_initialized
        new_lighting_sch = new_lighting_sch_object.get.to_ScheduleRuleset.get
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
        
    #replace lighting schedule for all fixtures of a given type with the new schedule
    number_of_fixtures_affected = 0
    if apply_to_building #apply to the whole building
      model.getLightss.each do |light_fixture|
        if light_fixture.lightsDefinition == lights_def
          light_fixture.setSchedule(new_lighting_sch)
          number_of_fixtures_affected += light_fixture.multiplier
        end
      end
    else #apply to the a specific space type
      #do the lights assigned to the space type itself
      space_type.lights.each do |light_fixture|
        if light_fixture.lightsDefinition == lights_def
          light_fixture.setSchedule(new_lighting_sch)
          number_of_fixtures_affected += light_fixture.multiplier
        end
      end
      #do the lights in each space of the selected space type
      space_type.spaces.each do |space|
        space.lights.each do |light_fixture|
          if light_fixture.lightsDefinition == lights_def
            light_fixture.setSchedule(new_lighting_sch)
            number_of_fixtures_affected += light_fixture.multiplier
          end
        end      
      end
    end
    
    # add costs
    if material_and_installation_cost != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Added lighting controls to #{number_of_fixtures_affected.round} light fixtures", model.getBuilding, material_and_installation_cost, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end
        
    #report initial condition
    runner.registerInitialCondition("The building has a number of #{lights_def.name.get} light fixtures, which could be made to save energy through better controls.") 
    
    #report final condition
    if apply_to_building
      runner.registerFinalCondition("Added lighting controls to #{number_of_fixtures_affected.round} existing #{lights_def.name.get} light fixtures throughout the building.  The total cost to install the controls is $#{material_and_installation_cost}.")
    else
      runner.registerFinalCondition("Added lighting controls to #{number_of_fixtures_affected.round} existing #{lights_def.name.get} light fixtures in #{space_type.name} spaces throughout the building.  The total cost to install the controls is $#{material_and_installation_cost}.")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SwapLightingScheduleforFixtureType.new.registerWithApplication