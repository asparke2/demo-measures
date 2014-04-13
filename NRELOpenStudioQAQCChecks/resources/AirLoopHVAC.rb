
# open the class to add methods to return sizing values
class OpenStudio::Model::AirLoopHVAC

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    design_supply_air_flow_rate = self.autosizedDesignSupplyAirFlowRate
    if design_supply_air_flow_rate.is_initialized
      self.setDesignSupplyAirFlowRate(design_supply_air_flow_rate.get) 
    end
        
  end

  # returns the autosized design supply air flow rate as an optional double
  def autosizedDesignSupplyAirFlowRate

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
              AND TableName='AirLoopHVAC' 
              AND RowName='#{name}' 
              AND ColumnName='Design Supply Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  
end
