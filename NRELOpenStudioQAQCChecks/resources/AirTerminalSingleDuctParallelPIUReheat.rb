
# open the class to add methods to return sizing values
class OpenStudio::Model::AirTerminalSingleDuctVAVReheat

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    maximum_primary_air_flow_rate = self.autosizedMaximumPrimaryAirFlowRate
    if maximum_primary_air_flow_rate.is_initialized
      self.setMaximumPrimaryAirFlowRate(maximum_primary_air_flow_rate.get) 
    end
    
    maximum_secondary_air_flow_rate = self.autosizedMaximumSecondaryAirFlowRate
    if maximum_secondary_air_flow_rate.is_initialized
      self.setMaximumSecondaryAirFlowRate(maximum_secondary_air_flow_rate.get)
    end
    
    minimum_primary_air_flow_fraction = self.autosizedMinimumPrimaryAirFlowFraction
    if minimum_primary_air_flow_fraction.is_initialized
      self.setMinimumPrimaryAirFlowFraction(minimum_primary_air_flow_fraction.get) 
    end
    
    fan_on_flow_fraction = self.autosizedFanOnFlowFraction
    if fan_on_flow_fraction.is_initialized
      self.setFanOnFlowFraction(fan_on_flow_fraction.get)
    end

    
  end

  # returns the autosized maximum primary air flow rate as an optional double
  def autosizedMaximumPrimaryAirFlowRate

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
              AND TableName='AirTerminal:SingleDuct:ParallelPIU:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Primary Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized maximum secondary air flow rate as an optional double
  def autosizedMaximumSecondaryAirFlowRate

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
              AND TableName='AirTerminal:SingleDuct:ParallelPIU:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Secondary Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
 # returns the autosized minimum primary air flow fraction as an optional double
  def autosizedMinimumPrimaryAirFlowFraction

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
              AND TableName='AirTerminal:SingleDuct:ParallelPIU:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Minimum Primary Air Flow Fraction'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
 # returns the autosized fan on flow fraction as an optional double
  def autosizedFanOnFlowFraction

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
              AND TableName='AirTerminal:SingleDuct:ParallelPIU:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Fan On Flow Fraction'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end    
  
    
end
