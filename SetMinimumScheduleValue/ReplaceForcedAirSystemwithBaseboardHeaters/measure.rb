#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReplaceForcedAirSystemwithElectricBaseboardHeaters < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace Forced Air System with Electric Baseboard Heaters"
  end
  
#define the user inputs
def arguments(model)
  inputs = OpenStudio::Ruleset::OSArgumentVector.new
  
  #user input for the name of the air system to remove
  air_sys_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("air_sys_name",true)
  air_sys_name.setDisplayName("Name of the air system to replace")
  inputs << air_sys_name
  
  return inputs
end

#define what happens when the measure is run
def run(model, runner, user_arguments)
  super(model, runner, user_arguments)

  #assign the user inputs to variables
  air_sys_name = runner.getStringArgumentValue("air_sys_name",user_arguments)

  #find the air system and hw system in the model
  air_sys = model.getAirLoopHVACByName(air_sys_name).get
  
  #log the zones on the air system, then remove it
  zones = air_sys.thermalZones
  air_sys.remove
  
  #loop through the zones, create a bb heater, add it to the zone, log action
  zones.each do |zone|
    elec_bb = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
    elec_bb.addToThermalZone(zone)
    runner.registerInfo("added elec bb heater to #{zone.name}")
  end
  
  return true

end

end #end the measure

#this allows the measure to be use by the application
ReplaceForcedAirSystemwithElectricBaseboardHeaters.new.registerWithApplication