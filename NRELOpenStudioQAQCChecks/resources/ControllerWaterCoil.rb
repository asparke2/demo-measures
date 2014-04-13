
# open the class to add methods to return sizing values
class OpenStudio::Model::ControllerWaterCoil

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    maximum_actuated_flow = self.autosizedMaximumActuatedFlow
    if maximum_actuated_flow.is_initialized
      self.setMaximumActuatedFlow(maximum_actuated_flow.get) 
    end

    controller_convergence_tolerance = self.autosizedControllerConvergenceTolerance
    if controller_convergence_tolerance.is_initialized
      self.setControllerConvergenceTolerance(controller_convergence_tolerance.get) 
    end
    
  end

  # returns the autosized maximum actuated flow rate as an optional double
  def autosizedMaximumActuatedFlow

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
              AND TableName='Controller:WaterCoil' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Actuated Flow' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized controller convergence tolerance as an optional double
  def autosizedControllerConvergenceTolerance

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
              AND TableName='Controller:WaterCoil' 
              AND RowName='#{name}' 
              AND ColumnName='Controller Convergence Tolerance'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  
end
