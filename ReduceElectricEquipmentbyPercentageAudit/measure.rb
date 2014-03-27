#start the measure
class ReduceElectricEquipmentByPercentageAudit < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Reduce Electric Equipment by Percentage Audit"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    equip_def_handles = OpenStudio::StringVector.new
    equip_def_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    equip_def_hash = {}
    
    building = model.getBuilding
    equip_def_display_names << "*All Equipment*"
    equip_def_handles << building.handle.to_s

    model.getLightsDefinitions.each do |equip_def|
      equip_def_display_names << equip_def.name.to_s
      equip_def_handles << equip_def.handle.to_s
    end
    
    model.getElectricEquipmentDefinitions.each do |equip_def|
      equip_def_display_names << equip_def.name.to_s
      equip_def_handles << equip_def.handle.to_s
    end
    
    #make a choice argument for space type
    equip_def = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("equip_def", equip_def_handles, equip_def_display_names)
    equip_def.setDisplayName("Apply the Measure to a Equipment Definition or to All Equipment in the model.")
    equip_def.setDefaultValue("*All Equipment*") 
    args << equip_def

    #make an argument for reduction percentage
    equip_power_reduction_percent = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("equip_power_reduction_percent",true)
    equip_power_reduction_percent.setDisplayName("Equipment Power Reduction (%).")
    equip_power_reduction_percent.setDefaultValue(30.0)
    args << equip_power_reduction_percent

    #make an argument for material and installation cost
    material_and_installation_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost",true)
    material_and_installation_cost.setDisplayName("Building Level Increase in Material and Installation Cost.")
    material_and_installation_cost.setDefaultValue(0.0)
    args << material_and_installation_cost

    #make an argument for expected life
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life (whole years).")
    expected_life.setDefaultValue(100)
    args << expected_life

    #make an argument for O & M cost
    om_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost",true)
    om_cost.setDisplayName("Building Level Increase in O & M Costs.")
    om_cost.setDefaultValue(0.0)
    args << om_cost

    #make an argument for O & M frequency
    om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency",true)
    om_frequency.setDisplayName("O & M Frequency (whole years).")
    om_frequency.setDefaultValue(1)
    args << om_frequency

    return args
  end #end the arguments method
  
  def reduceEquipmentDefinition(equip_def, percent)
    multiplier = 1.0 - (percent / 100.0)
    if not equip_def.designLevel.empty?
      designLevel = equip_def.designLevel.get * multiplier
      equip_def.setDesignLevel(designLevel)
    end
    if not equip_def.wattsperSpaceFloorArea.empty?
      wattsperSpaceFloorArea = equip_def.wattsperSpaceFloorArea.get * multiplier
      equip_def.setWattsperSpaceFloorArea(wattsperSpaceFloorArea)
    end
    if not equip_def.wattsperPerson.empty?
      wattsperPerson = equip_def.wattsperPerson.get * multiplier
      equip_def.setWattsperPerson(wattsperPerson)
    end
  end
  
  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue("equip_def",user_arguments,model)
    equip_power_reduction_percent = runner.getDoubleArgumentValue("equip_power_reduction_percent",user_arguments)
    material_and_installation_cost = runner.getDoubleArgumentValue("material_and_installation_cost",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)
    om_cost = runner.getDoubleArgumentValue("om_cost",user_arguments)
    om_frequency = runner.getIntegerArgumentValue("om_frequency",user_arguments)

    #check the equip_def for reasonableness and see if measure should run on just equip_def or on the entire building
    apply_to_building = false
    equip_def = nil
    if object.empty?
      handle = runner.getStringArgumentValue("equip_def",user_arguments)
      if handle.empty?
        runner.registerError("No equipment definition was chosen.")
      else
        runner.registerError("The selected equipment definition with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_ElectricEquipmentDefinition.empty?
        equip_def = object.get.to_ElectricEquipmentDefinition.get
      elsif not object.get.to_Building.empty?
        apply_to_building = true
      else
        runner.registerError("Script Error - argument not showing up as equipment definition or building.")
        return false
      end
    end
    object = object.get

    #check the equip_power_reduction_percent and for reasonableness
    if equip_power_reduction_percent > 100
      runner.registerError("Please Enter a Value less than or equal to 100 for the Equipment Power Reduction Percentage.")
      return false
    elsif equip_power_reduction_percent == 0
      runner.registerInfo("No equipment power adjustment requested, but some life cycle costs may still be affected.")
    elsif equip_power_reduction_percent < 1 and equip_power_reduction_percent > -1
      runner.registerWarning("An Equipment Power Reduction Percentage of #{equip_power_reduction_percent} percent is abnormally low.")
    elsif equip_power_reduction_percent > 90
      runner.registerWarning("An Equipment Power Reduction Percentage of #{equip_power_reduction_percent} percent is abnormally high.")
    elsif equip_power_reduction_percent < 0
      runner.registerInfo("The requested value for equipment power reduction percentage was negative. This will result in an increase in equipment power.")
    end

   #check lifecycle cost arguments for reasonableness
    if material_and_installation_cost < -100
      runner.registerError("Material and Installation Cost percentage increase can't be less than -100.")
      return false
    end

    if expected_life < 1
      runner.registerError("Enter an integer greater than or equal to 1 for Expected Life.")
      return false
    end

    if om_cost < -100
      runner.registerError("O & M Cost percentage increase can't be less than -100.")
      return false
    end

    if om_frequency < 1
      runner.registerError("Choose an integer greater than 0 for O & M Frequency.")
    end
    
    #helper to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure.
    def neat_numbers(number, roundto = 2) #round to 0 or 2)
      if roundto == 2
        number = sprintf "%.2f", number
      else
        number = number.round
      end
      #regex to add commas
      number.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1,").reverse
    end #end def neat_numbers
    
    #report initial condition
    building = model.getBuilding
    building_equip_power = building.electricEquipmentPower
    building_EPD = OpenStudio::convert(building.electricEquipmentPowerPerFloorArea,"W/m^2","W/ft^2")
    runner.registerInitialCondition("The model's initial building lighting power was  #{neat_numbers(building_equip_power,0)} watts, an equipment power density of #{neat_numbers(building_EPD)} W/ft^2.")

    #apply to equipment in model
    if apply_to_building
      model.getElectricEquipmentDefinitions.each do |equip_def|
        reduceEquipmentDefinition(equip_def, equip_power_reduction_percent)
      end
    elsif equip_def
      reduceEquipmentDefinition(equip_def, equip_power_reduction_percent)
    end
    
    # add costs
    if material_and_installation_cost != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("#{object.name.to_s} Equipment Reduction", building, material_and_installation_cost, "CostPerEach", "Construction", expected_life, 0)
      if cost.empty?
        runner.registerError("Failed to add construction costs.")
      end
    end
    
    if om_cost != 0
      cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("#{object.name.to_s} Equipment Maintenance", building, om_cost, "CostPerEach", "Maintenance", om_frequency, om_frequency)
      if cost.empty?
        runner.registerError("Failed to add maintenance costs.")
      end
    end

    #report final condition
    final_building = model.getBuilding
    final_building_equip_power = final_building.electricEquipmentPower
    final_building_EPD = OpenStudio::convert(final_building.electricEquipmentPowerPerFloorArea,"W/m^2","W/ft^2")
    runner.registerFinalCondition("The model's final equipment power was  #{neat_numbers(final_building_equip_power,0)} watts, a lighting power density of #{neat_numbers(final_building_EPD)} W/ft^2. Initial capital costs associated with the improvements are $#{material_and_installation_cost}.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
ReduceElectricEquipmentByPercentageAudit.new.registerWithApplication