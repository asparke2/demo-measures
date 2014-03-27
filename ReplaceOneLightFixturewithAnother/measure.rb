#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReplaceOneLightFixturewithAnother < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace One Light Fixture with Another"
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
    space_type.setDisplayName("Replace Light Fixtures in a Specific Space Type or in the Entire Model.")
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
    light_def.setDisplayName("Choose a Light Fixture Type to Replace.")
    args << light_def

    #make an argument for the number of lamps
    lamps_per_fixture = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("lamps_per_fixture",true)
    lamps_per_fixture.setDisplayName("Number of Lamps per New Fixture.")
    lamps_per_fixture.setDefaultValue(1)
    args << lamps_per_fixture

    #make an argument for the power per lamp in the new fixture
    power_per_lamp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("power_per_lamp",true)
    power_per_lamp.setDisplayName("Power per Lamp (W).")
    args << power_per_lamp

    #make an argument for the number of ballasts
    ballasts_per_fixture = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("ballasts_per_fixture",true)
    ballasts_per_fixture.setDisplayName("Number of Ballasts per New Fixture (use 0 for incandescent/HID/integral ballast).")
    ballasts_per_fixture.setDefaultValue(1)
    args << ballasts_per_fixture    
    
    #make an argument for the ballast factor of the new fixture
    ballast_factor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ballast_factor",true)
    ballast_factor.setDisplayName("Ballst Factor (use 1 for incandescent/HID lamps).")
    ballast_factor.setDefaultValue(1.0)
    args << ballast_factor    
    
    #make an argument for material and installation cost per fixture
    material_and_installation_cost_per_fixture = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost_per_fixture",true)
    material_and_installation_cost_per_fixture.setDisplayName("Material and Installation Cost per Fixture.")
    material_and_installation_cost_per_fixture.setDefaultValue(0.0)
    args << material_and_installation_cost_per_fixture

    #make an argument for material and installation cost per fixture
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life of the New Fixtures.")
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
    lamps_per_fixture = runner.getIntegerArgumentValue("lamps_per_fixture",user_arguments)
    power_per_lamp = runner.getDoubleArgumentValue("power_per_lamp",user_arguments)
    ballasts_per_fixture = runner.getIntegerArgumentValue("ballasts_per_fixture",user_arguments)
    ballast_factor = runner.getDoubleArgumentValue("ballast_factor",user_arguments)
    material_and_installation_cost_per_fixture = runner.getDoubleArgumentValue("material_and_installation_cost_per_fixture",user_arguments)
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
    if lamps_per_fixture < 1
      runner.registerError("Fixture must have at least 1 lamp.")
      return false
    end

    if ballasts_per_fixture < 0
      runner.registerError("Number of ballasts must be greater than or equal to 0.")
      return false
    end

    if ballast_factor < 0
      runner.registerError("Ballast factor cannot be less than 0.")
      return false
    end
    
    #make the new light fixture
    new_fixture_def = OpenStudio::Model::LightsDefinition.new(model)
    new_fixture_wattage = lamps_per_fixture * power_per_lamp * ballast_factor
    new_fixture_def.setLightingLevel(new_fixture_wattage)
    #name format is like this:  "(2) 40W Lamps (1) 0.8BF Ballast" or "(2) 40W Lamps"
    name = nil
    if ballasts_per_fixture > 0
      name = "(#{lamps_per_fixture}) #{power_per_lamp}W Lamps (#{ballasts_per_fixture}) #{ballast_factor}BF Ballast"    
    else
      name = "(#{lamps_per_fixture}) #{power_per_lamp}W Lamps"    
    end
    new_fixture_def.setName(name)
    
    #replace all of the fixtures of a given type
    #with the new fixture
    number_of_fixtures_replaced = 0
    if apply_to_building #apply to the whole building
      model.getLightss.each do |light_fixture|
        if light_fixture.lightsDefinition == lights_def
          light_fixture.setLightsDefinition(new_fixture_def)
          number_of_fixtures_replaced += light_fixture.multiplier
        end
      end
    else #apply to the a specific space type
      #do the lights assigned to the space type itself
      space_type.lights.each do |light_fixture|
        if light_fixture.lightsDefinition == lights_def
          light_fixture.setLightsDefinition(new_fixture_def)
          number_of_fixtures_replaced += light_fixture.multiplier
        end
      end
      #do the lights in each space of the selected space type
      space_type.spaces.each do |space|
        space.lights.each do |light_fixture|
          if light_fixture.lightsDefinition == lights_def
            light_fixture.setLightsDefinition(new_fixture_def)
            number_of_fixtures_replaced += light_fixture.multiplier
          end
        end      
      end
    end
    
    # add costs
    if material_and_installation_cost_per_fixture != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Replace #{number_of_fixtures_replaced.round} #{lights_def.name.get} with #{new_fixture_def.name.get}", new_fixture_def, material_and_installation_cost_per_fixture, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end
        
    #report initial condition
    runner.registerInitialCondition("The building has a number of #{lights_def.name.get} light fixtures, which are not the most efficient light source for the application.") 
    
    #report final condition
    if apply_to_building
      runner.registerFinalCondition("Replace #{number_of_fixtures_replaced.round} existing #{lights_def.name.get} light fixtures with #{new_fixture_def.name.get} light fixtures throughout the building.  The total cost to install the new light fixtures is $#{material_and_installation_cost_per_fixture.round} per fixture, for a total cost of $#{(material_and_installation_cost_per_fixture * number_of_fixtures_replaced).round}")
    else
      runner.registerFinalCondition("Replace #{number_of_fixtures_replaced.round} existing #{lights_def.name.get} light fixtures with #{new_fixture_def.name.get} light fixtures in #{space_type.name} spaces throughout the building.  The total cost to install the new light fixtures is $#{material_and_installation_cost_per_fixture.round} per fixture, for a total cost of $#{(material_and_installation_cost_per_fixture * number_of_fixtures_replaced).round}")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReplaceOneLightFixturewithAnother.new.registerWithApplication