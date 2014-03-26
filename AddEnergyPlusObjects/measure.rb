
#####This file shows 3 ways to add EnergyPlus objects to the idf directly######

#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#start the measure
class AddEnergyPlusObjects < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddEnergyPlusObjects"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    ###add objects from an idf file to a workspace
    
    #setup the path to the resource file
    #the file name can be whatever you want, doesn't have to be
    #called "resources.idf" and you can have multiple .idf files
    #inside this directory
    idf_resource_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources.idf")

    #load the resource file
    idf_resource_file = OpenStudio::IdfFile::load(idf_resource_path)

    #make sure the idf file exists, and if it does, get it
    if idf_resource_file.is_initialized   
      idf_resource_file = idf_resource_file.get  
    else
      runner.registerError("Unable to find the file #{idf_resource_path}")
      return false 
    end

    #get the schedule:compact objects out of the resource idf file
    schedules = idf_resource_file.getObjectsByType("Schedule:Compact".to_IddObjectType)

    #add these schedules to the idf
    workspace.addObjects(schedules)
    runner.registerInfo("Added #{schedules.size} Schedule:Compacts to the idf")
   
    ###remove objects of a certain type from the idf
    
    #get the objects
    objs_to_remove = []
    workspace.getObjectsByType("LifeCycleCost:Parameters".to_IddObjectType).each do |object|
      objs_to_remove << object.handle
    end

    #remove the objects
    workspace.removeObjects(objs_to_remove)
    runner.registerInfo("removed all of the LifeCycleCost:Parameters object from the idf")   
   
    ###add a single object to the idf from a string

    #define the text of the object
    life_cycle_params_string = "    
    LifeCycleCost:Parameters,
    FEMP LifeCycle Cost Parameters,         !- Name
    EndOfYear,                              !- Discounting Convention
    ConstantDollar,                         !- Inflation Approach
    0.03,                                   !- Real Discount Rate
    ,                                       !- Nominal Discount Rate
    ,                                       !- Inflation
    ,                                       !- Base Date Month
    2011,                                   !- Base Date Year
    ,                                       !- Service Date Month
    2011,                                   !- Service Date Year
    25,                                     !- Length of Study Period in Years
    ,                                       !- Tax rate
    None;                                   !- Depreciation Method	  
    "  

    #load the string into an idf object
    life_cycle_params = OpenStudio::IdfObject::load(life_cycle_params_string).get

    #add the idf object
    workspace.addObject(life_cycle_params) 
    runner.registerInfo("Added #{life_cycle_params} to the idf")
 
    ###editing an existing object in the idf
    
    #get the first timestep object
    timestep = workspace.getObjectsByType("Timestep".to_IddObjectType)[0]
    #set the 0th field's value to 4
    timestep.setString(0,"4")
    runner.registerInfo("Changed a field in the object #{timestep}")


    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddEnergyPlusObjects.new.registerWithApplication