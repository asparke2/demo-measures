#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetMinimumCondensingTemperature < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Minimum Condensing Temperature"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
  
    #make an argument for the refrigeration system to modify
    ref_sys_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("ref_sys_name",true)
    ref_sys_name.setDisplayName("Select a Refrigeration System to Modify.")
    ref_sys_name.setDefaultValue("Rack A Low Temp")
    args << ref_sys_name   
  
    #make an argument for minimum condensing temperature
    min_cond_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_cond_temp_f",true)
    min_cond_temp_f.setDisplayName("Minimum Condensing Temperature (F)")
    min_cond_temp_f.setDefaultValue(70.0)
    args << min_cond_temp_f

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
    ref_sys_name = runner.getStringArgumentValue("ref_sys_name",user_arguments)
    ref_sys = model.getRefrigerationSystemByName(ref_sys_name)
    if ref_sys.empty?
      runner.registerError("Could not find a refrigeration system called '#{ref_sys_name}'.")
      return false
    else
      ref_sys = ref_sys.get
    end
    
    min_cond_temp_f = runner.getDoubleArgumentValue("min_cond_temp_f",user_arguments)
    min_cond_temp_c = OpenStudio::convert(min_cond_temp_f,"F","C").get
        
    #reporting initial condition of model
    start_cond_temp_c = ref_sys.minimumCondensingTemperature
    start_cond_temp_f = OpenStudio::convert(start_cond_temp_c,"C","F").get
    runner.registerInitialCondition("#{ref_sys.name} started with a min condensing temperature of #{start_cond_temp_f}F.")
    
    #not applicable if starting temperature is same as requested temperature
    if start_cond_temp_c == min_cond_temp_c
      runner.registerAsNotApplicable("Not Applicable - #{ref_sys.name} is already set at the requested minimum condensing temperature of #{min_cond_temp_f}F.")
      return true
    else
      #modify the minimum condensing temperature as requested
      ref_sys.setMinimumCondensingTemperature(min_cond_temp_c)
      runner.registerInfo("Set minimum condensing temperature of #{ref_sys.name} to #{min_cond_temp_f}F.")
    end
      
    #reporting final condition of model
    end_cond_temp_c = ref_sys.minimumCondensingTemperature
    end_cond_temp_f = OpenStudio::convert(end_cond_temp_c,"C","F").get
    runner.registerFinalCondition("#{ref_sys.name} ended with a min condensing temperature of #{end_cond_temp_f}F.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetMinimumCondensingTemperature.new.registerWithApplication