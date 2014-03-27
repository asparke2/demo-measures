require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ImportRefrigerationCasesandWalkins_Test < Test::Unit::TestCase

  
  def test_ImportRefrigerationCasesandWalkins
     
    # create an instance of the measure
    measure = ImportRefrigerationCasesandWalkins.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    #load the model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/RefBldgSuperMarketNew2004.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(0, arguments.size)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    # set argument values to good values and run the measure on model with spaces
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")

    
  end  

end
