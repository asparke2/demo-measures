#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class WalmartAHUandRTU < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "WalmartAHUandRTU"
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
	
	#copy all the objects from the rer_sys.idf into the model    
    objects = idf_resource_file.objects
    workspace.addObjects(objects)
 
   end #end the run method

end #end the measure

#this allows the measure to be use by the application
WalmartAHUandRTU.new.registerWithApplication