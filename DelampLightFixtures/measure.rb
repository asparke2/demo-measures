#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class DelampLightFixtures < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Delamp Light Fixtures"
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
    space_type.setDisplayName("Delamp Light Fixtures in a Specific Space Type or in the Entire Model.")
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
    light_def.setDisplayName("Choose a Light Fixture Type to Delamp.")
    args << light_def

    #make an argument for the number of lamps
    lamps_removed_per_fixture = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("lamps_removed_per_fixture",true)
    lamps_removed_per_fixture.setDisplayName("Number of Lamps to Remove from Each Fixture.")
    lamps_removed_per_fixture.setDefaultValue(1)
    args << lamps_removed_per_fixture
   
    #make an argument for material and installation cost per fixture
    material_and_installation_cost_per_fixture = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost_per_fixture",true)
    material_and_installation_cost_per_fixture.setDisplayName("Cost to Delamp each Fixture.")
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

    #assume the delamping last the full analysis
    expected_life = 25
    
    #assign the user inputs to variables
    space_type_object = runner.getOptionalWorkspaceObjectChoiceValue("space_type",user_arguments,model)
    lights_def_object = runner.getOptionalWorkspaceObjectChoiceValue("light_def",user_arguments,model)
    lamps_removed_per_fixture = runner.getIntegerArgumentValue("lamps_removed_per_fixture",user_arguments)
    material_and_installation_cost_per_fixture = runner.getDoubleArgumentValue("material_and_installation_cost_per_fixture",user_arguments)
      
    #check the lighting_def argument to make sure it still is in the model
    original_lights_def = nil
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
        original_lights_def = lights_def_object.get.to_LightsDefinition.get
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
    if lamps_removed_per_fixture < 1
      runner.registerError("Number of lamps to remove per fixture must be greater than 0.")
      return false
    end

    #(1) 32.0W T8 Linear Fluorescent (1) 0.88BF Fluorescent Electronic Non-Dimming
    name = original_lights_def.name.get
    runner.registerInfo("Properties of Fixture to be Delamped:")
    runner.registerInfo("'#{name}'")
    
    #get the fixture properties from the fixture name
    lamp_type = name.scan(/[\d\.]+W (\w+)/)[0][0]
    runner.registerInfo("lamp_type = #{lamp_type}")
    next unless lamp_type == "T8" #only looking for T8 fixtures
    
    lamp_wattage = name.match(/([\d\.]+)W/)[0].to_f
    runner.registerInfo("lamp_wattage = #{lamp_wattage}")
    next unless lamp_wattage == 32.0 #only looking to replace 32W T8s
    
    num_lamps = name.scan(/\((\d+)\)/)[0][0].to_f
    runner.registerInfo("num_lamps = #{num_lamps}")
    num_new_lamps = num_lamps - lamps_removed_per_fixture
    
    num_ballasts = name.scan(/\((\d+)\)/)[1][0].to_f
    runner.registerInfo("num_ballasts = #{num_ballasts}")

    ballast_factor = name.match(/([\d\.]+)BF/)[0].to_f
    runner.registerInfo("ballast_factor = #{ballast_factor}")
    
    #calculate the wattage of the delamped fixture
    new_total_wattage = num_new_lamps * lamp_wattage * ballast_factor
    
    #make a delamped copy of the original fixture
    new_name = "Delamped #{name}"
    delamped_fixture_def = OpenStudio::Model::LightsDefinition.new(model)
    delamped_fixture_def.setName(new_name)
    delamped_fixture_def.setLightingLevel(new_total_wattage)

    #add costs to the new fixture
    if material_and_installation_cost_per_fixture != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Delamp #{name}", delamped_fixture_def, material_and_installation_cost_per_fixture, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end    
    
    #replace all of the fixtures of a given type
    #with the new fixture
    number_of_fixtures_delamped = 0
    if apply_to_building #apply to the whole building
      runner.registerInfo("Checking light fixtures in whole building")     
      model.getLightss.each do |light_fixture|
        if light_fixture.lightsDefinition == original_lights_def
          runner.registerInfo("Delamped '#{light_fixture.name}'")
          light_fixture.setLightsDefinition(delamped_fixture_def)
          number_of_fixtures_delamped += light_fixture.multiplier
        end
      end
    else #apply to the a specific space type
      #do the lights assigned to the space type itself
      runner.registerInfo("Checking light fixtures in space type '#{space_type.name}'")
      space_type.lights.each do |light_fixture|
        if light_fixture.lightsDefinition == original_lights_def
          runner.registerInfo("Delamped '#{light_fixture.name}'")
          light_fixture.setLightsDefinition(delamped_fixture_def)
          number_of_fixtures_delamped += light_fixture.multiplier
        end
      end
      #do the lights in each space of the selected space type
      space_type.spaces.each do |space|
        runner.registerInfo("Checking light fixtures in space '#{space.name}")
        space.lights.each do |light_fixture|
          if light_fixture.lightsDefinition == original_lights_def
            runner.registerInfo("Delamped '#{light_fixture.name}'")
            light_fixture.setLightsDefinition(delamped_fixture_def)
            number_of_fixtures_delamped += light_fixture.multiplier
          end
        end      
      end
    end
    
    #report if the measure is not applicable (no 32W T8 fixtures)
    if number_of_fixtures_delamped == 0
      runner.registerAsNotApplicable("This measure is not applicable, because this building has no #{original_lights_def} fixtures to delamp.")
      return true
    end
            
    #report initial condition
    runner.registerInitialCondition("The building has several areas where #{original_lights_def.name.get} light fixtures are providing too much light, causing occupant discomfort and wasting energy.") 
    
    #report final condition
    if apply_to_building
      runner.registerFinalCondition("Delamp #{number_of_fixtures_delamped.round} existing #{original_lights_def.name.get} light fixtures throughout the building by removing #{lamps_removed_per_fixture} lamps per fixture.  The total cost to perform this delamping is $#{material_and_installation_cost_per_fixture.round} per fixture, for a total cost of $#{(material_and_installation_cost_per_fixture * number_of_fixtures_delamped).round}")
    else
      runner.registerFinalCondition("Delamp #{number_of_fixtures_delamped.round} existing #{original_lights_def.name.get} light fixtures in #{space_type.name} spaces throughout the building by removing #{lamps_removed_per_fixture} lamps per fixture.  The total cost to perform this delamping is $#{material_and_installation_cost_per_fixture.round} per fixture, for a total cost of $#{(material_and_installation_cost_per_fixture * number_of_fixtures_delamped).round}")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
DelampLightFixtures.new.registerWithApplication