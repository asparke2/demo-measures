require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class SetCOPforTwoSpeedDXCoolingUnits_Test < Test::Unit::TestCase
  
  # def setup
  # end

  # def teardown
  # end
  
  def test_SetCOPforTwoSpeedDXCoolingUnits
     
    # create an instance of the measure
    measure = SetCOPforTwoSpeedDXCoolingUnits.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("cop_high", arguments[0].name)
    assert_equal("cop_low", arguments[1].name)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/0320_ModelWithHVAC_01.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    cop_high = arguments[0].clone
    assert(cop_high.setValue("2.0"))
    argument_map["cop_high"] = cop_high

    cop_low = arguments[1].clone
    assert(cop_low.setValue("4.0"))
    argument_map["cop_low"] = cop_low    
    
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 2)
    #assert(result.info.size == 1)
    
  end  

end
