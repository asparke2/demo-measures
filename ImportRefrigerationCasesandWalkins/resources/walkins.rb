
def create_walkin(col, model)
  
  #key to map column names to values
  name_row = 0
  availability_schedule_name_row = 1
  rated_coil_cooling_capacity_row = 2
  operating_temperature_row = 3
  rated_cooling_source_temperature_row = 4
  rated_total_heating_power_row = 5
  heating_power_schedule_name_row = 6
  rated_cooling_coil_fan_power_row = 7
  rated_circulation_fan_power_row = 8
  rated_total_lighting_power_row = 9
  lighting_schedule_name_row = 10
  defrost_type_row = 11
  defrost_control_type_row = 12
  defrost_schedule_name_row = 13
  defrost_drip_down_schedule_name_row = 14
  defrost_power_row = 15
  temperature_termination_defrost_fraction_to_ice_row = 16
  restocking_schedule_name_row = 17
  average_refrigerant_charge_inventory_row = 18
  insulated_floor_surface_area_row = 19
  insulated_floor_u_value_row = 20
  zone_1_name_row = 21
  total_insulated_surface_area_facing_zone_1_row = 22
  insulated_surface_u_value_facing_zone_1_row = 23
	area_of_glass_reach_in_doors_facing_zone_1_row = 24
	height_of_glass_reach_in_doors_facing_zone_1_row = 25
	glass_reach_in_door_u_value_facing_zone_1_row = 26
	glass_reach_in_door_opening_schedule_name_facing_zone_1_row = 27
	area_of_stocking_doors_facing_zone_1_row = 28
	height_of_stocking_doors_facing_zone_1_row = 29
	stocking_door_u_value_facing_zone_1_row = 20
	stocking_door_opening_schedule_name_facing_zone_1_row = 31
	stocking_door_opening_protection_type_facing_zone_1_row = 32
   
  #find the defrost schedule for the walkin
  def_sch_name = col[defrost_schedule_name_row]
  def_sch = model.getScheduleCompactByName(def_sch_name)
  if def_sch.is_initialized
    def_sch = def_sch.get
  else
    @runner.registerError("could not find def sch #{def_sch_name} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end

  #create the walkin (a defrost sch is required by the constructor)
  walkin = OpenStudio::Model::RefrigerationWalkIn.new(model, def_sch)
  
  #name
  walkin.setName(col[name_row])
  
  #availability schedule for the walkin
  avail_sch_name = col[availability_schedule_name_row]
  avail_sch = model.getScheduleCompactByName(avail_sch_name)
  if avail_sch.is_initialized
    avail_sch = avail_sch.get
  else
    @runner.registerError("could not find avail sch #{avail_sch_name} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  walkin.setAvailabilitySchedule(avail_sch)
  
  #walkin properties
  walkin.setRatedCoilCoolingCapacity(col[rated_coil_cooling_capacity_row])
  walkin.setOperatingTemperature(col[operating_temperature_row])
  walkin.setRatedCoolingSourceTemperature(col[rated_cooling_source_temperature_row])
  walkin.setRatedTotalHeatingPower(col[rated_total_heating_power_row])
  
  #heating schedule for the walkin
  heating_sch_name = col[heating_power_schedule_name_row]
  heating_sch = model.getScheduleCompactByName(heating_sch_name)
  if heating_sch.is_initialized
    heating_sch = heating_sch.get
  else
    @runner.registerError("could not find heating sch #{curve} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  walkin.setHeatingPowerSchedule(heating_sch)         
  
  #walkin properties
  walkin.setRatedCoolingCoilFanPower(col[rated_cooling_coil_fan_power_row])
  walkin.setRatedCirculationFanPower(col[rated_circulation_fan_power_row])
  walkin.setRatedTotalLightingPower(col[rated_total_lighting_power_row])
  
  #lighting schedule for the walkin
  lighting_sch_name = col[lighting_schedule_name_row]
  lighting_sch = model.getScheduleCompactByName(lighting_sch_name)
  if lighting_sch.is_initialized
    lighting_sch = lighting_sch.get
  else
    @runner.registerError("could not find lighting sch #{lighting_sch_name} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  walkin.setLightingSchedule(lighting_sch)       

  #walkin properties
  walkin.setDefrostType(col[defrost_type_row])
  walkin.setDefrostControlType(col[defrost_control_type_row])
  
  #dripdown schedule for the walkin
  dripdown_sch_name = col[defrost_drip_down_schedule_name_row]
  dripdown_sch = model.getScheduleCompactByName(dripdown_sch_name)
  if dripdown_sch.is_initialized
    dripdown_sch = dripdown_sch.get
  else
    @runner.registerError("could not find dripdown sch #{dripdown_sch_name} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  walkin.setDefrostDripDownSchedule(dripdown_sch)

  #walkin properties
  walkin.setDefrostPower(col[defrost_power_row])
  walkin.setTemperatureTerminationDefrostFractiontoIce(col[temperature_termination_defrost_fraction_to_ice_row])
  
  #restocking schedule for the walkin
  restocking_sch_name = col[restocking_schedule_name_row]
  restocking_sch = model.getScheduleCompactByName(restocking_sch_name)
  if restocking_sch.is_initialized
    restocking_sch = restocking_sch.get
  else
    @runner.registerError("could not find restocking sch #{restocking_sch_name} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  walkin.setRestockingSchedule(restocking_sch)   
  
  #walkin properties
  #walkin.setAverageRefrigerantChargeInventory(col[average_refrigerant_charge_inventory_row])
  walkin.setInsulatedFloorSurfaceArea(col[insulated_floor_surface_area_row])
  walkin.setInsulatedFloorUValue(col[insulated_floor_u_value_row])
  
  #create a zone boundary
  zn_boundary = OpenStudio::Model::RefrigerationWalkInZoneBoundary.new(model)
  
  #zone the walkin is in
  zone_name = col[zone_1_name_row]
  zone = model.getThermalZoneByName(zone_name)
  if zone.is_initialized
    zone = zone.get
  else
    @runner.registerError("could not find zone #{zone_name} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end 
  zn_boundary.setThermalZone(zone)
  
  #zone boundary properties  
  zn_boundary.setTotalInsulatedSurfaceAreaFacingZone(col[insulated_surface_u_value_facing_zone_1_row])
  zn_boundary.setInsulatedSurfaceUValueFacingZone(col[area_of_glass_reach_in_doors_facing_zone_1_row])
  zn_boundary.setAreaofGlassReachInDoorsFacingZone(col[area_of_glass_reach_in_doors_facing_zone_1_row])
  zn_boundary.setHeightofGlassReachInDoorsFacingZone(col[height_of_glass_reach_in_doors_facing_zone_1_row])
  zn_boundary.setGlassReachInDoorUValueFacingZone(col[glass_reach_in_door_u_value_facing_zone_1_row])
   
  #door opening schedule for the walkin
  door_open_sch_name = col[glass_reach_in_door_opening_schedule_name_facing_zone_1_row]
  door_open_sch = model.getScheduleCompactByName(door_open_sch_name)
  if door_open_sch.is_initialized
    door_open_sch = door_open_sch.get
  else
    @runner.registerError("could not find door open sch #{door_open_sch} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  walkin.setRestockingSchedule(door_open_sch)   
  zn_boundary.setGlassReachInDoorOpeningScheduleFacingZone(door_open_sch)
  
  #zone boundary properties
  zn_boundary.setAreaofStockingDoorsFacingZone(col[area_of_stocking_doors_facing_zone_1_row])
  zn_boundary.setHeightofStockingDoorsFacingZone(col[height_of_stocking_doors_facing_zone_1_row])
  zn_boundary.setStockingDoorUValueFacingZone(col[stocking_door_u_value_facing_zone_1_row])

  #glass door opening schedule for the walkin
  glass_door_open_sch_name = col[glass_reach_in_door_opening_schedule_name_facing_zone_1_row]
  glass_door_open_sch = model.getScheduleCompactByName(glass_door_open_sch_name)
  if glass_door_open_sch.is_initialized
    glass_door_open_sch = glass_door_open_sch.get
  else
    @runner.registerError("could not find door open sch #{glass_door_open_sch} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  zn_boundary.setGlassReachInDoorOpeningScheduleFacingZone(glass_door_open_sch)   

  #stock door opening schedule for the walkin
  stock_door_open_sch_name = col[glass_reach_in_door_opening_schedule_name_facing_zone_1_row]
  stock_door_open_sch = model.getScheduleCompactByName(stock_door_open_sch_name)
  if stock_door_open_sch.is_initialized
    stock_door_open_sch = stock_door_open_sch.get
  else
    @runner.registerError("could not find door open sch #{stock_door_open_sch} for walkin #{col[name_row]}, cannot create walkin")
    return false
  end      
  zn_boundary.setStockingDoorOpeningScheduleFacingZone(stock_door_open_sch)
  
  #zone boundary properties
  zn_boundary.setStockingDoorOpeningProtectionTypeFacingZone(col[stocking_door_opening_protection_type_facing_zone_1_row])
 
  #inform the user
  @runner.registerInfo("Created walkin #{col[name_row]}}")

  return walkin
  
end    