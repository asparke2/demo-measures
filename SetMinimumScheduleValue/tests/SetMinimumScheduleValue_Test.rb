######################################################################
#  Copyright (c) 2008-2013, Alliance for Sustainable Energy.  
#  All rights reserved.
#  
#  This library is free software you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation either
#  version 2.1 of the License, or (at your option) any later version.
#  
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
######################################################################

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ReduceNightTimeElectricEquipmentLoads_Test < Test::Unit::TestCase

  def test_SetMinimumScheduleValue
     
    # create an instance of the measure
    measure = SetMinimumScheduleValue.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("schedule", arguments[0].name)
    assert_equal("minimum_fraction", arguments[1].name)
    
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    schedule = arguments[0].clone
    assert(schedule.setValue("LargeHotel_Infil_Quarter_On"))
    argument_map["schedule"] = schedule
    minimum_fraction = arguments[1].clone
    assert(minimum_fraction.setValue(0.6))
    argument_map["minimum_fraction"] = minimum_fraction
    
    found_schedule = false
    model.getScheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "LargeHotel_Infil_Quarter_On"
        found_schedule = true
        scheduleRules = scheduleRuleset.scheduleRules
        assert(scheduleRules.length == 1)
        scheduleRules.each do |scheduleRule|
          daySchedule = scheduleRule.daySchedule
          values = daySchedule.values
          assert(values.length == 1)
          assert_equal(0.25, values[0])
        end
      end
    end
    assert(found_schedule)

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0)
    assert(result.info.size == 0)
    
    found_schedule = false
    model.getScheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "LargeHotel_Infil_Quarter_On"
        found_schedule = true
        scheduleRules = scheduleRuleset.scheduleRules
        assert(scheduleRules.length == 1)
        scheduleRules.each do |scheduleRule|
          daySchedule = scheduleRule.daySchedule
          values = daySchedule.values
          assert(values.length == 1)
          assert_equal(0.6, values[0])
        end
      end
    end
    assert(found_schedule)  
    
  end

end


