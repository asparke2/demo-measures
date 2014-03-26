#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class DebugControllerMechanicalVentilationMissingZones < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Debug Controller Mechanical Ventilation Errors"
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

    #first, check if the design days are missing
    #if you don't have design days, sizing:zone objects don't get translated
    #if sizing:zone doesn't get translated, the controller:mechanicalventilation for a zone
    #does not get the list of zones appended to the end of it
    if model.getSizingPeriods.size == 0
      puts "ERROR - you are missing design days; this will cause a controller:mechanicalventilation error"
      return true
    end
    
    
    #check for spaces not in a thermal zone
    model.getSpaces.each do |space|
      if not space.thermalZone.is_initialized
        puts "space #{space.name.get} is not assigned to a thermal zone; it will not be translated"
      end
    end
    
    #combine all spaces in each thermal zone
    #after this each zone will have 0 or 1 spaces and each space will have 0 or 1 zone
    puts "averaging all spaces in a zone into a single space"
    model.getThermalZones.each do |zone|
      num_spaces_in_zone_before = zone.spaces.size
      zone.combineSpaces
      num_spaces_in_zone_after = zone.spaces.size
      puts "  #{zone.name.get} - combined #{num_spaces_in_zone_before} spaces into #{num_spaces_in_zone_after} space"
    end
    
    #list the controller mechanical ventilation
    cntrl_mech_vent = nil
    model.getThermalZones.each do |zone|
      
      if zone.airLoopHVAC.is_initialized
        if zone.airLoopHVAC.get.airLoopHVACOutdoorAirSystem.is_initialized
          cntrl_mech_vent = zone.airLoopHVAC.get.airLoopHVACOutdoorAirSystem.get.getControllerOutdoorAir.controllerMechanicalVentilation
        else
          puts "  ERROR - airloop #{zone.airLoopHVAC.get.name.get} has no OA intake system; the design OA specified cannot be provided"
          puts "    to solve this issue, either remove the design OA specification from the spaces, or add an OA intake to the airloop"
          return true
        end
      end
    
      if cntrl_mech_vent
        #check out the thermal zone's spaces (there should be, at max, 1)
        #and get the designOAspec for this zone
        num_spaces_in_zone = zone.spaces.size
        if num_spaces_in_zone == 0
          puts "  ERROR - zone #{zone.name.get} contains no spaces"
        elsif num_spaces_in_zone == 1
          dsn_spec_oa = zone.spaces[0].designSpecificationOutdoorAir
          if dsn_spec_oa.is_initialized
            #puts "  #{dsn_spec_oa.get}"
          else
            puts "  ERROR - airloop #{zone.airLoopHVAC.get.name} has an OA intake system, but the spaces in zone #{zone.name} have no OA specified "
            puts "    to solve this issue, either add a design OA specification to the spaces, or remove an OA intake to the airloop"
            return true
          end
        elsif num_spaces_in_zone > 1
          puts "  ERROR - zone #{zone.name.get} contains more than 1 space; this means zone combination didn't work correctly"
          return true
        end
      end
    
    
    end
        
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
DebugControllerMechanicalVentilationMissingZones.new.registerWithApplication