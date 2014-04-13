
# open the class to add methods to return sizing values
class OpenStudio::Model::CoilHeatingElectric

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    nominal_capacity = self.autosizedNominalCapacity
    if nominal_capacity.is_initialized
      self.setNominalCapacity(nominal_capacity.get) 
    end
        
  end
 
  # returns the autosized rated capacity as an optional double
  def autosizedNominalCapacity

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
              AND TableName='Coil:Heating:Electric' 
              AND RowName='#{name}' 
              AND ColumnName='Nominal Capacity' 
              AND Units='W'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
    
    end

    return result
    
  end  
  
  
end
