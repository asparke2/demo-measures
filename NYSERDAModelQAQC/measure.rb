#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class NYSERDAModelQAQC < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "NYSERDAModelQAQC"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for your name
    code_choices = OpenStudio::StringVector.new 
    code_choices << "ASHRAE 90.1-2007" 
    code_choices << "ASHRAE 90.1-2010" 
    energy_code = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('energy_code', code_choices, true)
    energy_code.setDisplayName("Code baseline")
    energy_code.setDefaultValue("ASHRAE 90.1-2010")
    args << energy_code
    
    #make an argument to add new space true/false
    leed_check = OpenStudio::Ruleset::OSArgument::makeBoolArgument("leed_check",true)
    leed_check.setDisplayName("Perform typical LEED checks?")
    leed_check.setDefaultValue(true)
    args << leed_check
    
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
    energy_code = runner.getStringArgumentValue("energy_code",user_arguments)
    leed_check = runner.getBoolArgumentValue("leed_check",user_arguments)

    
    #WWR check
    #calculate an area-weighted WWR for the building
    #flag if more than 10% Winows (unrealistic, but will always trigger)
    total_wall_area = 0
    sum_area_times_wwr = 0
    surface_count = 0
    model.getSurfaces.each do |surface|
      if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
        total_wall_area += surface.grossArea
        sum_area_times_wwr += surface.grossArea * surface.windowToWallRatio
        surface_count += 1
      end
    end

    #report the number of windows
    runner.registerInfo("This building has #{surface_count} exterior walls, with a total area of #{total_wall_area} m^2")
    
    #calculate the weighted average WWR
    weighted_avg_wwr = sum_area_times_wwr/total_wall_area
    runner.registerInfo("Area-weighted WWR for this building is #{weighted_avg_wwr}")
    
    wwr_limit = 0.10 #unrealistically low limit for example
    if weighted_avg_wwr >= wwr_limit
      runner.registerWarning("NYSERDA - A WWR of #{weighted_avg_wwr} is greater than the NYSERDA limit of #{wwr_limit}")
    end
    
    #Building Area Check
    minimum_area = 9290.0 #9,290 m^2 = 100,000 ft^2
    bldg_area = model.building.get.floorArea
    if bldg_area < minimum_area
      runner.registerWarning("NYSERDA - The building area is #{bldg_area} m^2, which is less than the NYSERDA minimum size of #{minimum_area} m^2")
    end
    
    #LEED Check
    if leed_check == true
      runner.registerWarning("LEED - not enough bike racks!!")
    end
    
    #Write the warnings out to a file
    report = File.new("NYSERDA_QAQC_Report.txt", "w")
    report.puts("Baseline energy code = #{energy_code}")
    report.puts("Run LEED checks? = #{leed_check}")
    runner_results = runner.result 
    report.puts "**ERROR MESSAGES**"  
    runner_results.errors.each do |info_msg|
      report.puts "#{info_msg.logMessage}"
    end
    report.puts "**WARNING MESSAGES**"  
    runner_results.warnings.each do |info_msg|
      report.puts "#{info_msg.logMessage}"
    end
    report.puts "**INFO MESSAGES**"  
    runner_results.info.each do |info_msg|
      report.puts "#{info_msg.logMessage}"
    end
    report.close
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
NYSERDAModelQAQC.new.registerWithApplication