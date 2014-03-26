#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddPFPBoxesWithHotWaterReheat < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddPFPBoxesWithHotWaterReheat"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for hot water loop name
    hw_loop_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("hw_loop_name",true)
    hw_loop_name.setDisplayName("Name of the hot water loop")
    args << hw_loop_name    

    #make an argument for air loop name
    air_loop_name = OpenStudio::Ruleset::OSArgument::makeStringArgument("air_loop_name",true)
    air_loop_name.setDisplayName("Name of the hot water loop")
    args << air_loop_name  

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
    hw_loop_name = runner.getStringArgumentValue("hw_loop_name",user_arguments)
    air_loop_name = runner.getStringArgumentValue("air_loop_name",user_arguments)
    
    #add a PFP with hot water reheat to each zone
    hw_loop = nil
    if model.getPlantLoopByName(hw_loop_name).is_initialized
      hw_loop = model.getPlantLoopByName(hw_loop_name).get
    else
      runner.registerWarning("Could not find a loop called #{hw_loop_name} to attach reheat coils to; not hooking them up.")
    end
    
    #get the airloop
    air_loop = nil
    if model.getAirLoopHVACByName(air_loop_name).is_initialized
      air_loop = model.getAirLoopHVACByName(air_loop_name).get
    else
      runner.registerWarning("Could not find an air loop called #{air_loop_name} to attach terminals to; not hooking them up.")
    end    
    
    if hw_loop and air_loop
      zones = []
      zones << model.getThermalZoneByName("8120 Perimeter").get
      zones << model.getThermalZoneByName("8120 Core").get
      
      zones.each do |zone|
        #make a terminal
        htg_coil = OpenStudio::Model::CoilHeatingWater.new(model,model.alwaysOnDiscreteSchedule)
        fan = OpenStudio::Model::FanConstantVolume.new(model, model.alwaysOnDiscreteSchedule)
        terminal = OpenStudio::Model::AirTerminalSingleDuctParallelPIUReheat.new(model, model.alwaysOnDiscreteSchedule, fan, htg_coil)
        #hook the terminal to the zone
        air_loop.addBranchForZone(zone,terminal)
        #hook up the reheat coil to the plantloop
        hw_loop.addDemandBranchForComponent(htg_coil)
        
      end
      
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddPFPBoxesWithHotWaterReheat.new.registerWithApplication