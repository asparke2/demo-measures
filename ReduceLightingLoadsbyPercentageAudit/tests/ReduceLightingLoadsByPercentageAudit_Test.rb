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

class ReduceLightingLoadsByPercentage_Test < Test::Unit::TestCase
  
  def makeTestModel
    model = OpenStudio::Model::Model.new
    
    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0, 10, 0)
    vertices << OpenStudio::Point3d.new(10, 10, 0)
    vertices << OpenStudio::Point3d.new(10, 0, 0)
    vertices << OpenStudio::Point3d.new(0, 0, 0)
    space = OpenStudio::Model::Space::fromFloorPrint(vertices, 3, model).get
    
    lights_def = OpenStudio::Model::LightsDefinition.new(model)
    lights_def.setName("Lights Def")
    lights_def.setWattsperSpaceFloorArea(1.0)
       
    lights = OpenStudio::Model::Lights.new(lights_def)
    lights.setSpace(space)
    
    luminaire_def = OpenStudio::Model::LuminaireDefinition.new(model)
    luminaire_def.setName("Luminaire Def")
    luminaire_def.setLightingPower(100.0)
    
    luminaire = OpenStudio::Model::Luminaire.new(luminaire_def)
    luminaire.setSpace(space)
    
    return model
  end
  
  # def setup
  # end

  # def teardown
  # end
  
  def test_ReduceLightingLoadsByPercentageAudit_AllLights
     
    # create an instance of the measure
    measure = ReduceLightingLoadsByPercentageAudit.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get test model
    model = makeTestModel
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("light_def", arguments[0].name)
    assert_equal("lighting_power_reduction_percent", arguments[1].name)
    assert_equal("material_and_installation_cost", arguments[2].name)
    assert_equal("expected_life", arguments[3].name)
    assert_equal("om_cost", arguments[4].name)
    assert_equal("om_frequency", arguments[5].name)

    # fill in argument_map
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    light_def = arguments[count += 1].clone
    assert(light_def.setValue("*All Lights*"))
    argument_map["light_def"] = light_def

    lighting_power_reduction_percent = arguments[count += 1].clone
    assert(lighting_power_reduction_percent.setValue(20.0))
    argument_map["lighting_power_reduction_percent"] = lighting_power_reduction_percent

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(10.0))
    argument_map["material_and_installation_cost"] = material_and_installation_cost

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map["expected_life"] = expected_life

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.0))
    argument_map["om_cost"] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map["om_frequency"] = om_frequency
    
    # test building
    building = model.getBuilding
    assert_equal(200, building.lightingPower)
    assert_equal(0, building.lifeCycleCosts.size)
    
    measure.run(model, runner, argument_map)
    result = runner.result
    puts "test_ReduceLightingLoadsByPercentageAudit_AllLights"
    show_output(result)
    assert(result.value.valueName == "Success")

    building = model.getBuilding
    assert_equal(160, building.lightingPower)
    assert_equal(1, building.lifeCycleCosts.size)
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceLightingLoadsByPercentageAudit_Lights
     
    # create an instance of the measure
    measure = ReduceLightingLoadsByPercentageAudit.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get test model
    model = makeTestModel
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("light_def", arguments[0].name)
    assert_equal("lighting_power_reduction_percent", arguments[1].name)
    assert_equal("material_and_installation_cost", arguments[2].name)
    assert_equal("expected_life", arguments[3].name)
    assert_equal("om_cost", arguments[4].name)
    assert_equal("om_frequency", arguments[5].name)

    # fill in argument_map
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    light_def = arguments[count += 1].clone
    assert(light_def.setValue("Lights Def"))
    argument_map["light_def"] = light_def

    lighting_power_reduction_percent = arguments[count += 1].clone
    assert(lighting_power_reduction_percent.setValue(20.0))
    argument_map["lighting_power_reduction_percent"] = lighting_power_reduction_percent

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(10.0))
    argument_map["material_and_installation_cost"] = material_and_installation_cost

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map["expected_life"] = expected_life

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(1.0))
    argument_map["om_cost"] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map["om_frequency"] = om_frequency
    
    # test building
    building = model.getBuilding
    assert_equal(200, building.lightingPower)
    assert_equal(0, building.lifeCycleCosts.size)
    
    measure.run(model, runner, argument_map)
    result = runner.result
    puts "test_ReduceLightingLoadsByPercentageAudit_Lights"
    show_output(result)
    assert(result.value.valueName == "Success")

    building = model.getBuilding
    assert_equal(180, building.lightingPower)
    assert_equal(2, building.lifeCycleCosts.size)
  end

  def test_ReduceLightingLoadsByPercentageAudit_Luminaire
     
    # create an instance of the measure
    measure = ReduceLightingLoadsByPercentageAudit.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get test model
    model = makeTestModel
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("light_def", arguments[0].name)
    assert_equal("lighting_power_reduction_percent", arguments[1].name)
    assert_equal("material_and_installation_cost", arguments[2].name)
    assert_equal("expected_life", arguments[3].name)
    assert_equal("om_cost", arguments[4].name)
    assert_equal("om_frequency", arguments[5].name)

    # fill in argument_map
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    light_def = arguments[count += 1].clone
    assert(light_def.setValue("Luminaire Def"))
    argument_map["light_def"] = light_def

    lighting_power_reduction_percent = arguments[count += 1].clone
    assert(lighting_power_reduction_percent.setValue(20.0))
    argument_map["lighting_power_reduction_percent"] = lighting_power_reduction_percent

    material_and_installation_cost = arguments[count += 1].clone
    argument_map["material_and_installation_cost"] = material_and_installation_cost

    expected_life = arguments[count += 1].clone
    argument_map["expected_life"] = expected_life

    om_cost = arguments[count += 1].clone
    argument_map["om_cost"] = om_cost

    om_frequency = arguments[count += 1].clone
    argument_map["om_frequency"] = om_frequency
    
    # test building
    building = model.getBuilding
    assert_equal(200, building.lightingPower)
    assert_equal(0, building.lifeCycleCosts.size)
    
    measure.run(model, runner, argument_map)
    result = runner.result
    puts "test_ReduceLightingLoadsByPercentageAudit_Luminaire"
    show_output(result)
    assert(result.value.valueName == "Success")

    building = model.getBuilding
    assert_equal(180, building.lightingPower)
    assert_equal(0, building.lifeCycleCosts.size)
  end
end


