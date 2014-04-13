
# open the class to add methods to return sizing values
class OpenStudio::Model::AirTerminalSingleDuctVAVReheat

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues
       
    rated_flow_rate = self.autosizedMaximumAirFlowRate
    if rated_flow_rate.is_initialized
      self.setMaximumAirFlowRate(rated_flow_rate.get) 
    end
    
    maximum_hot_water_or_steam_flow_rate = self.autosizedMaximumHotWaterOrSteamFlowRate
    if maximum_hot_water_or_steam_flow_rate.is_initialized
      self.setMaximumHotWaterOrSteamFlowRate(maximum_hot_water_or_steam_flow_rate.get)
    end
    
    maximum_flow_per_zone_floor_area_during_reheat = self.autosizedMaximumFlowPerZoneFloorAreaDuringReheat
    if maximum_flow_per_zone_floor_area_during_reheat.is_initialized
      self.setMaximumFlowPerZoneFloorAreaDuringReheat(maximum_flow_per_zone_floor_area_during_reheat.get) 
    end
    
    maximum_flow_fraction_during_reheat = self.autosizedMaximumFlowFractionDuringReheat
    if maximum_flow_fraction_during_reheat.is_initialized
      self.setMaximumFlowFractionDuringReheat(maximum_flow_fraction_during_reheat.get)
    end

  end

  # returns the autosized maximum air flow rate as an optional double
  def autosizedMaximumAirFlowRate

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
              AND TableName='AirTerminal:SingleDuct:VAV:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized rated power consumption as an optional double
  def autosizedMaximumHotWaterOrSteamFlowRate

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
              AND TableName='AirTerminal:SingleDuct:VAV:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Reheat Water Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
 # returns the autosized maximum flow per zone floor area during reheat as an optional double
  def autosizedMaximumFlowPerZoneFloorAreaDuringReheat

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
              AND TableName='AirTerminal:SingleDuct:VAV:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Flow per Zone Floor Area during Reheat' 
              AND Units='m3/s-m2'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
 # returns the autosized maximum flow fraction during reheat as an optional double
  def autosizedMaximumFlowFractionDuringReheat

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
              AND TableName='AirTerminal:SingleDuct:VAV:Reheat' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Flow Fraction during Reheat'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end    
  
  

  
end
