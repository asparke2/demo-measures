#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class HardSizeHVACEquipment < OpenStudio::Ruleset::ModelUserScript
  
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "HardSizeHVACEquipment"
  end
  
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
        
    return args
  end #end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # make a copy of the model and set up for sizing run
    sizing_model = model
    
    # report the sizing factors being used
    siz_params = model.getSimulationControl.sizingParameters
    if siz_params.is_initialized
      siz_params = siz_params.get
    else
      siz_params_idf = OpenStudio::IdfObject.new OpenStudio::Model::SizingParameters::iddObjectType
      model.addObject siz_params_idf
      siz_params = model.getSimulationControl.sizingParameters.get
    end
    runner.registerInfo("The heating sizing factor for the model is #{siz_params.heatingSizingFactor}.  90.1 Appendix G requires 1.25.")
    runner.registerInfo("The cooling sizing factor for the model is #{siz_params.coolingSizingFactor}.  90.1 Appendix G requires 1.15.")
    
    # set the simulation to only run the sizing
    sim_control = sizing_model.getSimulationControl
    sim_control.setRunSimulationforSizingPeriods(true)
    sim_control.setRunSimulationforWeatherFileRunPeriods(false)
    
    # save the model to energyplus idf
    idf_directory = Dir.pwd
    idf_name = "sizing.idf"
    runner.registerInfo("Saving sizing idf to #{idf_directory} as '#{idf_name}'")
    forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new()
    workspace = forward_translator.translateModel(sizing_model)
    idf_path = OpenStudio::Path.new("#{idf_directory}/#{idf_name}")    
    workspace.save(idf_path,true)
    
    # set up to run the sizing simulation
    require 'openstudio/energyplus/find_energyplus'
    epw_path = OpenStudio::Path.new("#{Dir.pwd}/in.epw")
    if not File.file?("#{epw_path}")
      epw_path = OpenStudio::Path.new("#{Dir.pwd}/../in.epw")
    end
 
    # find energyplus
    ep_hash = OpenStudio::EnergyPlus::find_energyplus(8,0)
    ep_path = OpenStudio::Path.new(ep_hash[:energyplus_exe].to_s)
    idd_path = OpenStudio::Path.new(ep_hash[:energyplus_idd].to_s)
    weather_path = OpenStudio::Path.new(ep_hash[:energyplus_weatherdata].to_s)
        
    # make a run manager
    run_manager_db_path = OpenStudio::Path.new("#{idf_directory}/sizing_run.db")
    run_manager = OpenStudio::Runmanager::RunManager.new(run_manager_db_path, true)

    # setup tool info to pass run manager the location of energy plus
    ep_tool = OpenStudio::Runmanager::ToolInfo.new(ep_path)
    ep_tool_info = OpenStudio::Runmanager::Tools.new()
    ep_tool_info.append(ep_tool)

    # get the run manager configuration options
    config_options = run_manager.getConfigOptions()
    output_path = OpenStudio::Path.new("#{idf_directory}/")
            
    # make a job for the file we want to run
    job = OpenStudio::Runmanager::JobFactory::createEnergyPlusJob(ep_tool,
                                                                 idd_path,
                                                                 idf_path,
                                                                 epw_path,
                                                                 output_path)
    
    # put the job in the run queue
    run_manager.enqueue(job, true)

    # run then wait for jobs to complete
    while run_manager.workPending()
      sleep 1
      OpenStudio::Application::instance().processEvents()
    end
    runner.registerInfo("Finished sizing run.")
    
    # load the sql file, exiting and erroring if a problem is found
    sql_path = OpenStudio::Path.new("#{idf_directory}/Energyplus/eplusout.sql")
    if OpenStudio::exists(sql_path)
      sql = OpenStudio::SqlFile.new(sql_path)
      # attach the sql file from the run to the sizing model
      attach_sql = model.setSqlFile(sql)
    else 
      runner.registerError("#{sql_path} couldn't be found")
      return false
    end
    
    # load the helper libraries
    @resource_path = "#{File.dirname(__FILE__)}/resources"
    require "#{@resource_path}/Model.rb"
    require "#{@resource_path}/AirTerminalSingleDuctParallelPIUReheat.rb"
    require "#{@resource_path}/AirTerminalSingleDuctVAVReheat.rb"
    require "#{@resource_path}/AirTerminalSingleDuctUncontrolled.rb"
    require "#{@resource_path}/AirLoopHVAC.rb"
    require "#{@resource_path}/FanConstantVolume.rb"
    require "#{@resource_path}/FanVariableVolume.rb"
    require "#{@resource_path}/CoilHeatingElectric.rb"
    require "#{@resource_path}/CoilHeatingGas.rb"
    require "#{@resource_path}/CoilHeatingWater.rb"
    require "#{@resource_path}/CoilCoolingDXSingleSpeed.rb"
    require "#{@resource_path}/CoilCoolingDXTwoSpeed.rb"
    require "#{@resource_path}/CoilCoolingWater.rb"
    require "#{@resource_path}/ControllerOutdoorAir.rb"
    require "#{@resource_path}/PlantLoop.rb"
    require "#{@resource_path}/PumpConstantSpeed.rb"
    require "#{@resource_path}/PumpVariableSpeed.rb"
    require "#{@resource_path}/BoilerHotWater.rb"
    require "#{@resource_path}/ChillerElectricEIR.rb"
    require "#{@resource_path}/CoolingTowerSingleSpeed.rb"
    require "#{@resource_path}/ControllerWaterCoil.rb"
    
    # hard size the HVAC equipment
    apply_sizes_success = model.applySizingValues
    if apply_sizes_success
      runner.registerInfo("Successfully applied component sizing values.")
    else
      runner.registerInfo("Failed to apply component sizing values.")
    end
    
    # set the simulation back to running the weather file
    sim_control.setRunSimulationforSizingPeriods(false)
    sim_control.setRunSimulationforWeatherFileRunPeriods(true)
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
HardSizeHVACEquipment.new.registerWithApplication