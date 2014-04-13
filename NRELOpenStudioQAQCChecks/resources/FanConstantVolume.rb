
# open the class to add methods to return sizing values
class OpenStudio::Model::FanConstantVolume

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    maximum_flow_rate = self.autosizedMaximumFlowRate
    if maximum_flow_rate.is_initialized
      self.setMaximumFlowRate(maximum_flow_rate.get)
    end

  end
  
  # returns the autosized maximum flow rate as an optional double
  def autosizedMaximumFlowRate

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
              AND TableName='Fan:ConstantVolume' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end

    end

    return result
    
  end

end
