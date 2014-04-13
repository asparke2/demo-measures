
# open the class to add methods to size all HVAC equipment
class OpenStudio::Model::Model

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into all objects model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    # Ensure that the model has a sql file associated with it
    if not self.sqlFile.is_initialized
      puts "failed to apply sizing values for '#{name}' because sql file missing"
      return false
    end
  
    # Zone equipment
    # Air terminals
    self.getAirTerminalSingleDuctParallelPIUReheats.each {|obj| obj.applySizingValues}
    self.getAirTerminalSingleDuctVAVReheats.each {|obj| obj.applySizingValues}
    self.getAirTerminalSingleDuctUncontrolleds.each {|obj| obj.applySizingValues}
    # TODO VAV no reheat
    # TODO CAV reheat
    # TODO Cooled beam
    # Zone level heating
    # TODO water baseboard heating
    # TODO electric baseboard
    # TODO unit heater
    # TODO PTAC
    # TODO PTHP
    # TODO Zone Exhaust Fan
    # TODO four pipe fan coil
    # TODO water to air heat pump
    # TODO var flow radiant
    # TODO const flow radiant
    # TODO electric radiant
     
    # AirLoopHVAC components
    self.getAirLoopHVACs.each {|obj| obj.applySizingValues}
    # fans
    self.getFanConstantVolumes.each {|obj| obj.applySizingValues}
    self.getFanVariableVolumes.each {|obj| obj.applySizingValues}
    # Heating coils
    self.getCoilHeatingElectrics.each {|obj| obj.applySizingValues}
    self.getCoilHeatingGass.each {|obj| obj.applySizingValues}
    self.getCoilHeatingWaters.each {|obj| obj.applySizingValues}
    # TODO dx heat pump coils
    # Cooling coils
    self.getCoilCoolingDXSingleSpeeds.each {|obj| obj.applySizingValues}
    self.getCoilCoolingDXTwoSpeeds.each {|obj| obj.applySizingValues}
    self.getCoilCoolingWaters.each {|obj| obj.applySizingValues}
    # TODO dx heat pump coils
    # Outdoor air
    self.getControllerOutdoorAirs.each {|obj| obj.applySizingValues}
    # TODO evap cooler
    # TODO heat exchanger sensbile and latent
    
    # PlantLoop components
    self.getPlantLoops.each {|obj| obj.applySizingValues}
    # Pumps
    self.getPumpConstantSpeeds.each {|obj| obj.applySizingValues}
    self.getPumpVariableSpeeds.each {|obj| obj.applySizingValues}
    # Heating equipment
    self.getBoilerHotWaters.each {|obj| obj.applySizingValues}
    # Cooling equipment
    self.getChillerElectricEIRs.each {|obj| obj.applySizingValues}
    # Condenser equipment
    self.getCoolingTowerSingleSpeeds.each {|obj| obj.applySizingValues}
    # TODO evap fluid cooler
    # Controls
    self.getControllerWaterCoils.each {|obj| obj.applySizingValues}
    # TODO two speed cooling towers
    # Misc
    # TODO ground heat exchanger?
    
    # VRF components
    # TODO VRF system
    # TODO VRF terminal
    
    # Refrigeration components
    
    return true
    
  end

end
