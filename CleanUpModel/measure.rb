#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class CleanUpModel < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "CleanUpModel"
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

    #remove zones with no spaces
    puts "CLEANUP - removing zones with no spaces"
    model.getThermalZones.each do |zone|
      if zone.spaces.size == 0
        puts "zone #{zone.name} had no spaces in it; zone was deleted"
        zone.remove
      end
    end
    
    #remove curly braces fromall  object names
    puts "CLEANUP - removing curly braces fromall  object names"
    objects_renamed = 0
    model.getModelObjects.each do |object|      
      if object.name.is_initialized
        original_name = object.name.get
        if original_name.include? "{" or original_name.include? "}"
          new_name = original_name.gsub(/\W/,'').strip
          object.setName(new_name)
          objects_renamed += 1
          #puts "original name: #{original_name} - new name: #{new_name}"
        end
      end
    end
    if objects_renamed > 0
      puts "curly braces removed from names of #{objects_renamed} objects"
    end
    
    #rename objects with super long names 
    #E+ will truncate long names to 99 chars anyway
    #this avoids the warnings in E+
    puts "CLEANUP - truncating names longer than 99 characters"
    objects_w_long_names = 0
    model.getModelObjects.each do |object|      
      if object.name.is_initialized
        original_name = object.name.get
        if original_name.size > 99
          new_name = original_name[0..99]
          object.setName(new_name)
          objects_w_long_names += 1
        end
      end
    end
    if objects_w_long_names > 0
      puts "#{objects_w_long_names} objects had names longer than 99 characters; names were truncated to 99 to avoid E+ warnings"
    end        
    
    
    #remove orphaned VAV terminals
    puts "CLEANUP - removing orphaned VAV terminals"
    model.getAirTerminalSingleDuctVAVReheats.each do |terminal|
      if not terminal.airLoopHVAC.is_initialized
        terminal.remove
        runner.registerInfo("remove an orphaned VAV terminal")
        puts "removed an orphaned VAV terminal"
      end
    end

    #remove orphaned CAV terminals
    puts "CLEANUP - removing orphaned CAV terminals"
    model.getAirTerminalSingleDuctConstantVolumeReheats.each do |terminal|
      if not terminal.airLoopHVAC.is_initialized
        terminal.remove
        runner.registerInfo("remove an orphaned CAV terminal")
        puts "removed an orphaned CAV terminal"
      end
    end    

    #remove orphaned diffusers
    puts "CLEANUP - removing orphaned diffusers"
    model.getAirTerminalSingleDuctUncontrolleds.each do |terminal|
      if not terminal.airLoopHVAC.is_initialized
        terminal.remove
        runner.registerInfo("remove an orphaned diffuser")
        puts "removed an orphaned diffuser"
      end
    end  
    
    #remove orphaned hot water heating coils
    puts "CLEANUP - removing orphaned hot water heating coils"
    model.getCoilHeatingWaters.each do |coil|
      if coil.airLoopHVAC.is_initialized and coil.plantLoop.is_initialized
        next #ignore coils that are already connected properly
      else
        coil.remove
        runner.registerInfo("removed a coil")
        puts "removed an orphaned coil"
      end
    end    

    #remove orphaned chilled water cooling coils
    puts "CLEANUP - removing orphaned chilled water cooling coils"
    model.getCoilCoolingWaters.each do |coil|
      if coil.airLoopHVAC.is_initialized and coil.plantLoop.is_initialized
        next #ignore coils that are already connected properly
      else
        coil.remove
        runner.registerInfo("removed a coil")
        puts "removed an orphaned coil"
      end
    end        

    #remove orphaned water coil controllers (for hot and chilled water coils)
    puts "CLEANUP - removing orphaned water coil controllers (for hot and chilled water coils)"
    model.getControllerWaterCoils.each do |controller_water_coil|
      controller_used = false
      model.getCoilHeatingWaters.each do |coil|
        if coil.controllerWaterCoil.is_initialized
          if coil.controllerWaterCoil.get == controller_water_coil
            controller_used = true
          end
        end
      end
      model.getCoilCoolingWaters.each do |coil|
        if coil.controllerWaterCoil.is_initialized
          if coil.controllerWaterCoil.get == controller_water_coil
            controller_used = true
          end
        end
      end      
      #remove unused water coil controllers
      if controller_used == false
        puts "removing #{controller_water_coil.name.get} because it is unused"
        controller_water_coil.remove
      end
    end  
    
    #remove orphaned thermostats
    puts "CLEANUP - removing orphaned thermostats"
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
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
CleanUpModel.new.registerWithApplication