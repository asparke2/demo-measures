require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ConstantSpeedtoVariableSpeedPump_Test < Test::Unit::TestCase

  
  def test_ConstantSpeedtoVariableSpeedPump
     
    # create an instance of the measure
    measure = ConstantSpeedtoVariableSpeedPump.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # load test model
    osm = OpenStudio::Path.new(File.dirname(__FILE__) + "/HVACTest.osm")
    vt = OpenStudio::OSVersion::VersionTranslator.new
    model = vt.loadModel(osm).get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)
    assert_equal("object", arguments[0].name)
    assert((arguments[0].hasDefaultValue))
    assert_equal(3, arguments[0].choiceValues.size)
    assert_equal("remove_costs", arguments[1].name)
    assert((arguments[1].hasDefaultValue))
    assert_equal("material_cost", arguments[2].name)
    assert((arguments[2].hasDefaultValue))
    
    # count air loops
    initial_constantspeed_plantloops = 0
    initial_variablespeed_plantloops = 0
    model.getPlantLoops.each do |plant_loop|
      plant_loop.supplyComponents.each do |supply_comp|
        if supply_comp.to_PumpConstantSpeed.is_initialized
          initial_constantspeed_plantloops += 1
        elsif supply_comp.to_PumpVariableSpeed.is_initialized
          initial_variablespeed_plantloops += 1
        end
      end 
    end 
    assert_equal(2, initial_constantspeed_plantloops)
    assert_equal(0, initial_variablespeed_plantloops)
    
    # set argument values to default values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::convertOSArgumentVectorToMap(arguments)
    material_cost = arguments[2].clone
    assert(material_cost.setValue(100.0))
    argument_map["material_cost"] = material_cost
    
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal("Success", result.value.valueName)
    assert_equal(0, result.warnings.size)
    assert_equal(2, result.info.size)
    
    # count air loops
    final_constantspeed_plantloops = 0
    final_variablespeed_plantloops = 0
    model.getPlantLoops.each do |plant_loop|
      plant_loop.supplyComponents.each do |supply_comp|
        if supply_comp.to_PumpConstantSpeed.is_initialized
          final_constantspeed_plantloops += 1
        elsif supply_comp.to_PumpVariableSpeed.is_initialized
          final_variablespeed_plantloops += 1
        end
      end 
    end 
    assert_equal(0, final_constantspeed_plantloops)
    assert_equal(2, final_variablespeed_plantloops)
    
    model.save(OpenStudio::Path.new("out.osm"), true)
    
  end  

end
