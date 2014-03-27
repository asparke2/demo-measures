#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class Replace32WT8Lampswith25WT8Lamps < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace 32W T8 Lamps with 25W T8 Lamps"
  end
  
  #define the arguments that the user will input
  def arguments(model)
   args = OpenStudio::Ruleset::OSArgumentVector.new 
        
    #make an argument for material and installation cost per lamp
    material_and_installation_cost_per_lamp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost_per_lamp",true)
    material_and_installation_cost_per_lamp.setDisplayName("Material and Installation Cost per Lamp.")
    material_and_installation_cost_per_lamp.setDefaultValue(0.0)
    args << material_and_installation_cost_per_lamp

    #make an argument for expected life of the lamp
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life of the New Lamps.")
    expected_life.setDefaultValue(25)
    args << expected_life    
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    material_and_installation_cost_per_lamp = runner.getDoubleArgumentValue("material_and_installation_cost_per_lamp",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)
    
    #hash of originnal to new light fixtures
    old_lts_def_new_lts_def = {}
    lamps_replaced_per_fixture = {}
    
    #low wattage T8 wattage
    new_lamp_wattage = 25
    
    #first get all of the T8 light fixture defintions in the model
    model.getLightsDefinitions.each do |original_lights_def|
      #(1) 32.0W T8 Linear Fluorescent (1) 0.88BF Fluorescent Electronic Non-Dimming
      name = original_lights_def.name.get
      runner.registerInfo("Checking = #{name}")
      
      #get the fixture properties from the fixture name
      lamp_type = name.scan(/[\d\.]+W (\w+)/)[0][0]
      runner.registerInfo("lamp_type = #{lamp_type}")
      next unless lamp_type == "T8" #only looking for T8 fixtures
      
      lamp_wattage = name.match(/([\d\.]+)W/)[0].to_f
      runner.registerInfo("lamp_wattage = #{lamp_wattage}")
      next unless lamp_wattage == 32.0 #only looking to replace 32W T8s
      
      num_lamps = name.scan(/\((\d+)\)/)[0][0].to_f
      runner.registerInfo("num_lamps = #{num_lamps}")

      num_ballasts = name.scan(/\((\d+)\)/)[1][0].to_f
      runner.registerInfo("num_ballasts = #{num_ballasts}")

      ballast_factor = name.match(/([\d\.]+)BF/)[0].to_f
      runner.registerInfo("ballast_factor = #{ballast_factor}")

      #calculate the wattage of the fixture with lower wattage lamps
      new_total_wattage = num_lamps * new_lamp_wattage * ballast_factor
      
      #rename the fixture with new low wattage lamps, pattern:
      #(2) 40W A19 Standard Incandescent (1) 0.8BF HID Electronic Ballast
      new_name = "(#{num_lamps}) #{new_lamp_wattage}W T8 Linear Fluorescent (#{num_ballasts}) #{ballast_factor}BF"

      #make the new lights definition to replace the old one
      new_lights_def = OpenStudio::Model::LightsDefinition.new(model)
      new_lights_def.setName(new_name)
      new_lights_def.setLightingLevel(new_total_wattage)
 
      #add costs to the new fixture
      if material_and_installation_cost_per_lamp != 0
        cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Replace #{num_lamps} 32W T8 lamps with #{new_lamp_wattage}W T8 lamps in #{name}", new_lights_def, num_lamps * material_and_installation_cost_per_lamp, "CostPerEach", "Construction", expected_life, 0)
        if cost.empty?
          runner.registerError("Failed to add costs.")
        end
      end 
 
      #register the old and new fixture
      old_lts_def_new_lts_def[original_lights_def] = new_lights_def
      lamps_replaced_per_fixture[original_lights_def] = num_lamps
      
    end
    
    #replace all 32W T8 fixtures with their clones with 25W Lamps
    number_of_fixtures_replaced = 0
    number_of_lamps_replaced = 0
    model.getLightss.each do |light_fixture|
      if old_lts_def_new_lts_def[light_fixture.lightsDefinition]
        #log the  fixture name
        original_fixture_name = light_fixture.lightsDefinition.name
        #get the replacement light fixture definition
        new_lights_def = old_lts_def_new_lts_def[light_fixture.lightsDefinition]
        lamps_per_fixture = lamps_replaced_per_fixture[light_fixture.lightsDefinition]
        #replace the existing light fixture with the new one and log the replacement
        light_fixture.setLightsDefinition(new_lights_def)
        number_of_fixtures_replaced += light_fixture.multiplier
        number_of_lamps_replaced += light_fixture.multiplier * lamps_per_fixture
        runner.registerInfo("Replaced #{(light_fixture.multiplier * lamps_per_fixture).round} lamps in #{light_fixture.multiplier.round} #{original_fixture_name} fixtures.")
      end
    end
    
    #report if the measure is not applicable (no 32W T8 fixtures)
    if number_of_fixtures_replaced == 0
      runner.registerAsNotApplicable("This measure is not applicable, because this building has no 32W T8 fixtures.")
      return true
    end
     
    #report initial condition
    runner.registerInitialCondition("The building has approximately #{number_of_fixtures_replaced.round} light fixtures with standard 32W T8 linear fluorescent lamps.") 

    #report final condition
    runner.registerFinalCondition("Replace #{number_of_lamps_replaced.round} 32W T8 lamps in  #{number_of_fixtures_replaced.round} light fixtures throughout the building with #{new_lamp_wattage}W low-wattage T8 lamps.  The total cost to replace the lamps is $#{material_and_installation_cost_per_lamp.round} per lamp, for a total cost of $#{(material_and_installation_cost_per_lamp * number_of_lamps_replaced).round}")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
Replace32WT8Lampswith25WT8Lamps.new.registerWithApplication