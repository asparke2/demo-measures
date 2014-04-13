
# open the class to add methods to return sizing values
class OpenStudio::Model::SizingSystem

  # Takes the values calculated by the EnergyPlus sizing routines
  # and puts them into this object model in place of the autosized fields.
  # Must have previously completed a run with sql output for this to work.
  def applySizingValues

    # In OpenStudio, the design OA flow rates are calculated by the
    # controller:outdoorair object associated with this system.
    # Therefore, this property will be retrieved from that object's sizing values
    air_loop = self.airLoopHVAC
    air_loop.supplyComponents.each do |supply_comp|
      if supply_comp.to_AirLoopHVACOutdoorAirSystem.is_initialized
        controller_oa = supply_comp.to_AirLoopHVACOutdoorAirSystem.get.getControllerOutdoorAir
        # get the max oa flow rate from the controller:outdoor air sizing
        maximum_outdoor_air_flow_rate = controller_oa.autosizedMaximumOutdoorAirFlowRate
        if maximum_outdoor_air_flow_rate.is_initialized
          self.setMaximumOutdoorAirFlowRate(maximum_outdoor_air_flow_rate.get) 
        end
      end
    end
    
  end

  # returns the autosized maximum outdoor air flow rate as an optional double
  def autosizedMaximumOutdoorAirFlowRate

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
              AND TableName='Controller:OutdoorAir' 
              AND RowName='#{name}' 
              AND ColumnName='Maximum Outdoor Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  # returns the autosized minimum outdoor air flow rate as an optional double
  def autosizedMinimumOutdoorAirFlowRate

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
              AND TableName='Controller:OutdoorAir' 
              AND RowName='#{name}' 
              AND ColumnName='Minimum Outdoor Air Flow Rate' 
              AND Units='m3/s'"
              
      val = sql.execAndReturnFirstDouble(query)
      
      if val.is_initialized
        result = OpenStudio::OptionalDouble.new(val.get)
      end
 
    end

    return result
    
  end
  
  
end
