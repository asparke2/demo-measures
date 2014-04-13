
# open the class to add methods to return sizing values
class OpenStudio::Model::CoolingTowerSingleSpeed

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    design_water_flow_rate = self.autosizedDesignWaterFlowRate
    if design_water_flow_rate.is_initialized
      self.setDesignWaterFlowRate(design_water_flow_rate.get) 
    end

    fan_power_at_design_air_flow_rate = self.autosizedFanPoweratDesignAirFlowRate
    if fan_power_at_design_air_flow_rate.is_initialized
      self.setFanPoweratDesignAirFlowRate(fan_power_at_design_air_flow_rate.get) 
    end

    design_air_flow_rate = self.autosizedDesignAirFlowRate
    if design_air_flow_rate.is_initialized
      self.setDesignAirFlowRate(design_air_flow_rate.get) 
    end

    u_factor_times_area_value_at_design_air_flow_rate = self.autosizedUFactorTimesAreaValueatDesignAirFlowRate
    if u_factor_times_area_value_at_design_air_flow_rate.is_initialized
      self.setUFactorTimesAreaValueatDesignAirFlowRate(u_factor_times_area_value_at_design_air_flow_rate.get) 
    end

    air_flow_rate_in_free_convection_regime = self.autosizedAirFlowRateinFreeConvectionRegime
    if air_flow_rate_in_free_convection_regime.is_initialized
      self.setAirFlowRateinFreeConvectionRegime(air_flow_rate_in_free_convection_regime.get) 
    end

    u_factor_times_area_value_at_free_convection_air_flow_rate = self.autosizedUFactorTimesAreaValueatFreeConvectionAirFlowRate
    if u_factor_times_area_value_at_free_convection_air_flow_rate.is_initialized
      self.setUFactorTimesAreaValueatFreeConvectionAirFlowRate(u_factor_times_area_value_at_free_convection_air_flow_rate.get) 
    end
    
  end

  # returns the autosized design water flow rate as an optional double
  def autosizedDesignWaterFlowRate

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
              AND TableName='CoolingTower:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Design Water Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized fan power at design air flow rate as an optional double
  def autosizedFanPoweratDesignAirFlowRate

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
              AND TableName='CoolingTower:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Fan Power at Design Air Flow Rate'
              AND Units='W'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized reference design air flow rate as an optional double
  def autosizedDesignAirFlowRate

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
              AND TableName='CoolingTower:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Design Air Flow Rate'
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized u-factor times area value at design air flow rate as an optional double
  def autosizedUFactorTimesAreaValueatDesignAirFlowRate

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
              AND TableName='CoolingTower:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='U-Factor Times Area Value at Design Air Flow Rate' 
              AND Units='W/C'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized air flow rate in free convection regime as an optional double
  def autosizedAirFlowRateinFreeConvectionRegime

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
              AND TableName='CoolingTower:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='Air Flow Rate in Free Convection Regime'
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized u-factor times area value in free convection as an optional double
  def autosizedUFactorTimesAreaValueatFreeConvectionAirFlowRate

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
              AND TableName='CoolingTower:SingleSpeed' 
              AND RowName='#{name}' 
              AND ColumnName='U-Factor Times Area Value at Free Convection Air Flow Rate'
              AND Units='W/C'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
    
  
end
