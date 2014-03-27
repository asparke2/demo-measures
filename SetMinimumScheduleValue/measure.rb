#start the measure
class SetMinimumScheduleValue < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Set Minimum Schedule Value"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for schedules
    schedule_handles = OpenStudio::StringVector.new
    schedule_display_names = OpenStudio::StringVector.new

    #putting schedules and names into hash
    schedules = model.getScheduleRulesets
    schedules_hash = {}
    schedules.each do |schedule|
      schedules_hash[schedule.name.to_s] = schedule
    end

    #looping through sorted hash of schedule
    schedules_hash.sort.map do |key,value|
      schedule_handles << value.handle.to_s
      schedule_display_names << key
    end
    
    #make a choice argument for schedule
    schedule = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("schedule", schedule_handles, schedule_display_names)
    schedule.setDisplayName("Select Schedule.")
    args << schedule
    
    #make an argument for minimum fractional value 
    minimum_fraction = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("minimum_fraction",true)
    minimum_fraction.setDisplayName("Minimum Fractional Value.")
    minimum_fraction.setDefaultValue(0.1)
    args << minimum_fraction

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
    schedule = runner.getOptionalWorkspaceObjectChoiceValue("schedule",user_arguments,model)
    minimum_fraction = runner.getDoubleArgumentValue("minimum_fraction",user_arguments)
    
    #check the schedule
    if schedule.empty?
      runner.registerError("Cannot find schedule.")
      return false
    end
    schedule = schedule.get.to_ScheduleRuleset
    if schedule.empty?
      runner.registerError("Cannot find schedule.")
      return false
    end
    schedule = schedule.get
    
    #check the fraction for reasonableness
    if not 0 <= minimum_fraction and minimum_fraction <= 1
      runner.registerError("Minimum fractional value needs to be between or equal to 0 and 1.")
      return false
    end
    
    #check the fraction for reasonableness
    schedule.scheduleRules.each do |scheduleRule|
      # these are already unique, no need to clone
      daySchedule = scheduleRule.daySchedule
      times = daySchedule.times
      values = daySchedule.values
      daySchedule.clearValues
      
      times.each_index do |i|
        value = [values[i], minimum_fraction].max
        daySchedule.addValue(times[i], value)
      end
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
SetMinimumScheduleValue.new.registerWithApplication
