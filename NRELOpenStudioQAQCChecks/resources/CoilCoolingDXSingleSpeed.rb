
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilCoolingDXTwoSpeed

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    rated_air_flow_rate = self.autosizedRatedAirFlowRate
    if rated_air_flow_rate.is_initialized
      self.setRatedAirFlowRate(rated_air_flow_rate.get) 
    end

    rated_total_cooling_capacity = self.autosizedRatedTotalCoolingCapacity
    if rated_total_cooling_capacity.is_initialized
      self.setRatedTotalCoolingCapacity(rated_total_cooling_capacity.get) 
    end    

    rated_sensible_heat_ratio = self.autosizedRatedSensibleHeatRatio
    if rated_sensible_heat_ratio.is_initialized
      self.setRatedSensibleHeatRatio(rated_sensible_heat_ratio.get) 
    end     
      
  end

  # returns the autosized rated air flow rate as an optional double
  def autosizedRatedAirFlowRate

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
              AND TableName='Coil:Cooling:DX:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated High Speed Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized rated total cooling capacity as an optional double
  def autosizedRatedTotalCoolingCapacity

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
              AND TableName='Coil:Cooling:DX:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated High Speed Total Cooling Capacity (gross)' 
              AND Units='W'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized rated sensible heat ratio as an optional double
  def autosizedRatedSensibleHeatRatio

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
              AND TableName='Coil:Cooling:DX:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated High Speed Sensible Heat Ratio'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  
end
