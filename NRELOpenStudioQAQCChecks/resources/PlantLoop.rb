
# open the class to add methods to return sizing values
class OpenStudio::Model::PlantLoop

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    maximum_loop_flow_rate = self.autosizedMaximumLoopFlowRate
    if maximum_loop_flow_rate.is_initialized
      self.setMaximumLoopFlowRate(maximum_loop_flow_rate.get) 
    end

    plant_loop_volume = self.autosizedPlantLoopVolume
    if plant_loop_volume.is_initialized
      self.setPlantLoopVolume(plant_loop_volume.get) 
    end
    
  end

  # returns the autosized maximum loop flow rate as an optional double
  def autosizedMaximumLoopFlowRate

    result = OpenStudio::OptionalDouble.new()

    name = self.name.get.upcase
    
    model = self.model
    
    sql = model.sqlFile
    
    if sql.is_initialized
      sql = sql.get
    
      query = "SELECT Value 
              FROM tabulardatawithstrings 
              WHERE ReportName='ComponentSizingSummary' 
              AND ReportForString='Entire Facility' 
              AND TableName='PlantLoop' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Loop Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized plant loop volume as an optional double
  def autosizedPlantLoopVolume

    result = OpenStudio::OptionalDouble.new()

    name = self.name.get.upcase
    
    model = self.model
    
    sql = model.sqlFile
    
    if sql.is_initialized
      sql = sql.get
    
      query = "SELECT Value 
              FROM tabulardatawithstrings 
              WHERE ReportName='ComponentSizingSummary' 
              AND ReportForString='Entire Facility' 
              AND TableName='PlantLoop' 
              AND RowName='#{name}' 
              AND ColumnName='Plant Loop Volume'
              AND Units='m3'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  
end
