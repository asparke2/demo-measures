#start the measure
class ImproveBoilerEfficiency < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Improve Boiler Efficiency"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument to add new space true/false
    boiler_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_eff",true)
    boiler_eff.setDisplayName("Boiler Efficiency (%).")
    args << boiler_eff

    return args
  end #end the arguments method

  #define what happens when the measure is cop
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    boiler_eff = runner.getDoubleArgumentValue("boiler_eff",user_arguments)

    #check the user_name for reasonableness
    if boiler_eff <= 0 or  boiler_eff >= 100
      runner.registerError("Please enter a number between 0 and 100 for boiler efficiency percentage.")
      return false
    end

    model.getBoilerHotWaters.each do |boilerHotWater|
      boilerHotWater.setNominalThermalEfficiency(boiler_eff / 100.0)
    end

    return true

  end #end the cop method

end #end the measure

#this allows the measure to be used by the application
ImproveBoilerEfficiency.new.registerWithApplication