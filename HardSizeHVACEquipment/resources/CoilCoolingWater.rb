
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilCoolingWater

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    design_water_flow_rate = self.autosizedDesignWaterFlowRate
    if design_water_flow_rate.is_initialized
      self.setDesignWaterFlowRate(design_water_flow_rate.get) 
    end

    design_air_flow_rate = self.autosizedDesignAirFlowRate
    if design_air_flow_rate.is_initialized
      self.setDesignAirFlowRate(design_air_flow_rate.get) 
    end    

    design_inlet_water_temperature = self.autosizedDesignInletWaterTemperature
    if design_inlet_water_temperature.is_initialized
      self.setDesignInletWaterTemperature(design_inlet_water_temperature.get) 
    end  
    
    design_inlet_air_temperature = self.autosizedDesignInletAirTemperature
    if design_inlet_air_temperature.is_initialized
      self.setDesignInletAirTemperature(design_inlet_air_temperature.get) 
    end  

    design_outlet_air_temperature = self.autosizedDesignOutletAirTemperature
    if design_outlet_air_temperature.is_initialized
      self.setDesignOutletAirTemperature(design_outlet_air_temperature.get) 
    end  
    
    design_inlet_air_humidity_ratio = self.autosizedDesignInletAirHumidityRatio
    if design_inlet_air_humidity_ratio.is_initialized
      self.setDesignInletAirHumidityRatio(design_inlet_air_humidity_ratio.get) 
    end      
    
    design_outlet_air_humidity_ratio = self.autosizedDesignOutletAirHumidityRatio
    if design_outlet_air_humidity_ratio.is_initialized
      self.setDesignOutletAirHumidityRatio(design_outlet_air_humidity_ratio.get) 
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
              AND TableName='Coil:Cooling:Water' 
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

  # returns the autosized design air flow rate as an optional double
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
              AND TableName='Coil:Cooling:Water' 
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
  
  # returns the autosized design inlet water temperature as an optional double
  def autosizedDesignInletWaterTemperature

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
              AND TableName='Coil:Cooling:Water' 
              AND RowName='#{name}' 
              AND ColumnName='Design Inlet Water Temperature' 
              AND Units='C'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized design inlet air temperatureas an optional double
  def autosizedDesignInletAirTemperature

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
              AND TableName='Coil:Cooling:Water' 
              AND RowName='#{name}' 
              AND ColumnName='Design Inlet Air Temperature' 
              AND Units='C'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized design outlet air temperature as an optional double
  def autosizedDesignOutletAirTemperature

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
              AND TableName='Coil:Cooling:Water' 
              AND RowName='#{name}' 
              AND ColumnName='Design Outlet Air Temperature' 
              AND Units='C'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized inlet air humidity ratio as an optional double
  def autosizedDesignInletAirHumidityRatio

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
              AND TableName='Coil:Cooling:Water' 
              AND RowName='#{name}' 
              AND ColumnName='Design Inlet Air Humidity Ratio'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized outlet air humidity ratio as an optional double
  def autosizedDesignOutletAirHumidityRatio

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
              AND TableName='Coil:Cooling:Water' 
              AND RowName='#{name}' 
              AND ColumnName='Design Outlet Air Humidity Ratio'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end


end
