#start the measure
class ReplaceExteriorWindows < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Replace Exterior Windows"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for window construction to replace
    construction_to_replace_handles = OpenStudio::StringVector.new
    construction_to_replace_names = OpenStudio::StringVector.new
    model.getConstructions.each do |construction|
      if construction.isFenestration and not construction.getNetArea == 0
        construction_to_replace_handles << construction.handle.to_s
        construction_to_replace_names << construction.name.get
      end
    end
    construction_to_replace = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("construction_to_replace", construction_to_replace_handles, construction_to_replace_names,true)
    construction_to_replace.setDisplayName("Construction Being Replaced.")
    args << construction_to_replace    

    #make a choice argument for the new window construction
    new_construction_handles = OpenStudio::StringVector.new
    new_construction_names = OpenStudio::StringVector.new
    model.getConstructions.each do |construction|
      if construction.isFenestration
        new_construction_handles << construction.handle.to_s
        new_construction_names << construction.name.get
      end
    end
    new_construction = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("new_construction", new_construction_handles, new_construction_names,true)
    new_construction.setDisplayName("Replacement Construction.")
    args << new_construction    

    #make an argument for material and installation cost
    material_cost_per_area_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_per_area_ip",true)
    material_cost_per_area_ip.setDisplayName("Material and Installation Costs per Area ($/ft^2).")
    material_cost_per_area_ip.setDefaultValue(0.0)
    args << material_cost_per_area_ip
  
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
    construction_to_replace = runner.getOptionalWorkspaceObjectChoiceValue("construction_to_replace",user_arguments,model)
    new_construction = runner.getOptionalWorkspaceObjectChoiceValue("new_construction",user_arguments,model)
    material_cost_per_area_ip = runner.getDoubleArgumentValue("material_cost_per_area_ip",user_arguments)

    #check to make sure the construction to replace is still in the model
    if construction_to_replace.empty?
      handle = runner.getStringArgumentValue("construction_to_replace",user_arguments)
      if handle.empty?
        runner.registerError("No construction was chosen.")
      else
        runner.registerError("The selected construction was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not construction_to_replace.get.to_Construction.empty?
        construction_to_replace = construction_to_replace.get.to_Construction.get
      else
        runner.registerError("Script Error - argument not showing up as construction.")
        return false
      end
    end

    #check to make sure the new construction is still in the model
    if new_construction.empty?
      handle = runner.getStringArgumentValue("new_construction",user_arguments)
      if handle.empty?
        runner.registerError("No construction was chosen.")
      else
        runner.registerError("The selected construction was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not new_construction.get.to_Construction.empty?
        new_construction = new_construction.get.to_Construction.get
      else
        runner.registerError("Script Error - argument not showing up as construction.")
        return false
      end
    end

    #convert material cost to si for future use
    material_cost_per_area_si = OpenStudio::convert(material_cost_per_area_ip,"1/ft^2","1/m^2").get
    
    #copy the new construction
    #the copy will be assigned to the replacement
    #in case this construction was already used elsewhere in the model
    replacement_construction = new_construction.clone(model).to_Construction.get
    replacement_construction.setName("Copy of #{new_construction.name.get}")
    #add a cost to the replacement construction
    cost_for_replacing_windows = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Cost for replacing #{construction_to_replace.name.get} with  #{replacement_construction.name.get}",
                                                                              replacement_construction,
                                                                              material_cost_per_area_si,
                                                                              "CostPerArea",
                                                                              "Construction",
                                                                              25,
                                                                              0).get
                                                                         
    #short def to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). 
    #this method is used through the measure
    def neat_numbers(number, roundto = 2) #round to 0 or 2)
      if roundto == 2
        number = sprintf "%.2f", number
      else
        number = number.round
      end
      #regex to add commas
      number.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1,").reverse
    end #end def neat_numbers
                                                                              
    #find all exterior windows that use the original construction and
    #replace with the replacement construction
    area_of_windows_replaced_si = 0
    model.getSubSurfaces.each do |sub_surface|
      if sub_surface.outsideBoundaryCondition == "Outdoors" and (sub_surface.subSurfaceType == "FixedWindow" or sub_surface.subSurfaceType == "OperableWindow")
        if sub_surface.construction.is_initialized
          if sub_surface.construction.get == construction_to_replace
            sub_surface.setConstruction(replacement_construction)
            area_of_windows_replaced_si += sub_surface.netArea
          end 
        end
      end
    end

    #this measure is not applicable if there are no exterior windows that used
    #the selected construction
    if area_of_windows_replaced_si == 0
      runner.registerAsNotApplicable("Not Applicable - Model does not have any exterior windows that use the construction #{construction_to_replace.name.get}.")
      return true
    end

    #double-check that the impacted area is the same as what OS calculates automatically
    if area_of_windows_replaced_si != replacement_construction.getNetArea
      runner.registerError("OS calculated #{replacement_construction.getNetArea}m^2 of the new construction used; the measure calculated #{area_of_windows_replaced_si}m^2.  Something is wrong.")
      return false
    end
    
    #convert affected area to ft^2 for reporting
    area_of_windows_replaced_ip = OpenStudio::convert(area_of_windows_replaced_si,"m^2","ft^2").get
    
    #report the initial condition
    runner.registerInitialCondition("The building has #{neat_numbers(area_of_windows_replaced_ip,0)}ft^2 of #{construction_to_replace.name.get} exterior windows.")

    #report the final condition
    total_cost = material_cost_per_area_ip * area_of_windows_replaced_ip
    runner.registerFinalCondition("#{neat_numbers(area_of_windows_replaced_ip,0)}ft^2 of these windows have been replaced with #{new_construction.name.get} windows.  This was done at a cost of $#{neat_numbers(material_cost_per_area_ip,0)}/ft^2, for a total cost of $#{neat_numbers(total_cost,0)}.")
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
ReplaceExteriorWindows.new.registerWithApplication
