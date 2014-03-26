#start the measure
class ApplyCodeSpaceType < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see
  def name
    return "Apply Code Space Type"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    model.getSpaceTypes.each do |space_type|
    
      #define the choices
      choices = []
      choices << "open office"
      choices << "corridor"
      choices << "enclosed office"
      choices << "mechanical room"
      
      #make a choice argument for space type
      code_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("#{space_type.name}", choices)
      code_space_type.setDisplayName("#{space_type.name}")
      code_space_type.setDefaultValue("open office")
      args << code_space_type

    end
    
    return args
  end #end the arguments method
  
  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    
    model.getSpaceTypes.each do |space_type|
    
      #assign the user input to a variable
      code_space_type = runner.getOptionalWorkspaceObjectChoiceValue("#{space_type.name}",user_arguments,model)    
    
      #delete the lights in the existing space type
      space_type.lights.each do |light|
        light.remove
      end
      
      
      #assign new lights depending on the user input
      #create a lights definition
      code_lights_def = OpenStudio::Model::LightsDefinition.new(model)
      code_lights_def.setName("#{code_space_type}")
      case code_space_type
      when "open office"
        code_lights_def.setWattsperSpaceFloorArea(11.0) #W/m^2
      when "corridor"
        code_lights_def.setWattsperSpaceFloorArea(11.0) #W/m^2
      when "enclosed office"
        code_lights_def.setWattsperSpaceFloorArea(11.0) #W/m^2
      when "mechanical room"
        code_lights_def.setWattsperSpaceFloorArea(11.0) #W/m^2
      end
    
    end
    
    return true

  end #end the run method
  
end #end the measure

#this allows the measure to be used by the application
ApplyCodeSpaceType.new.registerWithApplication