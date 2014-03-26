#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class RemoveOrphanedControllerWaterCoils < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "RemoveOrphanedControllerWaterCoils"
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
    puts "started with #{model.getControllerWaterCoils.size} water coil controllers"
    
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

    #final condition
    puts "ended with #{model.getControllerWaterCoils.size} water coil controllers"    
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
RemoveOrphanedControllerWaterCoils.new.registerWithApplication