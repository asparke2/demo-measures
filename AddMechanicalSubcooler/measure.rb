#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddMechanicalSubcooler < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddMechanicalSubcooler"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for the refrigeration system to modify
    ref_sys_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("ref_sys_name",true)
    ref_sys_name.setDisplayName("Select a Refrigeration System to Get A Mechanical Subcooler.")
    ref_sys_name.setDefaultValue("Rack A Low Temp")
    args << ref_sys_name  

    #make an argument for the refrigeration system to modify
    cap_ref_sys_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("cap_ref_sys_name",true)
    cap_ref_sys_name.setDisplayName("Select a Refrigeration System to Provide Capacity.")
    cap_ref_sys_name.setDefaultValue("Rack B Med Temp")
    args << cap_ref_sys_name  
  
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

    #assign the user inputs to variables
    cap_ref_sys_name = runner.getStringArgumentValue("cap_ref_sys_name",user_arguments)
    cap_ref_sys = model.getRefrigerationSystemByName(cap_ref_sys_name)
    if cap_ref_sys.empty?
      runner.registerError("Could not find a refrigeration system called '#{cap_ref_sys_name}'.")
      return false
    else
      cap_ref_sys = cap_ref_sys.get
    end

    #reporting initial condition of model
    has_subcooler = false
    if ref_sys.mechanicalSubcooler.is_initialized
      has_subcooler = true
    else
      has_subcooler = false
    end

    #not applicable if system already has mechanical subcooler
    if has_subcooler == true
      runner.registerAsNotApplicable("Not Applicable - #{ref_sys.name} already has a mechanical subcooler.")
      return true
    else
      #create a mechanical subcooler
      subcooler = OpenStudio::Model::RefrigerationSubcoolerMechanical.new(model)
      subcooler.setCapacityProvidingSystem(cap_ref_sys)
      subcooler_outlet_temp_f = 50
      subcooler_outlet_temp_c = OpenStudio::convert(subcooler_outlet_temp_f,"F","C").get
      subcooler.setOutletControlTemperature(subcooler_outlet_temp_c)
      ref_sys.setMechanicalSubcooler(subcooler)
      runner.registerInfo("Added mechanical subcooler to #{ref_sys.name} with capacity provided by #{cap_ref_sys.name}.")
    end
      
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddMechanicalSubcooler.new.registerWithApplication