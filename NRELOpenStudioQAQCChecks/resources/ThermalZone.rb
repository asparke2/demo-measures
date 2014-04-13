
# open the class to add methods to return sizing values
class OpenStudio::Model::ThermalZone

  # returns the autosized maximum loop flow rate as an optional double
  def areaPerOccupant

    result = OpenStudio::OptionalDouble.new()

    name = self.name.get.upcase
    
    model = self.model
    
    sql = model.sqlFile
    
    if sql.is_initialized
      sql = sql.get
    
      query = "SELECT Value 
              FROM tabulardatawithstrings 
              WHERE ReportName='InputVerificationandResultsSummary' 
              AND ReportForString='Entire Facility' 
              AND TableName='Zone Summary' 
              AND RowName='#{name}' 
              AND ColumnName='People'
              AND Units='m2 per person'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized maximum loop flow rate as an optional double
  def averageOutdoorAirACH

    result = OpenStudio::OptionalDouble.new()

    name = self.name.get.upcase
    
    model = self.model
    
    sql = model.sqlFile
    
    if sql.is_initialized
      sql = sql.get
    
      query = "SELECT Value 
              FROM tabulardatawithstrings 
              WHERE ReportName='OutdoorAirSummary' 
              AND ReportForString='Entire Facility' 
              AND TableName='Average Outdoor Air During Occupied Hours' 
              AND RowName='#{name}' 
              AND ColumnName='Mechanical Ventilation'
              AND Units='ach'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end

  # returns the autosized maximum loop flow rate as an optional double
  def volumeFromOACalc

    result = OpenStudio::OptionalDouble.new()

    name = self.name.get.upcase
    
    model = self.model
    
    sql = model.sqlFile
    
    if sql.is_initialized
      sql = sql.get
    
      query = "SELECT Value 
              FROM tabulardatawithstrings 
              WHERE ReportName='OutdoorAirSummary' 
              AND ReportForString='Entire Facility' 
              AND TableName='Average Outdoor Air During Occupied Hours' 
              AND RowName='#{name}' 
              AND ColumnName='Zone Volume'
              AND Units='m3'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end  
  
  
end
