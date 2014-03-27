require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ImproveFanDriveEfficiency_Test < Test::Unit::TestCase
  
  def test_ImproveFanDriveEfficiency
     
    # create an instance of the measure
    measure = ImproveFanDriveEfficiency.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/0320_ModelWithHVAC_01.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal("object", arguments[0].name)
    assert((arguments[0].hasDefaultValue))
    #assert_equal(4, arguments[0].choiceValues.size)
    assert_equal("fan_type", arguments[1].name)
    assert((arguments[1].hasDefaultValue))
    assert_equal("belt_type", arguments[2].name)
    assert((arguments[2].hasDefaultValue))
    assert_equal("motor_eff", arguments[3].name)
    assert_equal("cost", arguments[4].name)
    assert((arguments[4].hasDefaultValue))
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::convertOSArgumentVectorToMap(arguments)

    object = arguments[0].clone
    assert(object.setValue("*All Air Loops*"))
    argument_map["object"] = object
    
    motor_eff = arguments[3].clone
    assert(motor_eff.setValue(95.0))
    argument_map["motor_eff"] = motor_eff
    
    model.getFanConstantVolumes.each do |fanConstantVolume|
      fanConstantVolume.setMotorEfficiency(0.8)
      assert_equal(0.80, fanConstantVolume.motorEfficiency)
    end
    
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 2)
    #assert(result.info.size == 1)
    
    fanConstantVolumes = []
    model.getAirLoopHVACs.each do |air_loop|
      air_loop.supplyComponents.each do |supply_comp|
        if supply_comp.to_FanConstantVolume.is_initialized
          fanConstantVolumes << supply_comp.to_FanConstantVolume.get
        end
      end
    end
    
    assert((not fanConstantVolumes.empty?))
    assert_equal(1, fanConstantVolumes.size)
    fanConstantVolumes.each do |fanConstantVolume|
      assert_equal(0.95, fanConstantVolume.motorEfficiency)
    end
    
  end

end
