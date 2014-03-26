#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ImportRefrigerationCasesandWalkins < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ImportRefrigerationCasesandWalkins"
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

    #load the ruby library to open a spreadsheet
    #this only works on windows
    require 'rubygems'
    require 'win32ole'

    #load the data from the spreadsheet into ruby
    data_path = "#{Dir.pwd}/resources/refrigeration_equip.xlsx"
    #enable Excel
    xl = WIN32OLE::new('Excel.Application')
    #open workbook
    wb = xl.workbooks.open(data_path)
    #get the cases data
    cases_ws = wb.worksheets("cases")
    cases_data = cases_ws.range('E3:AI375')['Value']
    cases_cols = cases_data.transpose
    cases_rows = cases_data
    #get the walkins data
    walkins_ws = wb.worksheets("walk-ins")
    walkins_data = walkins_ws.range('D3:J35')['Value']
    walkins_cols = walkins_data.transpose
    walkins_rows = walkins_data
    #close workbook
    wb.Close(1)
    #quit Excel
    xl.Quit
 
    #load the ruby helper libraries for creating objects
    require "#{Dir.pwd}/resources/cases.rb"
    require "#{Dir.pwd}/resources/walkins.rb"
    
    #make the runner accessible by all the helper methods
    @runner = runner
      
    #create a new case for each column
    cases_cols.each do |case_col|
      ref_case = create_case(case_col, model) #this method is defined in resources/cases.rb
    end
      
    #create a new walkin for each column
    walkins_cols.each do |walkin_col|
      runner.registerInfo("#{walkin_col}")
      #ref_case = create_case(walkin_col, model) #this method is defined in resources/walkins.rb
    end    
    
    
      
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ImportRefrigerationCasesandWalkins.new.registerWithApplication