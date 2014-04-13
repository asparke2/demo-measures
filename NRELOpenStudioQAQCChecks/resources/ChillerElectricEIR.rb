
# open the class to add methods to return sizing values
class OpenStudio::Model::ChillerElectricEIR

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    reference_chilled_water_flow_rate = self.autosizedReferenceChilledWaterFlowRate
    if reference_chilled_water_flow_rate.is_initialized
      self.setReferenceChilledWaterFlowRate(reference_chilled_water_flow_rate.get) 
    end

    reference_capacity = self.autosizedReferenceCapacity
    if reference_capacity.is_initialized
      self.setReferenceCapacity(reference_capacity.get) 
    end

    reference_condenser_fluid_flow_rate = self.autosizedReferenceCondenserFluidFlowRate
    if reference_condenser_fluid_flow_rate.is_initialized
      self.setReferenceCondenserFluidFlowRate(reference_condenser_fluid_flow_rate.get) 
    end
    
  end

  # returns the autosized chilled water flow rate as an optional double
  def autosizedReferenceChilledWaterFlowRate

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
              AND TableName='Chiller:Electric:EIR' 
              AND RowName='#{name}' 
              AND ColumnName='Reference Chilled Water Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized reference capacity as an optional double
  def autosizedReferenceCapacity

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
              AND TableName='Chiller:Electric:EIR' 
              AND RowName='#{name}' 
              AND ColumnName='Reference Capacity'
              AND Units='W'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized reference condenser fluid flow rate as an optional double
  def autosizedReferenceCondenserFluidFlowRate

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
              AND TableName='Chiller:Electric:EIR' 
              AND RowName='#{name}' 
              AND ColumnName='Reference Condenser Water Flow Rate'
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  
end
