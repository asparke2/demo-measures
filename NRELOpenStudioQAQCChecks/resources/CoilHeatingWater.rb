
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilHeatingWater

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    maximum_water_flow_rate = self.autosizedMaximumWaterFlowRate
    if maximum_water_flow_rate.is_initialized
      self.setMaximumWaterFlowRate(maximum_water_flow_rate.get) 
    end
    
    u_factor_times_area_value = self.autosizedUFactorTimesAreaValue
    if u_factor_times_area_value.is_initialized
      self.setUFactorTimesAreaValue(u_factor_times_area_value.get)
    end
    
    rated_capacity = self.autosizedRatedCapacity
    if rated_capacity.is_initialized
      self.setRatedCapacity(rated_capacity.get) 
    end
        
  end

  # returns the autosized maximum water flow rate as an optional double
  def autosizedMaximumWaterFlowRate

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
              AND TableName='Coil:Heating:Water' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Water Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized u-factor times area value as an optional double
  def autosizedUFactorTimesAreaValue

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
              AND TableName='Coil:Heating:Water' 
              AND RowName='#{name}' 
              AND ColumnName='U-Factor Times Area Value' 
              AND Units='W/K'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
 # returns the autosized rated capacity as an optional double
  def autosizedRatedCapacity

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
              AND TableName='Coil:Heating:Water' 
              AND RowName='#{name}' 
              AND ColumnName='Design Coil Load' 
              AND Units='W'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
  
end
