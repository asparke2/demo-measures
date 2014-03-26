#start the measure
class SetRunPeriod < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetRunPeriod"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for the boiler efficiency
    start_month = OpenStudio::Ruleset::OSArgument::makeStringArgument("start_month",true)
    start_month.setDisplayName("Start Month")
    start_month.setDefaultValue("1")
    args << start_month
    
    #make an argument for the boiler efficiency
    start_day = OpenStudio::Ruleset::OSArgument::makeStringArgument("start_day",true)
    start_day.setDisplayName("Start Day")
    start_day.setDefaultValue("1")
    args << start_day
          
    #make an argument for the boiler efficiency
    end_month = OpenStudio::Ruleset::OSArgument::makeStringArgument("end_month",true)
    end_month.setDisplayName("End Month")
    end_month.setDefaultValue("12")
    args << end_month
    
    #make an argument for the boiler efficiency
    end_day = OpenStudio::Ruleset::OSArgument::makeStringArgument("end_day",true)
    end_day.setDisplayName("End Day")
    end_day.setDefaultValue("31")
    args << end_day
    
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
    start_month = runner.getStringArgumentValue("start_month",user_arguments)    
    start_day = runner.getStringArgumentValue("start_day",user_arguments)      
    end_month = runner.getStringArgumentValue("end_month",user_arguments)    
    end_day = runner.getStringArgumentValue("end_day",user_arguments)         
    
    #remove any existing runperiod object
    workspace.getObjectsByType("RunPeriod".to_IddObjectType).each do |object|
      runner.registerInfo("removed existing runperiod object")
      workspace.removeObjects([object.handle])
    end
    
    #and replace with the custom one
    run_period_string = "    
    RunPeriod,
      Changed Run Period,      !- Name
      #{start_month},          !- Begin Month
      #{start_day},            !- Begin Day of Month
      #{end_month},            !- End Month
      #{end_day},              !- End Day of Month
      UseWeatherFile,          !- Day of Week for Start Day
      Yes,                     !- Use Weather File Holidays and Special Days
      Yes,                     !- Use Weather File Daylight Saving Period
      No,                      !- Apply Weekend Holiday Rule
      Yes,                     !- Use Weather File Rain Indicators
      Yes;                     !- Use Weather File Snow Indicators
    "  

    
    
    run_period = OpenStudio::IdfObject::load(run_period_string).get
    workspace.addObject(run_period)
    runner.registerInfo("added runperiod named #{run_period.name}")
            
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetRunPeriod.new.registerWithApplication









