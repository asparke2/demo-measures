#start the measure
class SetEfficiencyforHotWaterBoilers < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set COP for Two Speed DX Cooling Units"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for the boiler efficiency
    eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eff",true)
    eff.setDisplayName("Nominal Thermal Efficiency")
    eff.setDefaultValue(0.8)
    args << eff

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
    eff = runner.getDoubleArgumentValue("eff",user_arguments)

    #check the user_name for reasonableness
    if eff <= 0
      runner.registerError("Please enter a positive value for Nominal Thermal Efficiency.")
      return false
    end
    if eff > 1
      runner.registerWarning("The requested Nominal Thermal Efficiency must be <= 1")
    end
    
    #change the efficiency of each boiler
    #loop through all the plant loops in the mode
    model.getPlantLoops.each do |plant_loop|
      #loop through all the supply components on this plant loop
      plant_loop.supplyComponents.each do |supply_component|
        #check if the supply component is a boiler
        if not supply_component.to_BoilerHotWater.empty?
          boiler = supply_component.to_BoilerHotWater.get
          #set the efficiency of the boiler
          boiler.setNominalThermalEfficiency(eff)
          runner.registerInfo("set boiler #{boiler.name} efficiency to #{eff}")
        end
      end
    end
    
    
=begin 
    initial_effs = []
    missing_initial_effs = 0

    #find and loop through air loops
    air_loops = model.getAirLoopHVACs
    air_loops.each do |air_loop|
      supply_components = air_loop.supplyComponents

      #find two speed dx units on loop
      supply_components.each do |supply_component|
        dx_unit = supply_component.to_CoilCoolingDXTwoSpeed
        if not dx_unit.empty?
          dx_unit = dx_unit.get

          #change and report high speed cop
          initial_high_cop = dx_unit.ratedHighSpeedCOP
          if not initial_high_cop.empty?
            runner.registerInfo("Changing the Rated High Speed COP from #{initial_high_cop.get} to #{cop_high} for two speed dx unit '#{dx_unit.name}' on air loop '#{air_loop.name}'")
            initial_high_cop_values << initial_high_cop.get
            dx_unit.setRatedHighSpeedCOP(cop_high)
          else
            runner.registerInfo("Setting the Rated High Speed COP to #{cop_high} for two speed dx unit '#{dx_unit.name}' on air loop '#{air_loop.name}. The original object did not have a Rated High Speed COP value'")
            missing_initial_high_cop = missing_initial_high_cop + 1
            dx_unit.setRatedHighSpeedCOP(cop_high)
          end

          #change and report low speed cop
          initial_low_cop = dx_unit.ratedLowSpeedCOP
          if not initial_low_cop.empty?
            runner.registerInfo("Changing the Rated Low Speed COP from #{initial_low_cop.get} to #{cop_low} for two speed dx unit '#{dx_unit.name}' on air loop '#{air_loop.name}'")
            initial_low_cop_values << initial_low_cop.get
            dx_unit.setRatedLowSpeedCOP(cop_low)
          else
            runner.registerInfo("Setting the Rated Low Speed COP to #{cop_low} for two speed dx unit '#{dx_unit.name}' on air loop '#{air_loop.name}. The original object did not have a Rated Low Speed COP COP value'")
            missing_initial_low_cop = missing_initial_low_cop + 1
            dx_unit.setRatedLowSpeedCOP(cop_low)
          end

        end #end if not dx_unit.empty?

      end #end supply_components.each do

    end #end air_loops.each do

    #reporting initial condition of model
    runner.registerInitialCondition("The starting Rated High Speed COP values range from #{initial_high_cop_values.min} to #{initial_high_cop_values.max}. The starting Rated Low Speed COP values range from #{initial_low_cop_values.min} to #{initial_low_cop_values.max}.")

    #warning if two counts of cop's are not the same
    if not initial_high_cop_values.size + missing_initial_high_cop == initial_low_cop_values.size + missing_initial_low_cop
      runner.registerWarning("Something went wrong with the measure, not clear on count of two speed dx objects")
    end

    if initial_high_cop_values.size + missing_initial_high_cop == 0
      runner.registerAsNotApplicable("The model does not contain any two speed DX cooling units, the model will not be altered.")
      return true
    end

    #reporting final condition of model
    runner.registerFinalCondition("#{initial_high_cop_values.size + missing_initial_high_cop} two speed dx units had their High and Low speed COP values set to #{cop_high} for high, and #{cop_low} for low.")
=end
    return true

  end #end the cop method

end #end the measure

#this allows the measure to be used by the application
SetEfficiencyforHotWaterBoilers.new.registerWithApplication