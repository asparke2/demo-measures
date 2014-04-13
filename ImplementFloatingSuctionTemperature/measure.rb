#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ImplementFloatingSuctionTemperature < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Implement Floating Suction Temperature"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for the refrigeration system to modify
    ref_sys_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("ref_sys_name",true)
    ref_sys_name.setDisplayName("Select a Refrigeration System to Modify.")
    ref_sys_name.setDefaultValue("Rack A Low Temp")
    args << ref_sys_name     

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
    
    #reporting initial condition of model
    starting_suction_type = ref_sys.suctionTemperatureControlType
    runner.registerInitialCondition("#{ref_sys.name} started with #{starting_suction_type}.")
    
    #not applicable if starting temperature is same as requested temperature
    if starting_suction_type == "FloatSuctionTemperature"
      runner.registerAsNotApplicable("Not Applicable - system is already using floating suction temperature.")
      return true
    else
      #modify the suction control type as requested
      ref_sys.setSuctionTemperatureControlType("FloatSuctionTemperature")
      runner.registerInfo("Set #{ref_sys.name} to use floating suction temperature.")
    end
      
    #reporting final condition of model
    ending_suction_type = ref_sys.suctionTemperatureControlType
    runner.registerFinalCondition("#{ref_sys.name} ended with #{ending_suction_type}.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ImplementFloatingSuctionTemperature.new.registerWithApplication