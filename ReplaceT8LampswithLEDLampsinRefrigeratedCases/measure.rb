#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReplaceT8LampswithLEDLampsinRefrigeratedCases < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace T8 Lamps with LED Lamps in Refrigerated Cases"
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

    #light power above which indicates T8s
    lt_t8_w_per_ft = 28
    lt_t8_w_per_m = OpenStudio::convert(lt_t8_w_per_ft,"W/ft","W/m").get
    
    #light power for LEDs
    lt_led_w_per_ft = 8
    lt_led_w_per_m = OpenStudio::convert(lt_led_w_per_ft,"W/ft","W/m").get
    
    #loop through all cases
    cases_modified = []
    model.getRefrigerationCases.each do |ref_case|
      std_lt_pwr = ref_case.standardCaseLightingPowerperUnitLength
      ins_lt_pwr = ref_case.installedCaseLightingPowerperUnitLength
      next unless ins_lt_pwr.is_initialized
      ins_lt_pwr = ins_lt_pwr.get
      
      #find cases with more than 30W/ft
      if ins_lt_pwr > lt_t8_w_per_m
        runner.registerInfo("Case #{ref_case.name} appears to have T8 lights because installed lighting = #{OpenStudio::convert(ins_lt_pwr,"W/m","W/ft").get} W/ft.")
        ref_case.setInstalledCaseLightingPowerperUnitLength(lt_led_w_per_m)
        cases_modified << ref_case
        runner.registerInfo("Replaced T8 lamps in #{ref_case.name} with LEDs at  #{lt_led_w_per_ft} W/ft.")
      end
    end
    
    #check if the measure was applicable
    if cases_modified.size == 0
      runner.registerAsNotApplicable("Not Applicable - no cases appeared to have T8 lighting.")
      return true
    end
    
    runner.registerInitialCondition("#{cases_modified.size} cases had T8 lighting.")
    
    runner.registerFinalCondition("#{cases_modified.size} cases had T8 lighting replaced with LED lighting.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReplaceT8LampswithLEDLampsinRefrigeratedCases.new.registerWithApplication