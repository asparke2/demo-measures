#start the measure
class ImplementNightTimeThermostatSetback < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Implement Night Time Thermostat Setback"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for heating setback amount
    htg_setback_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("htg_setback_f",true)
    htg_setback_f.setDisplayName("Heating Setback (F) - Decrease in Heating Setpoint")
    htg_setback_f.setDefaultValue(15.0)
    args << htg_setback_f

    #make an argument for cooling setback amount
    clg_setback_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("clg_setback_f",true)
    clg_setback_f.setDisplayName("Cooling Setback (F) - Increase in Cooling Setpoint")
    clg_setback_f.setDefaultValue(5.0)
    args << clg_setback_f    
    
    #setback start time
    start_time = OpenStudio::Ruleset::OSArgument::makeStringArgument("start_time",true)
    start_time.setDisplayName("Time to Start Setback (eg 18:00).")
    start_time.setDefaultValue("20:00")
    args << start_time

    #weekday end time
    end_time = OpenStudio::Ruleset::OSArgument::makeStringArgument("end_time",true)
    end_time.setDisplayName("Time to End Setback (eg 07:00).")
    end_time.setDefaultValue("07:00")
    args << end_time

    #make an argument for material and installation cost
    material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)
    material_cost.setDisplayName("Material and Installation Cost($).")
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

    #assign the user inputs to variables
    htg_setback_f = runner.getDoubleArgumentValue("htg_setback_f",user_arguments)
    clg_setback_f = runner.getDoubleArgumentValue("clg_setback_f",user_arguments)
    start_time = runner.getStringArgumentValue("start_time",user_arguments)
    end_time = runner.getStringArgumentValue("end_time",user_arguments)
    material_cost = runner.getDoubleArgumentValue("material_cost",user_arguments)

    #split times into minutes and hours
    start_hr = start_time.split(":")[0].to_i
    start_min = start_time.split(":")[1].to_i
    end_hr = end_time.split(":")[0].to_i
    end_min = end_time.split(":")[1].to_i
 
    #show user inputs
    runner.registerInfo("Adding #{htg_setback_f}F heating and #{clg_setback_f}F cooling setback from #{start_hr}:#{start_min} to #{end_hr}:#{end_min}")
 
    #arrays to store messages that occur inside reduce_schedule
    @infos = []
 
    #define a method to reduce schedule values
    #within a given timeframe
    def reduce_schedule(sch, start_hr, start_min, end_hr, end_min, setback_c)
      if sch.to_ScheduleRuleset.is_initialized
        sch = sch.to_ScheduleRuleset.get
      else
        return false
      end
      
      @infos << "Modifying #{sch.name}"
      
      start_time = OpenStudio::Time.new(0, start_hr, start_min, 0)
      end_time = OpenStudio::Time.new(0, end_hr, end_min, 0)
      crosses_midnight = false
      if start_time < end_time
        crosses_midnight = false
      elsif start_time > end_time
        crosses_midnight = true
      end
      
      @infos << "crosses_midnight = #{crosses_midnight}"
      
      day_profiles = []
      day_profiles << sch.defaultDaySchedule
      sch.scheduleRules.each do |rule|
        day_profiles << rule.daySchedule
      end
      
      day_profiles.each do |day_profile|

        #report out the original schedule
        @infos << "Before setback:"
        day_profile.times.zip(day_profile.values).each do |time,val|
          @infos << "#{time} = #{val}"
        end

        original_start_time_val = day_profile.getValue(start_time)
        original_end_time_val = day_profile.getValue(end_time)
        day_profile.addValue(start_time,original_start_time_val)
        day_profile.addValue(end_time,original_end_time_val)
        times_vals = day_profile.times.zip(day_profile.values)
        
        #report out the original schedule
        @infos << "After adding breaks but before setback:"
        day_profile.times.zip(day_profile.values).each do |time,val|
          @infos << "#{time} = #{val}"
        end
        
        #apply the setback
        times_vals.each do |time,val|
          if crosses_midnight == false
            if time > start_time and time <= end_time
              day_profile.addValue(time, val + setback_c)
            end
          elsif crosses_midnight == true
            if time <= end_time or time > start_time
              day_profile.addValue(time, val + setback_c)
            end
          end
        end #next time val pair in the schedule
        
        #report out the changed schedule
        @infos << "After setback:"
        day_profile.times.zip(day_profile.values).each do |time,val|
          @infos << "#{time} = #{val}"
        end
        
      end #next day profile
      
      return sch
      
    end #end reduce schedule method   
  
    #log to make sure we don't setback to same schedule twice
    prev_setback_schs = []
  
    #get all the thermostats in the building
    model.getThermalZones.each do |zone|
      thermostat = zone.thermostatSetpointDualSetpoint
      if thermostat.is_initialized
        thermostat = thermostat.get
        htg_sch = thermostat.heatingSetpointTemperatureSchedule
        clg_sch = thermostat.coolingSetpointTemperatureSchedule
        
        #convert the setbacks to C (actually a delta C is a K
        #also, heating setback = lower heating setpoint, so make sign negative
        htg_setback_c = -1.0 * OpenStudio::convert(htg_setback_f,"R","K").get
        clg_setback_c = OpenStudio::convert(clg_setback_f,"R","K").get
  
        #add a heating setback
        if htg_sch.is_initialized
          htg_sch = htg_sch.get
          #skip already setback schedules
          if prev_setback_schs.include?(htg_sch)
            runner.registerInfo("The #{zone.name} htg sch: #{htg_sch.name} has already had setback applied.")
          else
            prev_setback_schs << reduce_schedule(htg_sch, start_hr, start_min, end_hr, end_min, htg_setback_c)
            runner.registerInfo("Applied setback to #{zone.name} htg sch: #{htg_sch.name}")
          end
        end
        
        #add a cooling setback
        if clg_sch.is_initialized
          clg_sch = clg_sch.get
          #skip already setback schedules
          if prev_setback_schs.include?(clg_sch)
            runner.registerInfo("The #{zone.name} clg sch: #{clg_sch.name} has already had setback applied.")
          else
            prev_setback_schs << reduce_schedule(clg_sch, start_hr, start_min, end_hr, end_min, clg_setback_c)
            runner.registerInfo("Applied setback to #{zone.name} clg sch: #{clg_sch.name}")
          end
        end

      end #if thermostat
      
    end #next zone

    #log all the messages from applying the messages
    @infos.each do |msg|
      runner.registerInfo("#{msg}")
    end
    
=begin    
    #add lifeCycleCost objects if there is a non-zero value in one of the cost arguments
    building = model.getBuilding
    if costs_requested == true
      quantity = lights_def.quantity
      #adding new cost items
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{lights_def.name} night reduction", building, material_cost * quantity, "CostPerEach", "Construction", expected_life, years_until_costs_start)
      lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_OM - #{lights_def.name} night reduction", building, om_cost * quantity, "CostPerEach", "Maintenance", om_frequency, 0)
      measure_cost =  material_cost * quantity
    end #end of costs_requested == true


    #reporting final condition of model
    runner.registerFinalCondition("#{lights_sch_names.uniq.size} schedule(s) were edited. The cost for the measure is #{neat_numbers(measure_cost,0)}.")
=end
    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
ImplementNightTimeThermostatSetback.new.registerWithApplication
