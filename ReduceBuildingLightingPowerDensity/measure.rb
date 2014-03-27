
class ReduceBuildingLightingPowerDensity < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Reduce Building Lighting Power Density"
  end
  
#define the user inputs
def arguments(model)
  args = OpenStudio::Ruleset::OSArgumentVector.new
  
  #make a user input for percent LPD reduction
  pct_red = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pct_red",true)
  pct_red.setDisplayName("Percent Lighting Power Reduction (%)")
  pct_red.setDefaultValue(10.0)
  args << pct_red
  
  return args

end

  #define what happens to the model when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    #assign the user inputs to variables
    pct_red = runner.getStringArgumentValue("user_name",user_arguments)

    model.getLightss.each do |light|
      original_lpd = light.li
    
    
    
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReduceBuildingLightingPowerDensity.new.registerWithApplication