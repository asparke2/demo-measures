#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddOccupancySensorsToLights < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add Occupancy Sensors To Lights"
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
    space_type.setDisplayName("Add Occ Sensors to Lights in a Specific Space Type or in the Entire Model.")
    space_type.setDefaultValue("*Entire Building*") #if no space type is chosen this will run on the entire building
    args << space_type    
    
    #make an argument for the number of lamps
    percent_runtime_reduction = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("percent_runtime_reduction",true)
    percent_runtime_reduction.setDisplayName("Percent Runtime Reduction due to Occupancy Sensors (%)")
    percent_runtime_reduction.setDefaultValue(15.0)
    args << percent_runtime_reduction
   
    #make an argument for material and installation cost per fixture
    material_and_installation_cost_per_space = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost_per_space",true)
    material_and_installation_cost_per_space.setDisplayName("Cost per Space to Install Occ Sensor ($).")
    args << material_and_installation_cost_per_space
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assume the occ sensors will last the full analysis
    expected_life = 25
    
    #assign the user inputs to variables
    space_type_object = runner.getOptionalWorkspaceObjectChoiceValue("space_type",user_arguments,model)
    percent_runtime_reduction = runner.getDoubleArgumentValue("percent_runtime_reduction",user_arguments)
    material_and_installation_cost_per_space = runner.getDoubleArgumentValue("material_and_installation_cost_per_space",user_arguments)

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
    if percent_runtime_reduction >= 100
      runner.registerError("Percent runtime reduction must be less than 100.")
      return false
    end

    #find all the original schedules (before occ sensors installed)
    original_lts_schedules = []
    if apply_to_building #apply to the whole building
    
      model.getLightss.each do |light_fixture|
        if light_fixture.schedule.is_initialized
          original_lts_schedules << light_fixture.schedule.get
        end
      end
    else #apply to the a specific space type
      #do the lights assigned to the space type itself
      space_type.lights.each do |light_fixture|
        if light_fixture.schedule.is_initialized
          original_lts_schedules << light_fixture.schedule.get
        end
      end
      #do the lights in each space of the selected space type
      space_type.spaces.each do |space|
        space.lights.each do |light_fixture|
          if light_fixture.schedule.is_initialized
            original_lts_schedules << light_fixture.schedule.get
          end
        end      
      end
    end
    
    #make copies of all the original lights schedules, reduced to include occ sensor impact
    original_schs_new_schs = {}
    original_lts_schedules.uniq.each do |orig_sch|
      #TODO skip non-schedule-ruleset schedules
      
      #copy the original schedule
      new_sch = orig_sch.clone.to_ScheduleRuleset.get
      #reduce each value in each profile (except the design days) by the specified amount
      runner.registerInfo("Reducing values in '#{orig_sch.name}' schedule by #{percent_runtime_reduction}% to represent occ sensor installation.")
      day_profiles = []
      day_profiles << new_sch.defaultDaySchedule
      new_sch.scheduleRules.each do |rule|
        day_profiles << rule.daySchedule
      end
      multiplier = (100 - percent_runtime_reduction)/100
      day_profiles.each do |day_profile|
        #runner.registerInfo("#{day_profile.name}")
        times_vals = day_profile.times.zip(day_profile.values)
        #runner.registerInfo("original time/values = #{times_vals}")
        times_vals.each do |time,val|
          day_profile.addValue(time, val * multiplier)
        end
        #runner.registerInfo("new time/values = #{day_profile.times.zip(day_profile.values)}")
      end    
      #log the relationship between the old sch and the new, reduced sch
      original_schs_new_schs[orig_sch] = new_sch
      #runner.registerInfo("***")
    end
       
    #replace the old schedules with the new schedules
    spaces_sensors_added_to = []
    if apply_to_building #apply to the whole building
      runner.registerInfo("Adding occupancy sensors to whole building")
      model.getLightss.each do |light_fixture|
        next if light_fixture.schedule.empty?
        lights_sch = light_fixture.schedule.get
        new_sch = original_schs_new_schs[lights_sch]
        if new_sch
          runner.registerInfo("Added occupancy sensor for '#{light_fixture.name}'")
          light_fixture.setSchedule(new_sch)
          spaces_sensors_added_to << light_fixture.space
        end
      end
    else #apply to the a specific space type
      #do the lights assigned to the space type itself
      runner.registerInfo("Adding occupancy sensors to space type '#{space_type.name}'")
      space_type.lights.each do |light_fixture|
        next if light_fixture.schedule.empty?
        lights_sch = light_fixture.schedule.get
        new_sch = original_schs_new_schs[lights_sch]
        if new_sch
          runner.registerInfo("Added occupancy sensor for '#{light_fixture.name}'")
          light_fixture.setSchedule(new_sch)
          spaces_sensors_added_to << light_fixture.space
        end
      end
      #do the lights in each space of the selected space type
      space_type.spaces.each do |space|
        runner.registerInfo("Adding occupancy sensors to space '#{space.name}")
        space.lights.each do |light_fixture|
          next if light_fixture.schedule.empty?
          lights_sch = light_fixture.schedule.get
          new_sch = original_schs_new_schs[lights_sch]
          if new_sch
            runner.registerInfo("Added occupancy sensor for '#{light_fixture.name}'")
            light_fixture.setSchedule(new_sch)
            spaces_sensors_added_to << light_fixture.space
          end
        end      
      end
    end    
    
    #report if the measure is not applicable
    num_sensors_added = spaces_sensors_added_to.uniq.size
    if spaces_sensors_added_to.size == 0
      runner.registerAsNotApplicable("This measure is not applicable because there were no lights in the specified areas of the building.")
      return true
    end
            
    #report initial condition
    runner.registerInitialCondition("The building has several areas where occupancy sensors could be used to reduce lighting energy by turning off the lights while no occupants are present.") 
    
    #add cost of adding occ sensors
    if material_and_installation_cost_per_space != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Add #{material_and_installation_cost_per_space} Occ Sensors to the Building", model.getBuilding, material_and_installation_cost_per_space * num_sensors_added, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add costs.")
      end
    end    
        
    #report final condition
    if apply_to_building
      runner.registerFinalCondition("Add occupancy sensors to #{num_sensors_added} spaces in the building.  The total cost to perform this is $#{material_and_installation_cost_per_space.round} per space, for a total cost of $#{(material_and_installation_cost_per_space * num_sensors_added).round}")
    else
      runner.registerFinalCondition("Add occupancy sensors to #{num_sensors_added} #{space_type.name} spaces in the building.  The total cost to perform this is $#{material_and_installation_cost_per_space.round} per space, for a total cost of $#{(material_and_installation_cost_per_space * num_sensors_added).round}")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddOccupancySensorsToLights.new.registerWithApplication