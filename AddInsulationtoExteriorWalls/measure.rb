#start the measure
class AddInsulationtoExteriorWalls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Add Insulation to Exterior Walls"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    
    #make a choice argument for construction to add insulation to
    construction_handles = OpenStudio::StringVector.new
    construction_names = OpenStudio::StringVector.new
    model.getConstructions.each do |construction|
      if not construction.isFenestration and not construction.getNetArea == 0
        construction_handles << construction.handle.to_s
        construction_names << construction.name.get
      end
    end
    construction_to_add_ins_onto = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("construction_to_add_ins_onto", construction_handles, construction_names,true)
    construction_to_add_ins_onto.setDisplayName("Construction to Add Insulation To.")
    args << construction_to_add_ins_onto    
    
    #make an argument insulation R-value
    r_value_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("r_value_ip",true)
    r_value_ip.setDisplayName("Insulation R-value (ft^2*h*R/Btu) (R-8.8 = 1.5in insulation).")
    r_value_ip.setDefaultValue(8.8)
    args << r_value_ip

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
    construction_to_add_ins_onto = runner.getOptionalWorkspaceObjectChoiceValue("construction_to_add_ins_onto",user_arguments,model)
    r_value_ip = runner.getDoubleArgumentValue("r_value_ip",user_arguments)
    material_cost_per_area_ip = runner.getDoubleArgumentValue("material_cost_per_area_ip",user_arguments)

    #check to make sure the selected construction is still in the model
    if construction_to_add_ins_onto.empty?
      handle = runner.getStringArgumentValue("construction_to_add_ins_onto",user_arguments)
      if handle.empty?
        runner.registerError("No construction was chosen.")
      else
        runner.registerError("The selected construction was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not construction_to_add_ins_onto.get.to_Construction.empty?
        construction_to_add_ins_onto = construction_to_add_ins_onto.get.to_Construction.get
      else
        runner.registerError("Script Error - argument not showing up as construction.")
        return false
      end
    end
      
    #check the R-value for reasonableness
    if r_value_ip < 0 or r_value_ip > 100
      runner.registerError("The requested wall insulation R-value of #{r_value_ip} ft^2*h*R/Btu is not realistic.")
      return false
    elsif r_value_ip > 20
      runner.registerWarning("The requested wall insulation R-value of #{r_value_ip} ft^2*h*R/Btu is abnormally high.")
    elsif r_value_ip < 2
      runner.registerWarning("The requested wall insulation R-value of #{r_value_ip} ft^2*h*R/Btu is abnormally low.")
    end

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
    
    #convert r_value_ip and material_cost to si for future use
    r_value_si = OpenStudio::convert(r_value_ip, "ft^2*h*R/Btu","m^2*K/W").get
    material_cost_per_area_si = OpenStudio::convert(material_cost_per_area_ip,"1/ft^2","1/m^2").get
    
    #create a material for polyisocyanurate insulation
    # https://bcl.nrel.gov/node/34449
    # Cellular Polyurethane or Polyisocyanurate - Unfaced - 1 1/2 in.,  ! Name
    # Rough,                    ! Roughness
    # 0.0381,                   ! Thickness {m}
    # 0.0245,                   ! Conductivity {W/m-K}
    # 24,                       ! Density {kg/m3}
    # 1590;                     ! Specific Heat {J/kg-K}
    ins_layer = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ins_layer.setRoughness("Rough")
    ins_layer.setConductivity(0.0245)
    ins_layer.setDensity(24.0)
    ins_layer.setSpecificHeat(1590.0)
    #calculate the thickness required to meet the desired R-Value
    reqd_thickness_si = r_value_si * ins_layer.thermalConductivity
    reqd_thickness_ip = OpenStudio::convert(reqd_thickness_si, "m", "in").get
    runner.registerInfo("To achieve an R-Value of #{r_value_ip} you need #{neat_numbers(reqd_thickness_ip,2)}in of Polyisocyanurate insulation.")
    
    #copy the selected construction and add the layer of insulation
    construction_plus_ins = construction_to_add_ins_onto.clone(model).to_Construction.get
    construction_plus_ins.insertLayer(0,ins_layer)
    
    #add a cost to the new construction
    cost_for_adding_ins = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("Cost for adding #{reqd_thickness_ip}in ins to  #{construction_to_add_ins_onto.name.get}",
                                                                              construction_plus_ins,
                                                                              material_cost_per_area_si,
                                                                              "CostPerArea",
                                                                              "Construction",
                                                                              25,
                                                                              0).get
                                                                              
    #find all exterior walls that use the original construction and
    #replace with the clone of this construction with added insulation
    area_of_insulation_added_si = 0
    model.getSurfaces.each do |surface|
      if surface.outsideBoundaryCondition == "Outdoors" and surface.surfaceType == "Wall"
        if surface.construction.is_initialized
          if surface.construction.get == construction_to_add_ins_onto
            surface.setConstruction(construction_plus_ins)
            area_of_insulation_added_si += surface.netArea
          end 
        end
      end
    end

    #this measure is not applicable if there are no exterior walls that used
    #the selected construction
    if area_of_insulation_added_si == 0
      runner.registerAsNotApplicable("Not Applicable - Model does not have any exterior walls that use the construction #{construction_to_add_ins_onto.name.get}.")
      return true
    end

    #double-check that the impacted area is the same as what OS calculates automatically
    if area_of_insulation_added_si != construction_plus_ins.getNetArea
      runner.registerError("OS calculated #{construction_plus_ins.getNetArea}m^2 of the new construction used; the measure calculated #{area_of_insulation_added_si}m^2.  Something is wrong.")
      return false
    end
    
    #convert affected area to ft^2 for reporting
    area_of_insulation_added_ip = OpenStudio::convert(area_of_insulation_added_si,"m^2","ft^2").get
    
    #report the initial condition
    runner.registerInitialCondition("The building has #{neat_numbers(area_of_insulation_added_ip,0)}ft^2 of #{construction_to_add_ins_onto.name.get} exterior walls.")

    #report the final condition
    total_cost = material_cost_per_area_ip * area_of_insulation_added_ip
    runner.registerFinalCondition("#{neat_numbers(reqd_thickness_ip,2)}in of insulation has been applied to #{neat_numbers(area_of_insulation_added_ip,0)}ft^2 of these exterior walls.  This was done at a cost of $#{neat_numbers(material_cost_per_area_ip,0)}/ft^2, for a total cost of $#{neat_numbers(total_cost,0)}.")
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
AddInsulationtoExteriorWalls.new.registerWithApplication
