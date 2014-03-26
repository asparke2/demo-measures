#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddVAVTerminalwithHotWaterReheatandFourPipeFanCoiltoEachZone < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddVAVTerminalwithHotWaterReheatandFourPipeFanCoiltoEachZone"
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

    hw_loop_name = "Hot Water Loop"
    air_loop_name = "VAV with Reheat"
    chw_loop_name = "Chilled Water Loop"
    
    #add a PFP with hot water reheat to each zone
    hw_loop = nil
    if model.getPlantLoopByName(hw_loop_name).is_initialized
      hw_loop = model.getPlantLoopByName(hw_loop_name).get
    else
      runner.registerWarning("Could not find a loop called #{hw_loop_name} to attach reheat coils to; not hooking them up.")
    end
    
    chw_loop = nil
    if model.getPlantLoopByName(chw_loop_name).is_initialized
      chw_loop = model.getPlantLoopByName(chw_loop_name).get
    else
      runner.registerWarning("Could not find a loop called #{chw_loop_name} to attach cooling coils to; not hooking them up.")
    end
    
    #get the airloop
    air_loop = nil
    if model.getAirLoopHVACByName(air_loop_name).is_initialized
      air_loop = model.getAirLoopHVACByName(air_loop_name).get
    else
      runner.registerWarning("Could not find an air loop called #{air_loop_name} to attach terminals to; not hooking them up.")
    end    
    
    if hw_loop and air_loop and chw_loop
      model.getThermalZones.each do |zone|
        #make a terminal
        term_htg_coil = OpenStudio::Model::CoilHeatingWater.new(model,model.alwaysOnDiscreteSchedule)
        terminal = OpenStudio::Model::AirTerminalSingleDuctVAVReheat.new(model, model.alwaysOnDiscreteSchedule, term_htg_coil)
        #hook the terminal to the zone
        air_loop.addBranchForZone(zone,terminal)
        #hook up the reheat coil to the plantloop
        hw_loop.addDemandBranchForComponent(term_htg_coil)
        #make a FPFC
        fpfc_fan = OpenStudio::Model::FanConstantVolume.new(model, model.alwaysOnDiscreteSchedule)
        fpfc_clg_coil = OpenStudio::Model::CoilCoolingWater.new(model,model.alwaysOnDiscreteSchedule)
        fpfc_htg_coil = OpenStudio::Model::CoilHeatingWater.new(model,model.alwaysOnDiscreteSchedule)
        fpfc = OpenStudio::Model::ZoneHVACFourPipeFanCoil.new(model, model.alwaysOnDiscreteSchedule,fpfc_fan, fpfc_clg_coil, fpfc_htg_coil)
        fpfc.addToThermalZone(zone)
        #set the FPFC OA to zero
        fpfc.setMaximumOutdoorAirFlowRate(0.0)
        #hook up the cooling coil to the chilled water loop
        chw_loop.addDemandBranchForComponent(fpfc_clg_coil)
        #hook up the hot water coil to the hot water loop
        hw_loop.addDemandBranchForComponent(fpfc_htg_coil)        
      end
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddVAVTerminalwithHotWaterReheatandFourPipeFanCoiltoEachZone.new.registerWithApplication