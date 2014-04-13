require 'erb'

#start the measure
class NRELOpenStudioQAQCChecks < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "NRELOpenStudioQAQCChecks"
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
    
    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)
 
    # load some the helper libraries
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
    require "#{@resource_path}/ThermalZone.rb" 
 
    # check the EUI of the building
    building = model.getBuilding
    
    #make sure all required data are available
    if sql.totalSiteEnergy.empty?
      runner.registerError("Site energy data unavailable; check not run")
    end
    
    total_site_energy_kBtu = OpenStudio::convert(sql.totalSiteEnergy.get, "GJ", "kBtu").get
    if total_site_energy_kBtu == 0
      runner.registerWarning("Model site energy use = 0; likely a problem with the model")
    end
  
    floor_area_ft2 = OpenStudio::convert(building.floorArea, "m^2", "ft^2").get
    if floor_area_ft2 == 0
      runner.registerError("The building has 0 floor area")
    end

    site_EUI = total_site_energy_kBtu / floor_area_ft2
    if site_EUI > 100
      runner.registerWarning("Site EUI of #{site_EUI} looks high for a school.  Look at other errors and warnings for possible issues.")
    end
    
    if site_EUI < 30
      runner.registerWarning("Site EUI of #{site_EUI} looks low for a school.  Look at other errors and warnings for possible issues.")
    end     
 
    # Check for systems that should have DCV but don't (from 90.1-2007):
    # 6.4.3.9 	Ventilation Controls for High-Occupancy Areas. 
    # Demand control ventilation (DCV) is required for spaces larger than 500 ft2 and 
    # with a design occupancy for ventilation of greater than 40 people per 1000 ft2 of floor area 
    # and served by systems with one or more of the following:
    # a.		an air-side economizer,
    # b.		automatic modulating control of the outdoor air damper, or
    # c.		a design outdoor airflow greater than 3000 cfm.
    model.getThermalZones.each do |zone|
      
      # skip zones not connected to an air loop
      next if not zone.airLoopHVAC.is_initialized
      
      # get the zone area
      next if not zone.floorArea
      area_m2 = zone.floorArea
      area_ft2 = OpenStudio::convert(area_m2,"m^2","ft^2").get
      
      # skip areas smaller than 500 ft2
      next if area_ft2 < 500
      
      density_or_oa_req_dcv = false
      
      # get the area per occupant
      # DCV required if density more than 40 people / 1000 ft2
      area_per_occupant_m2 = zone.areaPerOccupant
      if not area_per_occupant_m2.is_initialized
        runner.registerWarning("Could not find area per occupant for #{zone.name}.")
        next
      end
      area_per_occupant_m2 = area_per_occupant_m2.get
      area_per_occupant_ft2 = OpenStudio::convert(area_per_occupant_m2,"m^2","ft^2").get
      occupant_per_area_ft2 = 1/area_per_occupant_ft2
      occ_per_thousand_ft2 = occupant_per_area_ft2 * 1000
      if occ_per_thousand_ft2 > (40)
        runner.registerInfo("'#{zone.name}' occ density of #{occ_per_thousand_ft2} people/1000ft2 is greater than 40 people/1000 ft2; requires DCV.")
        density_or_oa_req_dcv = true
      end

      # get the total OA cfm
      # DCV required if design OA more than 3000 cfm
      if not zone.volumeFromOACalc.is_initialized
        runner.registerWarning("Could not find volume for #{zone.name}.")
        next
      end
      volume_m3 = zone.volumeFromOACalc.get
      volume_ft3 = OpenStudio::convert(volume_m3,"m^3","ft^3").get   
      if not zone.averageOutdoorAirACH.is_initialized
        runner.registerWarning("Could not find volume for #{zone.name}.")
        next
      end
      oa_ach = zone.averageOutdoorAirACH.get
      zone_oa_m3_per_hr = volume_m3 * oa_ach
      zone_oa_ft3_per_min = OpenStudio::convert(zone_oa_m3_per_hr,"m^3/hr","ft^3/min").get
      if zone_oa_ft3_per_min > 3000.0     
        runner.registerInfo("'#{zone.name}' design OA of #{zone_oa_ft3_per_min} cfm is greater than 3000 cfm; requires DCV.")
        density_or_oa_req_dcv = true
      end
      
      # skip spaces that don't require DCV
      next if density_or_oa_req_dcv == false
 
      # this space requires DCV; check if already installed
      air_loop = zone.airLoopHVAC.get
      air_loop.supplyComponents.each do |sup_comp|
        if sup_comp.to_AirLoopHVACOutdoorAirSystem.is_initialized
          oa_sys = sup_comp.to_AirLoopHVACOutdoorAirSystem.get
          # get ControllerOutdoorAir
          controller_oa = oa_sys.getControllerOutdoorAir
          # get ControllerMechanicalVentilation
          controller_mv = controller_oa.controllerMechanicalVentilation
          # warn if demand control is not enabled
          if controller_mv.demandControlledVentilation == false
            runner.registerWarning("Zone '#{zone.name}' on Air Loop '#{air_loop.name}' should
                                    have DCV enabled per 90.1, but does not.  DCV is
                                    required because the zone has a high occupant density
                                    or OA flow rate. Without DCV, the HVAC systems will provide much more ventilation than 
                                    necessary during times when the space is lightly occupied.  This
                                    will typically result in unreasonably high heating and/or
                                    cooling energy consumption.  To turn on DCV, go to the 
                                    HVAC systems tab, find the Air Loop '#{air_loop.name}',
                                    go to the controls pane, and toggle DCV to 'On.'")
          end
        end
      end
    end

    #closing the sql file
    sql.close()

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
NRELOpenStudioQAQCChecks.new.registerWithApplication