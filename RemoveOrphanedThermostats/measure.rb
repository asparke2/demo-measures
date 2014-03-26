#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class RemoveOrphanedThermostats < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "RemoveOrphanedThermostats"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #initial condition
    puts "the model started with #{ model.getThermostatSetpointDualSetpoints.size} thermostats"
    
    #loop through all thermostats in the model
    model.getThermostatSetpointDualSetpoints.each do |thermostat|
      thermostat_used = false
      #loop through all zones in the model, finding unused thermostats
      model.getThermalZones.each do |zone|
        if zone.thermostatSetpointDualSetpoint.is_initialized
          if zone.thermostatSetpointDualSetpoint.get == thermostat
            thermostat_used = true
          end
        end
      end
      #delete unused thermostat
      if thermostat_used == false
        puts "thermostat #{thermostat.name.get} was not used; thermostat has been removed"
        thermostat.remove
      end
    end
    
    #final condition
    puts "the model ended with #{ model.getThermostatSetpointDualSetpoints.size} thermostats"
     
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
RemoveOrphanedThermostats.new.registerWithApplication