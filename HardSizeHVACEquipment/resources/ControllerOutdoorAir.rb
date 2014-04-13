
# open the class to add methods to return sizing values
class OpenStudio::Model::ControllerOutdoorAir

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    maximum_outdoor_air_flow_rate = self.autosizedMaximumOutdoorAirFlowRate
    if maximum_outdoor_air_flow_rate.is_initialized
      self.setMaximumOutdoorAirFlowRate(maximum_outdoor_air_flow_rate.get) 
    end

    minimum_outdoor_air_flow_rate = self.autosizedMinimumOutdoorAirFlowRate
    if minimum_outdoor_air_flow_rate.is_initialized
      self.setMinimumOutdoorAirFlowRate(minimum_outdoor_air_flow_rate.get) 
    end
    
  end

  # returns the autosized maximum outdoor air flow rate as an optional double
  def autosizedMaximumOutdoorAirFlowRate

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
              AND TableName='Controller:OutdoorAir' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Outdoor Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized minimum outdoor air flow rate as an optional double
  def autosizedMinimumOutdoorAirFlowRate

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
              AND TableName='Controller:OutdoorAir' 
              AND RowName='#{name}' 
              AND ColumnName='Minimum Outdoor Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  
end
