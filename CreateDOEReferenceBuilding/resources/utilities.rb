
#load a model into OS & version translates, exiting and erroring if a problem is found
def safe_load_model(model_path_string)  
  model_path = OpenStudio::Path.new(model_path_string)
  if OpenStudio::exists(model_path)
    versionTranslator = OpenStudio::OSVersion::VersionTranslator.new 
    model = versionTranslator.loadModel(model_path)
    if model.empty?
      @runner.registerError("Version translation failed for #{model_path_string}")
      return false
    else
      model = model.get
    end
  else
    @runner.registerError("#{model_path_string} couldn't be found")
    return false
  end
  return model
end

#load a sql file, exiting and erroring if a problem is found
def safe_load_sql(sql_path_string)
  sql_path = OpenStudio::Path.new(sql_path_string)
  if OpenStudio::exists(sql_path)
    sql = OpenStudio::SqlFile.new(sql_path)
  else 
    @runner.registerError("#{sql_path} couldn't be found")
    exit
  end
  return sql
end

def strip_model(model)


  #remove all materials
  model.getMaterials.each do |mat|
    mat.remove
  end

  #remove all constructions
  model.getConstructions.each do |constr|
    constr.remove
  end

  #remove performance curves
  model.getCurves.each do |curve|
    curve.remove
  end

  #remove all zone equipment
  model.getThermalZones.each do |zone|
    zone.equipment.each do |equip|
      equip.remove
    end
  end
    
  #remove all thermostats
  model.getThermostatSetpointDualSetpoints.each do |tstat|
    tstat.remove
  end

  #remove all people
  model.getPeoples.each do |people|
    people.remove
  end
  model.getPeopleDefinitions.each do |people_def|
    people_def.remove
  end

  #remove all lights
#model.getLights.each do |lights|
 #   lights.remove
 # end
 # model.getLightDefinitions.each do |lights_def|
 #   lights_def.remove
 # end

  #remove all electric equipment
  model.getElectricEquipments.each do |equip|
    equip.remove
  end
  model.getElectricEquipmentDefinitions.each do |equip_def|
    equip_def.remove
  end

  #remove all gas equipment
  model.getGasEquipments.each do |equip|
    equip.remove
  end
  model.getGasEquipmentDefinitions.each do |equip_def|
    equip_def.remove
  end

  #remove all outdoor air
  model.getDesignSpecificationOutdoorAirs.each do |oa_spec|
    oa_spec.remove
  end

  #remove all infiltration
  model.getSpaceInfiltrationDesignFlowRates.each do |infil|
    infil.remove
  end


  return model


end

