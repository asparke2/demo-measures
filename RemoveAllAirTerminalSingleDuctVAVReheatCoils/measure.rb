#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class RemoveAllAirTerminalSingleDuctVAVReheatCoils < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "RemoveAllAirTerminalSingleDuctVAVReheatCoils"
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

    starting_VAV_terminals = model.getAirTerminalSingleDuctVAVReheats.size
    runner.registerInitialCondition("Model started with #{starting_VAV_terminals} VAV reheat terminals")
    
    model.getAirTerminalSingleDuctVAVReheats.each do |terminal|
      if not terminal.airLoopHVAC.is_initialized
        terminal.remove
        runner.registerInfo("remove an orphaned VAV terminal")
        puts "removed an orphaned VAV terminal"
      end
    end

    model.getAirTerminalSingleDuctConstantVolumeReheats.each do |terminal|
      if not terminal.airLoopHVAC.is_initialized
        terminal.remove
        runner.registerInfo("remove an orphaned CAV terminal")
        puts "removed an orphaned CAV terminal"
      end
    end    
    
    model.getCoilHeatingWaters.each do |coil|
      if coil.airLoopHVAC.is_initialized and coil.plantLoop.is_initialized
        next #ignore coils that are already connected properly
      else
        coil.remove
        runner.registerInfo("removed a coil")
        puts "removed an orphaned coil"
      end
    end    

    model.getCoilCoolingWaters.each do |coil|
      if coil.airLoopHVAC.is_initialized and coil.plantLoop.is_initialized
        next #ignore coils that are already connected properly
      else
        coil.remove
        runner.registerInfo("removed a coil")
        puts "removed an orphaned coil"
      end
    end        

    
    ending_VAV_terminals = model.getAirTerminalSingleDuctVAVReheats.size
    runner.registerFinalCondition("Model ended with #{ending_VAV_terminals} VAV reheat terminals")
    
  
  
    
    return true

    
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
RemoveAllAirTerminalSingleDuctVAVReheatCoils.new.registerWithApplication