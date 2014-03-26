#start the measure
class ExtractionQAQCMeasures < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ExtractionQAQCMeasures"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    
    # perform queries on the sql file
    # look at eplustbl.htm to see how queries in tabulardatawithstrings correspond
    
    query = "SELECT Value FROM TabularDataWithStrings WHERE "
    query << "ReportName='SystemSummary' and " # Notice no space in SystemSummary
    query << "ReportForString='Entire Facility' and "
    query << "TableName='Time Setpoint Not Met' and "
    query << "RowName='Facility' and "
    query << "ColumnName='During Occupied Cooling' and "
    query << "Units='hr';"

    unmet_heating_hours = sqlFile.execAndReturnFirstDouble(query)
    
    if unmet_heating_hours.is_initialized
      runner.registerInfo("unmet heating hours = #{unmet_heating_hours}")
    end
       
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ExtractionQAQCMeasures.new.registerWithApplication