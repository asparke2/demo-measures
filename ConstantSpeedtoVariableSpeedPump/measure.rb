#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ConstantSpeedtoVariableSpeedPump < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Constant Speed to Variable Flow Speed"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #populate choice argument for plant loops in the model
    plant_loop_handles = OpenStudio::StringVector.new
    plant_loop_display_names = OpenStudio::StringVector.new

    #putting plant loop names into hash
    plant_loop_args = model.getPlantLoops
    plant_loop_args_hash = {}
    plant_loop_args.each do |plant_loop_arg|
      plant_loop_args_hash[plant_loop_arg.name.to_s] = plant_loop_arg
    end

    #looping through sorted hash of plant loops
    plant_loop_args_hash.sort.map do |plant_loop_name,plant_loop|
      plant_loop.supplyComponents.each do |supply_comp|
        #find constant speed pumps
        if supply_comp.to_PumpConstantSpeed.is_initialized
          plant_loop_handles << plant_loop.handle.to_s
          plant_loop_display_names << plant_loop_name
        end
      end
    end

    #add building to string vector with plant loops
    building = model.getBuilding
    plant_loop_handles << building.handle.to_s
    plant_loop_display_names << "*All Plant Loops*"

    #make an argument for air loops
    object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", plant_loop_handles, plant_loop_display_names, true)
    object.setDisplayName("Choose a Plant Loop to change from Constant Speed to Variable Speed.")
    object.setDefaultValue("*All Plant Loops*") #if no plant loop is chosen this will run on all plant loops
    args << object

    #make an argument for variable speed pump minimum flow rate
    min_flow_gpm = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("min_flow_gpm",true)
    min_flow_gpm.setDisplayName("Pump Minimum Flow Rate (gpm) (0 means VFD can ramp to 0%).")
    min_flow_gpm.setDefaultValue(0.0)
    args << min_flow_gpm    
    
    #make an argument to remove existing costs
    remove_costs = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remove_costs",true)
    remove_costs.setDisplayName("Remove Existing Costs?")
    remove_costs.setDefaultValue(true)
    args << remove_costs

    #make an argument for material and installation cost
    material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)
    material_cost.setDisplayName("Material and Installation Costs per Variable Speed Unit ($).")
    material_cost.setDefaultValue(0.0)
    args << material_cost

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
    object = runner.getOptionalWorkspaceObjectChoiceValue("object",user_arguments,model) #model is passed in because of argument type
    min_flow_gpm = runner.getDoubleArgumentValue("min_flow_gpm",user_arguments)
    remove_costs = runner.getBoolArgumentValue("remove_costs",user_arguments)
    material_cost = runner.getDoubleArgumentValue("material_cost",user_arguments)
    
    #reporting initial condition of model
    initial_constantspeed_plantloops = 0
    model.getPlantLoops.each do |plant_loop|
      #loop through all supply components on the plant loop
      plant_loop.supplyComponents.each do |supply_comp|
        #find constant speed pumps
        if supply_comp.to_PumpConstantSpeed.is_initialized
          initial_constantspeed_plantloops += 1
        end
      end #next supply component
    end #next plantloop
    runner.registerInitialCondition("The building started with #{initial_constantspeed_plantloops} constant speed plant loops.")
    
    #check the plant loop selection for reasonableness
    apply_to_all_plant_loops = false
    selected_plantloop = nil
    if object.empty?
      handle = runner.getStringArgumentValue("object",user_arguments)
      if handle.empty?
        runner.registerError("No plant loop was chosen.")
      else
        runner.registerError("The selected plant loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_PlantLoop.empty?
        selected_plantloop = object.get.to_PlantLoop.get
      elsif not object.get.to_Building.empty?
        apply_to_all_plant_loops = true
      else
        runner.registerError("Script Error - argument not showing up as plant loop.")
        return false
      end
    end  #end of if object.empty?
    
    #check min flow gpm argument for reasonableness
    if min_flow_gpm < 0
      runner.registerError("min flow must be greater than 0 gpm")
      return false
    end
    min_flow_m3pers = OpenStudio::convert(min_flow_gpm, "gal/min", "m^3/s").get
    
    
    #depending on user input, add selected airloops to an array
    selected_plantloops = [] 
    if apply_to_all_plant_loops == true
      selected_plantloops = model.getPlantLoops
    else
      selected_plantloops << selected_plantloop
    end
    
    #replace constant speed with variable speed pumps on the selected airloops
    selected_plantloops.each do |plant_loop|
      
      replaced = false
      
      #loop through all supply components on the plant loop
      plant_loop.supplyComponents.each do |supply_comp|

        #find constant speed pump to variable speed
        if supply_comp.to_PumpConstantSpeed.is_initialized
        
          # make the new vav_fan and transfer existing costs to it
          variable_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
          if not remove_costs
            supply_comp.lifeCycleCosts.each do |object_LCC|
              OpenStudio::Model::LifeCycleCost::createLifeCycleCost(object_LCC.name, variable_pump, object_LCC.cost, object_LCC.costUnits, object_LCC.category, object_LCC.repeatPeriodYears, object_LCC.yearsFromStart)
            end
          end
          
          if material_cost.abs != 0
            OpenStudio::Model::LifeCycleCost::createLifeCycleCost("LCC_Mat - #{variable_pump.name}", variable_pump, material_cost, "CostPerEach", "Construction")
          end
        
          #preserve characteristics of the original pump
          constant_pump = supply_comp.to_PumpConstantSpeed.get
          
          #preserve flow rate hard sizing
          if not constant_pump.isRatedFlowRateAutosized
            constant_rated_flow_rate = constant_pump.ratedFlowRate.get
            variable_pump.setRatedFlowRate(constant_rated_flow_rate)
          end 
          
          #preserve rated pump head
          constant_rated_pump_head = constant_pump.ratedPumpHead
          variable_pump.setRatedPumpHead(constant_rated_pump_head)
           
          #preserve rated power consumption
          if not constant_pump.isRatedPowerConsumptionAutosized
            constant_rated_pwr_cons = constant_pump.ratedPowerConsumption.get
            variable_pump.setRatedPowerConsumption(constant_rated_pwr_cons)
          end

          #preserve motor efficiency
          constant_motor_efficiency = constant_pump.motorEfficiency
          variable_pump.setMotorEfficiency(constant_motor_efficiency)          
          
          #preserve fraction of inefficiencies to fluid stream
          constant_motor_inefficiencies = constant_pump.fractionofMotorInefficienciestoFluidStream
          variable_pump.setFractionofMotorInefficienciestoFluidStream(constant_motor_inefficiencies)     
           
          #set the minimum flow for the VFD
          variable_pump.setMinimumFlowRate(min_flow_m3pers)
                    
          #remove the constant speed pump
          pump_outlet_node = supply_comp.to_PumpConstantSpeed.get.inletModelObject.get.to_Node.get
          supply_comp.remove
          variable_pump.addToNode(pump_outlet_node)

          #let the user know that a change was made
          replaced = true
          runner.registerInfo("Plant loop #{plant_loop.name} was changed from constant speed to variable speed")
          
        end
      end #next supply component
    
    end #next selected plant loop
    
    #reporting final condition of model
    final_constantspeed_plantloops = 0
    model.getPlantLoops.each do |plant_loop|
      #loop through all supply components on the plant loop
      plant_loop.supplyComponents.each do |supply_comp|
        #find constant speed pumps
        if supply_comp.to_PumpConstantSpeed.is_initialized
          final_constantspeed_plantloops += 1
        end
      end #next supply component
    end #next selected plant loop
    runner.registerFinalCondition("The building finished with #{final_constantspeed_plantloops} constant speed plant loops.")
    
    if final_constantspeed_plantloops == initial_constantspeed_plantloops 
      runner.registerAsNotApplicable("This measure is not applicable; no plant loops were changed from constant speed to variable speed")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ConstantSpeedtoVariableSpeedPump.new.registerWithApplication