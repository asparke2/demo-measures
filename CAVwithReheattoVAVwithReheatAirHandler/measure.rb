#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class CAVwithReheattoVAVwithReheatAirHandler < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "CAVwithReheattoVAVwithReheatAirHandler"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #populate choice argument for constructions that are applied to surfaces in the model
    air_loop_handles = OpenStudio::StringVector.new
    air_loop_display_names = OpenStudio::StringVector.new

    #putting space types and names into hash
    air_loop_args = model.getAirLoopHVACs
    air_loop_args_hash = {}
    air_loop_args.each do |air_loop_arg|
      air_loop_args_hash[air_loop_arg.name.to_s] = air_loop_arg
    end

    #looping through sorted hash of air loops, looking
    air_loop_args_hash.sort.map do |air_loop_name,air_loop|
      air_loop.supplyComponents.each do |supply_comp|
        #find CAV fan and replace with VAV fan
        if supply_comp.to_FanConstantVolume.is_initialized
          air_loop_handles << air_loop.handle.to_s
          air_loop_display_names << air_loop_name
        end
      end
    end

    #add building to string vector with air loops
    building = model.getBuilding
    air_loop_handles << building.handle.to_s
    air_loop_display_names << "*All CAV Air Loops*"

    #make an argument for air loops
    object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", air_loop_handles, air_loop_display_names,true)
    object.setDisplayName("Choose an Air Loop to change from CAV to VAV.")
    object.setDefaultValue("*All Air Loops*") #if no air loop is chosen this will run on all air loops
    args << object

    #make an argument to remove existing costs
    remove_costs = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remove_costs",true)
    remove_costs.setDisplayName("Remove Existing Costs?")
    remove_costs.setDefaultValue(true)
    args << remove_costs

    #make an argument for material and installation cost
    material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)
    material_cost.setDisplayName("Material and Installation Costs per Cooling Coil DX Two Speed Unit ($).")
    material_cost.setDefaultValue(0.0)
    args << material_cost

    #make an argument for demolition cost
    demolition_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("demolition_cost",true)
    demolition_cost.setDisplayName("Demolition Costs per Cooling Coil DX Two Speed Unit ($).")
    demolition_cost.setDefaultValue(0.0)
    args << demolition_cost

    #make an argument for duration in years until costs start
    years_until_costs_start = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("years_until_costs_start",true)
    years_until_costs_start.setDisplayName("Years Until Costs Start (whole years).")
    years_until_costs_start.setDefaultValue(0)
    args << years_until_costs_start

    #make an argument to determine if demolition costs should be included in initial construction
    demo_cost_initial_const = OpenStudio::Ruleset::OSArgument::makeBoolArgument("demo_cost_initial_const",true)
    demo_cost_initial_const.setDisplayName("Demolition Costs Occur During Initial Construction?")
    demo_cost_initial_const.setDefaultValue(false)
    args << demo_cost_initial_const

    #make an argument for expected life
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life (whole years).")
    expected_life.setDefaultValue(20)
    args << expected_life

    #make an argument for o&m cost
    om_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost",true)
    om_cost.setDisplayName("O & M Costs per Cooling Coil DX Two Speed Unit ($).")
    om_cost.setDefaultValue(0.0)
    args << om_cost

    #make an argument for o&m frequency
    om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency",true)
    om_frequency.setDisplayName("O & M Frequency (whole years).")
    om_frequency.setDefaultValue(1)
    args << om_frequency
    
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
    remove_costs = runner.getBoolArgumentValue("remove_costs",user_arguments)
    material_cost = runner.getDoubleArgumentValue("material_cost",user_arguments)
    demolition_cost = runner.getDoubleArgumentValue("demolition_cost",user_arguments)
    years_until_costs_start = runner.getIntegerArgumentValue("years_until_costs_start",user_arguments)
    demo_cost_initial_const = runner.getBoolArgumentValue("demo_cost_initial_const",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)
    om_cost = runner.getDoubleArgumentValue("om_cost",user_arguments)
    om_frequency = runner.getIntegerArgumentValue("om_frequency",user_arguments)
    
    #reporting initial condition of model
    initial_cav_airloops = 0
    model.getAirLoopHVACs.each do |air_loop|
      #loop through all supply components on the airloop
      air_loop.supplyComponents.each do |supply_comp|
        #find CAV fan and replace with VAV fan
        if supply_comp.to_FanConstantVolume.is_initialized
        initial_cav_airloops += 1
        end
      end #next supply component
    end #next selected airloop
    runner.registerInitialCondition("The building started with #{initial_cav_airloops} CAV air loops.")
    
    #check the air loop selection for reasonableness
    apply_to_all_air_loops = false
    selected_airloop = nil
    if object.empty?
      handle = runner.getStringArgumentValue("object",user_arguments)
      if handle.empty?
        runner.registerError("No air loop was chosen.")
      else
        runner.registerError("The selected air_loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_AirLoopHVAC.empty?
        selected_airloop = object.get.to_AirLoopHVAC.get
      elsif not object.get.to_Building.empty?
        apply_to_all_air_loops = true
      else
        runner.registerError("Script Error - argument not showing up as air loop.")
        return false
      end
    end  #end of if air_loop.empty?

    #depending on user input, add selected airloops to an array
    selected_airloops = [] 
    if apply_to_all_air_loops == true
       selected_airloops = model.getAirLoopHVACs
    else
      selected_airloops << selected_airloop
    end
    
    #replace CAV with VAV fans on the selected airloops
    selected_airloops.each do |air_loop|
      #loop through all supply components on the airloop
      air_loop.supplyComponents.each do |supply_comp|
        #find CAV fan and replace with VAV fan
        if supply_comp.to_FanConstantVolume.is_initialized
        
          #remove the CAV fan and add a new VAV fan
          fan_outlet_node = supply_comp.to_FanConstantVolume.get.outletModelObject.get.to_Node.get
          supply_comp.remove
          vav_fan = OpenStudio::Model::FanVariableVolume.new(model, model.alwaysOnDiscreteSchedule)
          vav_fan.addToNode(fan_outlet_node)

          #add a mixed air setpoint manager to the new fan's inlet node
          stp_mixed = OpenStudio::Model::SetpointManagerMixedAir.new(model)
          stp_mixed.addToNode(vav_fan.inletModelObject.get.to_Node.get)

          #replace the existing setpoint manager with a new one that does SA temp reset
          sa_stpt_manager = OpenStudio::Model::SetpointManagerWarmest.new(model)
          sa_stpt_manager.setMinimumSetpointTemperature(OpenStudio::convert(55.0,"F","C").get)
          sa_stpt_manager.setMaximumSetpointTemperature(OpenStudio::convert(65.0,"F","C").get)
          air_loop.supplyOutletNode.addSetpointManagerWarmest(sa_stpt_manager)

          #let the user know that a change was made
          runner.registerInfo("AirLoop #{air_loop.name} was changed from CAV to VAV")
          
          #TODO add the cost of the retrofit to the AirLoop
          
          #also, if a VAV system is DX, the DX coil must be a 2 speed DX coil
          air_loop.supplyComponents.each do |supply_comp|
            #find single speed DX coil and replace with 2 speed DX coil
            if supply_comp.to_CoilCoolingDXSingleSpeed.is_initialized
              
              dx_coil_inlet_node = supply_comp.to_CoilCoolingDXSingleSpeed.get.inletModelObject.get.to_Node.get
              supply_comp.remove
              
              #make a replacement 2 speed cooling coil
              #coil cooling dx twospeed
              #from HVACTemplates.cpp Add System Type 5 Packaged Rooftop VAV with Reheat
                
              coil_clg_dx_2spd_clg_curve_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setName("coil_clg_dx_2spd_clg_curve_f_of_temp")
              coil_clg_dx_2spd_clg_curve_f_of_temp.setCoefficient1Constant(0.42415)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setCoefficient2x(0.04426)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setCoefficient3xPOW2(-0.00042)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setCoefficient4y(0.00333)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setCoefficient5yPOW2(-0.00008)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setCoefficient6xTIMESY(-0.00021)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setMinimumValueofx(17.0)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setMaximumValueofx(22.0)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setMinimumValueofy(13.0)
              coil_clg_dx_2spd_clg_curve_f_of_temp.setMaximumValueofy(46.0)

              coil_clg_dx_2spd_clg_curve_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
              coil_clg_dx_2spd_clg_curve_f_of_flow.setName("coil_clg_dx_2spd_clg_curve_f_of_flow")
              coil_clg_dx_2spd_clg_curve_f_of_flow.setCoefficient1Constant(0.77136)
              coil_clg_dx_2spd_clg_curve_f_of_flow.setCoefficient2x(0.34053)
              coil_clg_dx_2spd_clg_curve_f_of_flow.setCoefficient3xPOW2(-0.11088)
              coil_clg_dx_2spd_clg_curve_f_of_flow.setMinimumValueofx(0.75918)
              coil_clg_dx_2spd_clg_curve_f_of_flow.setMaximumValueofx(1.13877)

              coil_clg_dx_2spd_energy_input_ratio_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setName("coil_clg_dx_2spd_energy_input_ratio_f_of_temp")
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setCoefficient1Constant(1.23649)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setCoefficient2x(-0.02431)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setCoefficient3xPOW2(0.00057)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setCoefficient4y(-0.01434)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setCoefficient5yPOW2(0.00063)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setCoefficient6xTIMESY(-0.00038)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setMinimumValueofx(17.0)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setMaximumValueofx(22.0)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setMinimumValueofy(13.0)
              coil_clg_dx_2spd_energy_input_ratio_f_of_temp.setMaximumValueofy(46.0)

              coil_clg_dx_2spd_energy_input_ratio_f_of_flow = OpenStudio::Model::CurveQuadratic.new(model)
              coil_clg_dx_2spd_energy_input_ratio_f_of_flow.setName("coil_clg_dx_2spd_energy_input_ratio_f_of_flow")
              coil_clg_dx_2spd_energy_input_ratio_f_of_flow.setCoefficient1Constant(1.20550)
              coil_clg_dx_2spd_energy_input_ratio_f_of_flow.setCoefficient2x(-0.32953)
              coil_clg_dx_2spd_energy_input_ratio_f_of_flow.setCoefficient3xPOW2(0.12308)
              coil_clg_dx_2spd_energy_input_ratio_f_of_flow.setMinimumValueofx(0.75918)
              coil_clg_dx_2spd_energy_input_ratio_f_of_flow.setMaximumValueofx(1.13877)

              coil_clg_dx_2spd_part_load_fraction = OpenStudio::Model::CurveQuadratic.new(model)
              coil_clg_dx_2spd_part_load_fraction.setName("coil_clg_dx_2spd_part_load_fraction")
              coil_clg_dx_2spd_part_load_fraction.setCoefficient1Constant(0.77100)
              coil_clg_dx_2spd_part_load_fraction.setCoefficient2x(0.22900)
              coil_clg_dx_2spd_part_load_fraction.setCoefficient3xPOW2(0.0)
              coil_clg_dx_2spd_part_load_fraction.setMinimumValueofx(0.0)
              coil_clg_dx_2spd_part_load_fraction.setMaximumValueofx(1.0)

              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp = OpenStudio::Model::CurveBiquadratic.new(model)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setName("coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp")
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setCoefficient1Constant(0.42415)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setCoefficient2x(0.04426)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setCoefficient3xPOW2(-0.00042)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setCoefficient4y(0.00333)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setCoefficient5yPOW2(-0.00008)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setCoefficient6xTIMESY(-0.00021)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setMinimumValueofx(17.0)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setMaximumValueofx(22.0)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setMinimumValueofy(13.0)
              coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp.setMaximumValueofy(46.0)

              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow = OpenStudio::Model::CurveBiquadratic.new(model)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setName("coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow")
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setCoefficient1Constant(1.23649)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setCoefficient2x(-0.02431)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setCoefficient3xPOW2(0.00057)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setCoefficient4y(-0.01434)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setCoefficient5yPOW2(0.00063)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setCoefficient6xTIMESY(-0.00038)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setMinimumValueofx(17.0)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setMaximumValueofx(22.0)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setMinimumValueofy(13.0)
              coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow.setMaximumValueofy(46.0)
              
              two_speed_dx_coil = OpenStudio::Model::CoilCoolingDXTwoSpeed.new(model,
                                                    model.alwaysOnDiscreteSchedule,
                                                    coil_clg_dx_2spd_clg_curve_f_of_temp,
                                                    coil_clg_dx_2spd_clg_curve_f_of_flow,
                                                    coil_clg_dx_2spd_energy_input_ratio_f_of_temp,
                                                    coil_clg_dx_2spd_energy_input_ratio_f_of_flow,
                                                    coil_clg_dx_2spd_part_load_fraction, 
                                                    coil_clg_dx_2spd_clg_lowspd_curve_f_of_temp,
                                                    coil_clg_dx_2spd_energy_lowspd_input_ratio_f_of_flow)
              
              two_speed_dx_coil.addToNode(dx_coil_inlet_node)
              
              #add a mixed air setpoint manager to the new fan's inlet node
              stp_mixed = OpenStudio::Model::SetpointManagerMixedAir.new(model)
              stp_mixed.addToNode(two_speed_dx_coil.outletModelObject.get.to_Node.get)
              stp_mixed.setFanInletNode(vav_fan.inletModelObject.get.to_Node.get)
              runner.registerInfo("Set the new setpointmanager")
            end
          end #next supply component
          
        end
      end #next supply component
    end #next selected airloop
    
    #reporting final condition of model
    final_cav_airloops = 0
    model.getAirLoopHVACs.each do |air_loop|
      #loop through all supply components on the airloop
      air_loop.supplyComponents.each do |supply_comp|
        #find CAV fan and replace with VAV fan
        if supply_comp.to_FanConstantVolume.is_initialized
        final_cav_airloops += 1
        end
      end #next supply component
    end #next selected airloop
    runner.registerFinalCondition("The building finished with #{final_cav_airloops} spaces.")
    
    if final_cav_airloops == initial_cav_airloops 
      runner.registerAsNotApplicable("This measure is not applicable; no airloops were changed from CAV to VAV")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
CAVwithReheattoVAVwithReheatAirHandler.new.registerWithApplication