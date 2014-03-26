#start the measure
class ExampleQAQCReportingMeasures < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ExampleQAQCReportingMeasures"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)
    
    #use the built-in error checking on the arguments.  In this case, there are no arguments
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    #load the last model and the sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    
    #make a vector of all end uses in OpenStudio
    end_use_cat_types = []
    OpenStudio::EndUseCategoryType::getValues.each do |end_use_val|
      end_use_cat_types << OpenStudio::EndUseCategoryType.new(end_use_val)
    end

    #make a vector of all fuel types in OpenStudio
    end_use_fuel_types = []
    OpenStudio::EndUseFuelType::getValues.each do |end_use_fuel_type_val|
      end_use_fuel_types << OpenStudio::EndUseFuelType.new(end_use_fuel_type_val)
    end  

    #only attempt to get monthly data if enduses table is available from sql file
    if sql.endUses.is_initialized
      
      #the end uses table is available, so assign it to a variable
      end_uses_table = sql.endUses.get
      
      #loop through all the fuel types
      end_use_fuel_types.each do |end_use_fuel_type|
        #loop through all end uses categories in the fuel type
        end_use_cat_types.each do |end_use_cat_type|
          #get the energy consumption for this fuel type & end use combination
          energy_consumption = end_uses_table.getEndUse(end_use_fuel_type,end_use_cat_type)
          runner.registerInfo("energy consumption for #{end_use_fuel_type.valueName}:#{end_use_cat_type.valueName} = #{energy_consumption} GJ")
          
          #NOTE there are some helper methods available so not everything has to be written as a new query
          #http://openstudio.nrel.gov/latest-c-sdk-documentation
          #click on Utilities>SqlFile
          #all the methods are listed there (usually the names are self-explanatory) 
          
          #fake error check as an example
          if energy_consumption > 100 #100GJ
            runner.registerWarning("energy consumption for #{end_use_fuel_type.valueName}:#{end_use_cat_type.valueName} = #{energy_consumption} GJ; This seems too high (normal limit is 100GJ)")
          end
          
          #append the info to a file here.  Ruby can write to many different filetypes, googling should have examples
          #after running the file, look inside the directory for this measure and you should find "report.csv"
          #this filepath can be anywhere on your computer.
          #you could also make the user enter the filepath as a string argument if you wanted.
          File.open("report.csv", 'w') do |file|
            file << "#{end_use_fuel_type.valueName},#{end_use_cat_type.valueName},#{energy_consumption},GJ"
          end
            
        end
      end
      
    else

      puts "End-Use table not available in results file; could not retrieve monthly costs by end use"
      #runner.registerError("End-Use table not available in results; could not retrieve monthly costs by end use")

    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ExampleQAQCReportingMeasures.new.registerWithApplication