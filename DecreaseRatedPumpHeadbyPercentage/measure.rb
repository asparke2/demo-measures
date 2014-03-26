#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class DecreaseRatedPumpHeadbyPercentage < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "DecreaseRatedPumpHeadbyPercentage"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #populate choice argument for constructions that are applied to surfaces in the model
    loop_handles = OpenStudio::StringVector.new
    loop_display_names = OpenStudio::StringVector.new

    #putting loops and names into hash
    loop_args = model.getPlantLoops
    loop_args_hash = {}
    loop_args.each do |loop_arg|
      loop_args_hash[loop_arg.name.to_s] = loop_arg
    end

    #looping through sorted hash of air loops
    loop_args_hash.sort.map do |key,value|
      show_loop = false
      components = value.supplyComponents
      components.each do |component|
        if not component.to_PumpConstantSpeed.empty?
          show_loop = true
        end
        if not component.to_PumpVariableSpeed.empty?
          show_loop = true
        end
      end

      #if loop as object of correct type then add to hash.
      if show_loop == true
        loop_handles << value.handle.to_s
        loop_display_names << key
      end
    end

    #add building to string vector with air loops
    building = model.getBuilding
    loop_handles << building.handle.to_s
    loop_display_names << "*Pumps on All Plant Loops*"

    #make an argument for air loops
    object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", loop_handles, loop_display_names,true)
    object.setDisplayName("Choose a Plant Loop whose Pumps to Alter.")
    object.setDefaultValue("*Pumps on All Plant Loops*") #if no loop is chosen this will run on all air loops
    args << object

    #make an argument to add new space true/false
    pump_head_pct_decrease = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("pump_head_pct_decrease",true)
    pump_head_pct_decrease.setDisplayName("Percent Rated Pump Head Decrease(%).")
    pump_head_pct_decrease.setDefaultValue(30.0)
    args << pump_head_pct_decrease
    
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
    pump_head_pct_decrease = runner.getDoubleArgumentValue("pump_head_pct_decrease",user_arguments)
    
    #check to make sure the selected loop still exists
    apply_to_all_loops = false
    loop = nil
    if object.empty?
      handle = runner.getStringArgumentValue("loop",user_arguments)
      if handle.empty?
        runner.registerError("No loop was chosen.")
      else
        runner.registerError("The selected loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_Loop.empty?
        loop = object.get.to_Loop.get
      elsif not object.get.to_Building.empty?
        apply_to_all_loops = true
      else
        runner.registerError("Script Error - argument not showing up as loop.")
        return false
      end
    end  #end of if loop.empty?

    #get loops for measure
    if apply_to_all_loops
      loops = model.getPlantLoops
    else
      loops = []
      loops << loop #only run on a single plant loop
    end

    # get cop values
    initial_pump_head_values = []
    final_pump_head_values = []

    #loop through air loops
    loops.each do |loop|
      loop.supplyComponents.each do |component|
        if component.to_PumpConstantSpeed.is_initialized
          pump = component.to_PumpConstantSpeed.get
          initial_pump_head = pump.ratedPumpHead
          initial_pump_head_values << OpenStudio::convert(initial_pump_head, "ftH_{2}O","Pa").get
          new_pump_head = initial_pump_head * ((100 + pump_head_pct_decrease)/100)
          pump.setRatedPumpHead(new_pump_head)
          verified_new_pump_head = pump.ratedPumpHead
          final_pump_head_values << OpenStudio::convert(verified_new_pump_head, "ftH_{2}O","Pa").get
          runner.registerInfo("#{pump.name.get} was changed from #{OpenStudio::convert(initial_pump_head, "ftH_{2}O","Pa").get} ftH2O to #{OpenStudio::convert(verified_new_pump_head, "ftH_{2}O","Pa").get} ftH2O")          
        end
        if component.to_PumpVariableSpeed.is_initialized
          pump = component.to_PumpVariableSpeed.get
          initial_pump_head = pump.ratedPumpHead
          initial_pump_head_values << OpenStudio::convert(initial_pump_head, "ftH_{2}O","Pa").get
          new_pump_head = initial_pump_head * ((100 + pump_head_pct_decrease)/100)
          pump.setRatedPumpHead(new_pump_head)
          verified_new_pump_head = pump.ratedPumpHead
          final_pump_head_values << OpenStudio::convert(verified_new_pump_head, "ftH_{2}O","Pa").get
          runner.registerInfo("#{pump.name.get} was changed from #{OpenStudio::convert(initial_pump_head, "ftH_{2}O","Pa").get} ftH2O to #{OpenStudio::convert(verified_new_pump_head, "ftH_{2}O","Pa").get} ftH2O")         
        end
      end
    end
    
    
    #report the final and initial pump heads
    runner.registerInitialCondition("The initial pump head values were: #{initial_pump_head_values} ftH2O")
    runner.registerFinalCondition("The final pump head values were: #{initial_pump_head_values} ftH2O")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
DecreaseRatedPumpHeadbyPercentage.new.registerWithApplication