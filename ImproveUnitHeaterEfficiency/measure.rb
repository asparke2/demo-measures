#start the measure
class ImproveUnitHeaterEfficiency < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Improve Unit Heater Efficiency"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument to add new space true/false
    heater_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("heater_eff",true)
    heater_eff.setDisplayName("Unit Heater Efficiency (%).")
    args << heater_eff

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
    heater_eff = runner.getDoubleArgumentValue("heater_eff",user_arguments)

    #check the user_name for reasonableness
    if heater_eff <= 0 or  heater_eff >= 100
      runner.registerError("Please enter a number between 0 and 100 for unit heater efficiency percentage.")
      return false
    end

    model.getCoilHeatingGass.each do |coilHeatingGas|
      coilHeatingGas.setGasBurnerEfficiency(heater_eff / 100.0)
    end

    return true

  end #end the cop method

end #end the measure

#this allows the measure to be used by the application
ImproveUnitHeaterEfficiency.new.registerWithApplication