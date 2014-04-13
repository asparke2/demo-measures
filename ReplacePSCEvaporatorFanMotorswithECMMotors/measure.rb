#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReplacePSCEvaporatorFanMotorswithECMMotors < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace PSC Evaporator Fan Motors with ECM Motors"
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

    #fan power above which indicates PSC motors
    fan_psc_w_per_ft = 10
    fan_psc_w_per_m = OpenStudio::convert(fan_psc_w_per_ft,"W/ft","W/m").get
    
    #light power for ECM motors
    fan_ecm_w_per_ft = 4
    fan_ecm_w_per_m = OpenStudio::convert(fan_ecm_w_per_ft,"W/ft","W/m").get
    
    #loop through all cases
    cases_modified = []
    model.getRefrigerationCases.each do |ref_case|
      std_fan_pwr = ref_case.standardCaseFanPowerperUnitLength
      ins_fan_pwr = ref_case.operatingCaseFanPowerperUnitLength
      
      #find cases with PSC fans
      if ins_fan_pwr > fan_psc_w_per_m
        runner.registerInfo("Case #{ref_case.name} appears to have PSC evaporator fan motors because installed fan power = #{OpenStudio::convert(ins_fan_pwr,"W/m","W/ft").get} W/ft.")
        ref_case.setOperatingCaseFanPowerperUnitLength(fan_ecm_w_per_m)
        cases_modified << ref_case
        runner.registerInfo("Replaced PSC evaporator fan motor #{ref_case.name} with ECM motor at  #{fan_ecm_w_per_ft} W/ft.")
      end
    end
    
    #check if the measure was applicable
    if cases_modified.size == 0
      runner.registerAsNotApplicable("Not Applicable - no cases appeared to have PSC evaporator fan motors.")
      return true
    end
    
    runner.registerInitialCondition("#{cases_modified.size} cases had PSC evaporator fan motors.")
    
    runner.registerFinalCondition("#{cases_modified.size} cases had  PSC evaporator fan motors replaced with ECM motors.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReplacePSCEvaporatorFanMotorswithECMMotors.new.registerWithApplication