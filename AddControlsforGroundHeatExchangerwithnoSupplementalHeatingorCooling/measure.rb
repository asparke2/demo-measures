#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class AddControlsforGroundHeatExchangerwithnoSupplementalHeatingorCooling < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddControlsforGroundHeatExchangerwithnoSupplementalHeatingorCooling"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for node name
    node_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("node_name",true)
    node_name.setDisplayName("Name of node to add SetpointManager to (typically supply outlet node of plant loop)")
    args << node_name
 
    #make arguments for monthly deep ground temps
    jan_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("jan_temp_f",true)
    jan_temp_f.setDisplayName("Jan Deep Ground Temp (F)")
    jan_temp_f.setDefaultValue(61)
    args << jan_temp_f

    feb_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("feb_temp_f",true)
    feb_temp_f.setDisplayName("Feb Deep Ground Temp (F)")
    feb_temp_f.setDefaultValue(61)
    args << feb_temp_f

    mar_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mar_temp_f",true)
    mar_temp_f.setDisplayName("Mar Deep Ground Temp (F)")
    mar_temp_f.setDefaultValue(61)
    args << mar_temp_f

    apr_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("apr_temp_f",true)
    apr_temp_f.setDisplayName("Apr Deep Ground Temp (F)")
    apr_temp_f.setDefaultValue(61)
    args << apr_temp_f

    may_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("may_temp_f",true)
    may_temp_f.setDisplayName("May Deep Ground Temp (F)")
    may_temp_f.setDefaultValue(61)
    args << may_temp_f

    jun_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("jun_temp_f",true)
    jun_temp_f.setDisplayName("Jun Deep Ground Temp (F)")
    jun_temp_f.setDefaultValue(61)
    args << jun_temp_f

    jul_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("jul_temp_f",true)
    jul_temp_f.setDisplayName("Jul Deep Ground Temp (F)")
    jul_temp_f.setDefaultValue(61)
    args << jul_temp_f

    aug_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("aug_temp_f",true)
    aug_temp_f.setDisplayName("Aug Deep Ground Temp (F)")
    aug_temp_f.setDefaultValue(61)
    args << aug_temp_f

    sep_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sep_temp_f",true)
    sep_temp_f.setDisplayName("Sep Deep Ground Temp (F)")
    sep_temp_f.setDefaultValue(61)
    args << sep_temp_f

    oct_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("oct_temp_f",true)
    oct_temp_f.setDisplayName("Oct Deep Ground Temp (F)")
    oct_temp_f.setDefaultValue(61)
    args << oct_temp_f

    nov_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nov_temp_f",true)
    nov_temp_f.setDisplayName("Nov Deep Ground Temp (F)")
    nov_temp_f.setDefaultValue(61)
    args << nov_temp_f
    
    dec_temp_f = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("dec_temp_f",true)
    dec_temp_f.setDisplayName("Dec Deep Ground Temp (F)")
    dec_temp_f.setDefaultValue(61)
    args << dec_temp_f
    
 
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    #assign the user inputs to variables
    node_name = runner.getStringArgumentValue("node_name",user_arguments)
    jan_temp_f = runner.getDoubleArgumentValue("jan_temp_f",user_arguments)
    feb_temp_f = runner.getDoubleArgumentValue("feb_temp_f",user_arguments)
    mar_temp_f = runner.getDoubleArgumentValue("mar_temp_f",user_arguments)
    apr_temp_f = runner.getDoubleArgumentValue("apr_temp_f",user_arguments)
    may_temp_f = runner.getDoubleArgumentValue("may_temp_f",user_arguments)
    jun_temp_f = runner.getDoubleArgumentValue("jun_temp_f",user_arguments)
    jul_temp_f = runner.getDoubleArgumentValue("jul_temp_f",user_arguments)
    aug_temp_f = runner.getDoubleArgumentValue("aug_temp_f",user_arguments)
    sep_temp_f = runner.getDoubleArgumentValue("sep_temp_f",user_arguments)
    oct_temp_f = runner.getDoubleArgumentValue("oct_temp_f",user_arguments)
    nov_temp_f = runner.getDoubleArgumentValue("nov_temp_f",user_arguments)
    dec_temp_f = runner.getDoubleArgumentValue("dec_temp_f",user_arguments)
    
    #convert inputs from F to C
    jan_temp_c = OpenStudio::convert(jan_temp_f,"F","C").get
    feb_temp_c = OpenStudio::convert(feb_temp_f,"F","C").get
    mar_temp_c = OpenStudio::convert(mar_temp_f,"F","C").get
    apr_temp_c = OpenStudio::convert(apr_temp_f,"F","C").get
    may_temp_c = OpenStudio::convert(may_temp_f,"F","C").get
    jun_temp_c = OpenStudio::convert(jun_temp_f,"F","C").get
    jul_temp_c = OpenStudio::convert(jul_temp_f,"F","C").get
    aug_temp_c = OpenStudio::convert(aug_temp_f,"F","C").get
    sep_temp_c = OpenStudio::convert(sep_temp_f,"F","C").get
    oct_temp_c = OpenStudio::convert(oct_temp_f,"F","C").get
    nov_temp_c = OpenStudio::convert(nov_temp_f,"F","C").get
    dec_temp_c = OpenStudio::convert(dec_temp_f,"F","C").get
    
    #define the monthly deep ground temperatures (C) per user inputs
    deep_gnd_temps_string =
    "
    Site:GroundTemperature:Deep, !- Monthly Deep Ground Temperatures (C)
      #{jan_temp_c},
      #{feb_temp_c},
      #{mar_temp_c},
      #{apr_temp_c},
      #{may_temp_c},
      #{jun_temp_c},
      #{jul_temp_c},
      #{aug_temp_c},
      #{sep_temp_c},
      #{oct_temp_c},
      #{nov_temp_c},
      #{dec_temp_c};
    "  
    
    #create the setpoint manager, per node name in user input
    stp_mgr_string =     
      "
      SetpointManager:FollowGroundTemperature,
      GroundHeatExchangerLoopSetpointManager, !- Name
      Temperature, !- Control Variable
      Site:GroundTemperature:Deep, !- Reference Ground Temperature Object Type
      1.5, !- Offset Temperature Difference {deltaC}
      50.0, !- Maximum Setpoint Temperature {C}
      10.0, !- Minimum Setpoint Temperature {C}
      #{node_name}; !- Setpoint Node or NodeList Name
      "

    #add the deep ground temps
    deep_gnd_temps = OpenStudio::IdfObject::load(deep_gnd_temps_string).get
    workspace.addObject(deep_gnd_temps)
      
    #add the setpoint manager
    stp_mgr = OpenStudio::IdfObject::load(stp_mgr_string).get
    workspace.addObject(stp_mgr)     

    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddControlsforGroundHeatExchangerwithnoSupplementalHeatingorCooling.new.registerWithApplication