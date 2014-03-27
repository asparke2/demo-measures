#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class AddOAtoTyndall1060 < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddOAtoTyndall1060"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    midrise_apt_office_oa = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
    midrise_apt_office_oa.setOutdoorAirFlowperPerson(0.01076452)
    
    midrise_apt_corridor_oa = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
    midrise_apt_corridor_oa.setOutdoorAirFlowperFloorArea(0.000254)    
    
    model.getSpaceTypes.each do |space_type|
      if space_type.name.get == "Barracks room"
        space_type.setDesignSpecificationOutdoorAir(midrise_apt_office_oa)
      else
        space_type.setDesignSpecificationOutdoorAir(midrise_apt_corridor_oa)
      end
    end
 
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddOAtoTyndall1060.new.registerWithApplication