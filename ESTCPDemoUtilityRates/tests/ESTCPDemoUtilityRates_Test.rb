require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ESTCPDemoUtilityRates_Test < Test::Unit::TestCase
  
  # def setup
  # end

  # def teardown
  # end
  
  def test_ESTCPDemoUtilityRates
     
    # create an instance of the measure
    measure = ESTCPDemoUtilityRates.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(2, arguments.size)
    assert_equal("elec_tar", arguments[0].name)
    assert_equal("gas_tar", arguments[1].name)

    # set argument values to good values and run the measure on the workspace
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    elec_tar = arguments[0].clone
    assert(elec_tar.setValue("AFA_Electricity"))
    argument_map["elec_tar"] = elec_tar
    gas_tar = arguments[1].clone
    assert(gas_tar.setValue("AFA_Gas"))
    argument_map["gas_tar"] = gas_tar
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0)
    assert(result.info.size == 15)

  end

end