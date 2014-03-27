#start the measure
class IncreaseChillerCOP < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Increase Chiller COP"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #populate choice argument for plant loops with chillers
    plant_loop_handles = OpenStudio::StringVector.new
    plant_loop_names = OpenStudio::StringVector.new
    model.getChillerElectricEIRs.each do |chiller|
      if chiller.plantLoop.is_initialized
        plant_loop = chiller.plantLoop.get
        plant_loop_handles << plant_loop.handle.to_s
        plant_loop_names << plant_loop.name.to_s
      end
    end
    building = model.getBuilding
    plant_loop_handles << building.handle.to_s
    plant_loop_names << "*All Plant Loops*"
    
    #make an argument to select plant loop whose chillers to modify
    plant_loop_object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("plant_loop_object", plant_loop_handles, air_loop_display_names,true)
    plant_loop_object.setDisplayName("Choose a Plant Loop Whose Chillers to Alter.")
    plant_loop_object.setDefaultValue("*All Air Loops*") #if no air loop is chosen this will run on all air loops
    args << plant_loop_object

    #make an argument for the COP
    new_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("new_cop",true)
    new_cop.setDisplayName("New Chiller COP")
    new_cop.setDefaultValue(6.0)
    args << new_cop

    #make an argument for material and installation cost
    material_cost_per_chiller = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_per_chiller",true)
    material_cost_per_chiller.setDisplayName("Material and Installation Costs per Chiller ($).")
    material_cost_per_chiller.setDefaultValue(0.0)
    args << material_cost_per_chiller

    #make an argument for expected life
    expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
    expected_life.setDisplayName("Expected Life (whole years).")
    expected_life.setDefaultValue(20)
    args << expected_life

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
    plant_loop_object = runner.getOptionalWorkspaceObjectChoiceValue("plant_loop_object",user_arguments,model)
    new_cop = runner.getDoubleArgumentValue("new_cop",user_arguments)
    material_cost_per_chiller = runner.getDoubleArgumentValue("material_cost_per_chiller",user_arguments)
    expected_life = runner.getIntegerArgumentValue("expected_life",user_arguments)

    #check that the selected plant loop still exists
    apply_to_all_plant_loops = false
    plant_loop = nil
    if plant_loop_object.empty?
      handle = runner.getStringArgumentValue("plant_loop",user_arguments)
      if handle.empty?
        runner.registerError("No plant loop was chosen.")
      else
        runner.registerError("The selected plant loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if plant_loop_object.get.to_PlantLoop.is_initialized
        plant_loop = plant_loop_object.get.to_PlantLoop.get
      elsif not plant_loop_object.get.to_Building.empty?
        apply_to_all_plant_loops = true
      else
        runner.registerError("Script Error - argument not showing up as plant loop.")
        return false
      end
    end

    #check the COP
    if cop <= 0
      runner.registerError("Please enter a positive value for COP.")
      return false
    end
    if cop > 10
      runner.registerWarning("The requested Rated COP of #{cop} seems unusually high")
    end

    #short def to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure
    def neat_numbers(number, roundto = 2) #round to 0 or 2)
      if roundto == 2
        number = sprintf "%.2f", number
      else
        number = number.round
      end
      #regex to add commas
      number.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1,").reverse
    end #end def neat_numbers

    #set the list of plant loops whose chillers to modify
    plant_loops = []
    if apply_to_all_plant_loops
      plant_loops = model.getPlantLoops
    else
      plant_loops << plant_loop #only run on a single plant loop
    end

    #loop through plant loops, setting Chiller COPs
    chillers_modified = []
    plant_loops.each do |plant_loop|
      plant_loop.supplyComponents.each do |supply_component|
        if supply_component.to_ChillerElectricEIR.is_initialized
          chiller = supply_component.to_ChillerElectricEIR.get
        
          #change the COP and add a cost
          initial_cop = chiller.referenceCOP
          if initial_cop == new_cop
            runner.registerWarning("#{chiller.name.get} COP already equals the requested COP.  Cost will not be added for this chiller.")
          else 
            chiller.setReferenceCOP(new_cop)
            chillers_modified << chiller.name.get
            runner.registerInfo("Changed the COP from #{initial_cop.get} to #{new_cop} for '#{chiller.name}' on '#{plant_loop.name}'")
            cost = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Modified #{chiller.name} COP", chiller, material_cost_per_chiller, "CostPerEach", "Construction", expected_life, 0)
          end
        end
      end
    end

    #report if the measure does not apply to this model
    #because there were no chillers to modify
    if chillers_modified.size == 0
      runner.registerAsNotApplicable("Not Applicable - The selected loop(s) do not contain any chillers, the model will not be altered.")
      return true
    end
    
    #reporting initial condition of model
    runner.registerInitialCondition("The building has #{chillers_modified.size} chillers that could be replaced by more efficient chillers.")
    
    #reporting final condition of model
    total_cost = material_cost_per_chiller * chillers_modified.size
    runner.registerFinalCondition("#{chillers_modified.size} chillers were replaced with more efficient chillers. This was done at a cost of $#{neat_numbers(material_cost_per_chiller,0)} per chiller, for a total cost of $#{neat_numbers(total_cost,0)}.")

    return true

  end #end the cop method

end #end the measure

#this allows the measure to be used by the application
IncreaseChillerCOP.new.registerWithApplication