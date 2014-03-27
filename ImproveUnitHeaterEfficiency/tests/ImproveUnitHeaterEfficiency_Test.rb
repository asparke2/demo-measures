require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ImproveUnitHeaterEfficiency_Test < Test::Unit::TestCase
  
  def test_ImproveUnitHeaterEfficiency
     
    # create an instance of the measure
    measure = ImproveUnitHeaterEfficiency.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal("heater_eff", arguments[0].name)
    
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/0320_ModelWithHVAC_01.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    
    heater_eff = arguments[0].clone
    assert(heater_eff.setValue(95.0))
    argument_map["heater_eff"] = heater_eff
    
    model.getCoilHeatingGass.each do |coilHeatingGas|
      coilHeatingGas.setGasBurnerEfficiency(0.8)
      assert_equal(0.80, coilHeatingGas.gasBurnerEfficiency)
    end
    
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 2)
    #assert(result.info.size == 1)
    
    coilHeatingGass = model.getCoilHeatingGass
    assert((not coilHeatingGass.empty?))
    coilHeatingGass.each do |coilHeatingGas|
      assert_equal(0.95, coilHeatingGas.gasBurnerEfficiency)
    end
    
  end

end
