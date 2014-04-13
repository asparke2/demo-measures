
# open the class to add methods to return sizing values
class OpenStudio::Model::AirTerminalSingleDuctUncontrolled

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    maximum_air_flow_rate = self.autosizedMaximumAirFlowRate
    if maximum_air_flow_rate.is_initialized
      self.setMaximumAirFlowRate(maximum_air_flow_rate.get) 
    end
        
  end
 
  # returns the autosized maximum air flow rate as optional double
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
              AND TableName='AirTerminal:SingleDuct:Uncontrolled' 
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
  
  
end
