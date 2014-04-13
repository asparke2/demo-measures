
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilCoolingDXTwoSpeed

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    rated_high_speed_air_flow_rate = self.autosizedRatedHighSpeedAirFlowRate
    if rated_high_speed_air_flow_rate.is_initialized
      self.setRatedHighSpeedAirFlowRate(rated_high_speed_air_flow_rate.get) 
    end

    rated_high_speed_total_cooling_capacity = self.autosizedRatedHighSpeedTotalCoolingCapacity
    if rated_high_speed_total_cooling_capacity.is_initialized
      self.setRatedHighSpeedTotalCoolingCapacity(rated_high_speed_total_cooling_capacity.get) 
    end    

    rated_high_speed_sensible_heat_ratio = self.autosizedRatedHighSpeedSensibleHeatRatio
    if rated_high_speed_sensible_heat_ratio.is_initialized
      self.setRatedHighSpeedSensibleHeatRatio(rated_high_speed_sensible_heat_ratio.get) 
    end     
    
    rated_low_speed_air_flow_rate = self.autosizedRatedLowSpeedAirFlowRate
    if rated_low_speed_air_flow_rate.is_initialized
      self.setRatedLowSpeedAirFlowRate(rated_low_speed_air_flow_rate.get) 
    end  

    rated_low_speed_total_cooling_capacity = self.autosizedRatedLowSpeedTotalCoolingCapacity
    if rated_low_speed_total_cooling_capacity.is_initialized
      self.setRatedLowSpeedTotalCoolingCapacity(rated_low_speed_total_cooling_capacity.get) 
    end  
      
  end

  # returns the autosized rated high speed air flow rate as an optional double
  def autosizedRatedHighSpeedAirFlowRate

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
              AND TableName='Coil:Cooling:DX:TwoSpeed' 
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

  # returns the autosized rated high speed total cooling capacity as an optional double
  def autosizedRatedHighSpeedTotalCoolingCapacity

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
              AND TableName='Coil:Cooling:DX:TwoSpeed' 
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
  
  # returns the autosized rated high speed sensible heat ratio as an optional double
  def autosizedRatedHighSpeedSensibleHeatRatio

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
              AND TableName='Coil:Cooling:DX:TwoSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated High Speed Sensible Heat Ratio'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized rated low speed air flow rate as an optional double
  def autosizedRatedLowSpeedAirFlowRate

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
              AND TableName='Coil:Cooling:DX:TwoSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated Low Speed Air Flow Rate ' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized rated low speed total cooling capacity as an optional double
  def autosizedRatedLowSpeedTotalCoolingCapacity

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
              AND TableName='Coil:Cooling:DX:TwoSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated Low Speed Total Cooling Capacity (gross)' 
              AND Units='W'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end


end
