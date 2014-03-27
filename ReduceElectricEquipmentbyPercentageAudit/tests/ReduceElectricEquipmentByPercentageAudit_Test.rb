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

class ReduceElectricEquipmentByPercentageAudit_Test < Test::Unit::TestCase
  
  def makeTestModel
    model = OpenStudio::Model::Model.new
    
    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0, 10, 0)
    vertices << OpenStudio::Point3d.new(10, 10, 0)
    vertices << OpenStudio::Point3d.new(10, 0, 0)
    vertices << OpenStudio::Point3d.new(0, 0, 0)
    space = OpenStudio::Model::Space::fromFloorPrint(vertices, 3, model).get
    
    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName("General Def")
    equip_def.setWattsperSpaceFloorArea(1.0)
       
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setSpace(space)
    
    computer_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    computer_def.setName("Computer Def")
    computer_def.setDesignLevel(100.0)
    
    computer = OpenStudio::Model::ElectricEquipment.new(computer_def)
    computer.setSpace(space)
    
    return model
  end
  
  # def setup
  # end

  # def teardown
  # end
  
  def test_ReduceElectricEquipmentByPercentageAudit_AllEquipment
     
    # create an instance of the measure
    measure = ReduceElectricEquipmentByPercentageAudit.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get test model
    model = makeTestModel
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("equip_def", arguments[0].name)
    assert_equal("equip_power_reduction_percent", arguments[1].name)
    assert_equal("material_and_installation_cost", arguments[2].name)
    assert_equal("expected_life", arguments[3].name)
    assert_equal("om_cost", arguments[4].name)
    assert_equal("om_frequency", arguments[5].name)

    # fill in argument_map
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    equip_def = arguments[count += 1].clone
    assert(equip_def.setValue("*All Equipment*"))
    argument_map["equip_def"] = equip_def

    equip_power_reduction_percent = arguments[count += 1].clone
    assert(equip_power_reduction_percent.setValue(20.0))
    argument_map["equip_power_reduction_percent"] = equip_power_reduction_percent

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
    assert_equal(200, building.electricEquipmentPower)
    assert_equal(0, building.lifeCycleCosts.size)
    
    measure.run(model, runner, argument_map)
    result = runner.result
    puts "test_ReduceElectricEquipmentByPercentage_AllEquipment"
    show_output(result)
    assert(result.value.valueName == "Success")

    building = model.getBuilding
    assert_equal(160, building.electricEquipmentPower)
    assert_equal(1, building.lifeCycleCosts.size)
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceElectricEquipmentByPercentageAudit_GeneralEquipment
     
    # create an instance of the measure
    measure = ReduceElectricEquipmentByPercentageAudit.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get test model
    model = makeTestModel
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("equip_def", arguments[0].name)
    assert_equal("equip_power_reduction_percent", arguments[1].name)
    assert_equal("material_and_installation_cost", arguments[2].name)
    assert_equal("expected_life", arguments[3].name)
    assert_equal("om_cost", arguments[4].name)
    assert_equal("om_frequency", arguments[5].name)

    # fill in argument_map
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    equip_def = arguments[count += 1].clone
    assert(equip_def.setValue("General Def"))
    argument_map["equip_def"] = equip_def

    equip_power_reduction_percent = arguments[count += 1].clone
    assert(equip_power_reduction_percent.setValue(20.0))
    argument_map["equip_power_reduction_percent"] = equip_power_reduction_percent

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
    assert_equal(200, building.electricEquipmentPower)
    assert_equal(0, building.lifeCycleCosts.size)
    
    measure.run(model, runner, argument_map)
    result = runner.result
    puts "test_ReduceElectricEquipmentByPercentageAudit_GeneralEquipment"
    show_output(result)
    assert(result.value.valueName == "Success")

    building = model.getBuilding
    assert_equal(180, building.electricEquipmentPower)
    assert_equal(2, building.lifeCycleCosts.size)
  end

  def test_ReduceElectricEquipmentByPercentageAudit_ComputerEquipment
     
    # create an instance of the measure
    measure = ReduceElectricEquipmentByPercentageAudit.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get test model
    model = makeTestModel
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("equip_def", arguments[0].name)
    assert_equal("equip_power_reduction_percent", arguments[1].name)
    assert_equal("material_and_installation_cost", arguments[2].name)
    assert_equal("expected_life", arguments[3].name)
    assert_equal("om_cost", arguments[4].name)
    assert_equal("om_frequency", arguments[5].name)

    # fill in argument_map
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    equip_def = arguments[count += 1].clone
    assert(equip_def.setValue("Computer Def"))
    argument_map["equip_def"] = equip_def

    equip_power_reduction_percent = arguments[count += 1].clone
    assert(equip_power_reduction_percent.setValue(20.0))
    argument_map["equip_power_reduction_percent"] = equip_power_reduction_percent

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
    assert_equal(200, building.electricEquipmentPower)
    assert_equal(0, building.lifeCycleCosts.size)
    
    measure.run(model, runner, argument_map)
    result = runner.result
    puts "test_ReduceElectricEquipmentByPercentageAudit_ComputerEquipment"
    show_output(result)
    assert(result.value.valueName == "Success")

    building = model.getBuilding
    assert_equal(180, building.electricEquipmentPower)
    assert_equal(0, building.lifeCycleCosts.size)
  end
end


