#start the measure
#Author: Ian Metzger
class ImproveFanDriveEfficiency < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Improve Fan Drive Efficiency"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #populate choice argument for air loops in the model
    air_loop_handles = OpenStudio::StringVector.new
    air_loop_display_names = OpenStudio::StringVector.new

    #putting air loop names into hash
    air_loop_args = model.getAirLoopHVACs
    air_loop_args_hash = {}
    air_loop_args.each do |air_loop_arg|
      air_loop_args_hash[air_loop_arg.name.to_s] = air_loop_arg
    end

    #looping through sorted hash of air loops
    air_loop_args_hash.sort.map do |air_loop_name,air_loop|
      air_loop.supplyComponents.each do |supply_comp|
        #find all fans
        if supply_comp.to_FanConstantVolume.is_initialized
          air_loop_handles << air_loop.handle.to_s
          air_loop_display_names << air_loop_name
        elsif supply_comp.to_FanVariableVolume.is_initialized
          air_loop_handles << air_loop.handle.to_s
          air_loop_display_names << air_loop_name
        end
      end
    end
    
    #add building to string vector with air loops
    building = model.getBuilding
    air_loop_handles << building.handle.to_s
    air_loop_display_names << "*All Air Loops*"

    #make an argument for air loops
    object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", air_loop_handles, air_loop_display_names,true)
    object.setDisplayName("Choose an air loop to change total fan drive efficiency")
    object.setDefaultValue("*All Air Loops*") #if no air loop is chosen this will run on all air loops
    args << object
    
    #make an argument for fan type
    fan_type_chs = OpenStudio::StringVector.new
    fan_type_chs << "Centrifugal: Backward-Curved"
    fan_type_chs << "Centrifugal: Forward-Curved"
    fan_type_chs << "Centrifugal: Radial"
    fan_type_chs << "Axial: Vane"
    fan_type_chs << "Axial: Tube"
    fan_type_chs << "Axial: Propeller"
    fan_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('fan_type', fan_type_chs, true)
    fan_type.setDisplayName("Fan Type")
    fan_type.setDefaultValue("Centrifugal: Backward-Curved")
    args << fan_type
    
    #make an argument belt type
    belt_type_chs = OpenStudio::StringVector.new
    belt_type_chs << "Standard V-Belt"
    belt_type_chs << "Cogged V-Belt"
    belt_type_chs << "Synchronous Belt"
    belt_type_chs << "No Belt (Direct-Drive)"
    belt_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('belt_type', belt_type_chs, true)
    belt_type.setDisplayName("Belt Type")
    belt_type.setDefaultValue("Standard V-Belt")
    args << belt_type
    
    #make an argument for motor efficiency
    motor_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("motor_eff",true)
    motor_eff.setDisplayName("Motor Nameplate Efficiency (%)")
    args << motor_eff
    
    #make an argument for cost
    cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cost",true)
    cost.setDisplayName("Cost per fan ($)")
    cost.setDefaultValue(0)
    args << cost

    return args
    
  end #end the arguments method

  #define what happens when the measure is cop
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    #assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue("object",user_arguments,model) #model is passed in because of argument type
    fan_type = runner.getStringArgumentValue("fan_type",user_arguments)
    belt_type = runner.getStringArgumentValue("belt_type",user_arguments)
    motor_eff = runner.getDoubleArgumentValue("motor_eff",user_arguments)
    cost = runner.getDoubleArgumentValue("cost",user_arguments)
    
    #reporting initial condition of model
    fan_count = 0.0
    fan_eff = 0.0
    model.getAirLoopHVACs.each do |air_loop|
      #loop through all supply components on the airloop
      air_loop.supplyComponents.each do |supply_comp|
        #find initial fan count and average efficiency 
        get_fan=nil
        if supply_comp.to_FanConstantVolume.is_initialized
          get_fan = supply_comp.to_FanConstantVolume.get
        elsif supply_comp.to_FanVariableVolume.is_initialized
          get_fan = supply_comp.to_FanVariableVolume.get
        end
        if get_fan
          fan_count += 1.0
          fan_eff += get_fan.fanEfficiency
        end
      end #next supply component
    end #next airloop
    avg_fan_eff = fan_eff/fan_count
    runner.registerInitialCondition("The building has #{fan_count} fan system(s) with an average total fan drive efficiency of #{avg_fan_eff}")

    #check the air loop selection for reasonableness
    apply_to_all_air_loops = false
    selected_airloop = nil
    if object.empty?
      handle = runner.getStringArgumentValue("object",user_arguments)
      if handle.empty?
        runner.registerError("No air loop was chosen.")
      else
        runner.registerError("The selected air loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
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
    end  #end of if object.empty?
    
    #depending on user input, add selected airloops to an array
    selected_airloops = [] 
    if apply_to_all_air_loops == true
       selected_airloops = model.getAirLoopHVACs
    else
      selected_airloops << selected_airloop
    end
       
    fan_eff = nil
    if fan_type == "Centrifugal: Backward-Curved"
      fan_eff = 0.81
    elsif fan_type == "Centrifugal: Forward-Curved"
      fan_eff = 0.63
    elsif fan_type == "Centrifugal: Radial"
      fan_eff = 0.74
    elsif fan_type == "Axial: Vane"
      fan_eff = 0.82
    elsif fan_type == "Axial: Tube"
      fan_eff = 0.70
    elsif fan_type == "Axial: Propeller"
      fan_eff = 0.48
    else
      runner.registerError("Unknown fan type '#{fan_type}'.")
      return false
    end

    belt_eff = nil
    if belt_type == "Standard V-Belt"
      belt_eff = 0.95
    elsif belt_type == "Cogged V-Belt"
      belt_eff = 0.97
    elsif belt_type == "Synchronous Belt"
      belt_eff = 0.98
    elsif belt_type == "No Belt (Direct-Drive)"
      belt_eff = 1.00
    else
      runner.registerError("Unknown belt type '#{belt_type}'.")
      return false
    end
    
    #check if motor_eff is reasonable
    if motor_eff <= 0 or  motor_eff >= 100
      runner.registerError("Please enter a number between 0 and 100 for motor efficiency percentage.")
      return false
    end
    
    fanEfficiency = motor_eff*belt_eff*fan_eff

    number_fans = 0
    #replace fan efficiencies on the selected airloops
    selected_airloops.each do |air_loop|
      
      #loop through all supply components on the airloop
      air_loop.supplyComponents.each do |supply_comp|

        # check if this is a fan
        fan = nil
        if supply_comp.to_FanConstantVolume.is_initialized
          fan = supply_comp.to_FanConstantVolume.get
        elsif supply_comp.to_FanVariableVolume.is_initialized
          fan = supply_comp.to_FanVariableVolume.get
        end
        
        if fan
          number_fans += 1
          oldFanEfficiency = fan.fanEfficiency
          oldMotorEfficiency = fan.motorEfficiency
                         
          if oldFanEfficiency > fanEfficiency
            runner.registerWarning("New fan drive efficiency is lower than existing fan drive efficiency for #{fan.name}.")
          end
          
          if oldMotorEfficiency > motor_eff
            runner.registerWarning("New motor efficiency is lower than existing motor efficiency for #{fan.name}.")
          end
          
          fan.setFanEfficiency(fanEfficiency / 100.0)
          fan.setMotorEfficiency(motor_eff / 100.0)
          
          if cost.abs != 0
            OpenStudio::Model::LifeCycleCost::createLifeCycleCost("LCC_Mat - #{fan.name}", fan, cost, "CostPerEach", "Construction")
          end

          if oldMotorEfficiency != motor_eff/100.0
            runner.registerInfo("Changing motor efficiency on fan '#{fan.name}' from #{oldMotorEfficiency} to #{motor_eff}.")
          end          
          runner.registerInfo("Changing total fan drive efficiency on fan '#{fan.name}' from #{oldFanEfficiency} to #{fanEfficiency}.")

        end
      end
    end

    runner.registerFinalCondition("This measure changed #{number_fans} fan system(s) to a total fan drive efficiency of #{fanEfficiency} %")
    return true

  end #end the run method

end #end the measure
#\Desktop\ImproveFanDriveEfficiency\test>"c:\Program Files (x86)\OpenStudio 1.2.1\ruby-install\ruby\bin\ruby.exe" ImproveFanDriveEfficiency_Test.rb
#this allows the measure to be used by the application
ImproveFanDriveEfficiency.new.registerWithApplication