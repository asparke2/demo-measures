#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class SetDefrostEnergyCorrectionCurveforRefrigeratedCases < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SetDefrostEnergyCorrectionCurveforRefrigeratedCases"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for your name
    curve_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("curve_name",true)
    curve_name.setDisplayName("Pick the curve to set")
    curve_name.setDefaultValue("SingleShelfHorizontal_DefrostEnergyMult")
    args << curve_name
    
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
    curve_name = runner.getStringArgumentValue("curve_name",user_arguments)

    #get the curve named above
    curve = model.getCurveCubicByName(curve_name)
    if curve.is_initialized
      curve = curve.get
    else
      runner.registerError("No curve called #{curve_name} was found in the model")
      return false
    end
    
    model.getRefrigerationCases.each do |ref_case|
      if ref_case.caseDefrostType == "HotGasWithTemperatureTermination"
        ref_case.setDefrostEnergyCorrectionCurveType("RelativeHumidityMethod")
        ref_case.setDefrostEnergyCorrectionCurve(curve)
        runner.registerInfo("#{ref_case.name.get} def curve type = #{ref_case.defrostEnergyCorrectionCurveType} curve = #{ref_case.defrostEnergyCorrectionCurve.get.name.get}")
      end
    end
    
    compressor = model.getRefrigerationCompressorByName("CU8")
    if compressor.is_initialized
      compressor = compressor.get
      compressor.resetRatedSubcooling
      compressor.resetRatedSuperheat
    
    end
    
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SetDefrostEnergyCorrectionCurveforRefrigeratedCases.new.registerWithApplication