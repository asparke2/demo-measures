
# open the class to add methods to return sizing values
class OpenStudio::Model::PumpVariableSpeed

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    rated_flow_rate = self.autosizedRatedFlowRate
    if rated_flow_rate.is_initialized
      self.setRatedFlowRate(rated_flow_rate.get) 
    end
    
    rated_power_consumption = self.autosizedRatedPowerConsumption
    if rated_power_consumption.is_initialized
      self.setRatedPowerConsumption(rated_power_consumption.get)
    end
    
    
  end

  # returns the autosized rated flow rate as an optional double
  def autosizedRatedFlowRate

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
              AND TableName='Pump:VariableSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized rated power consumption as an optional double
  def autosizedRatedPowerConsumption

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
              AND TableName='Pump:VariableSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Rated Power Consumption' 
              AND Units='W'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
  
end
