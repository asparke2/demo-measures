#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class CreateDOEReferenceBuilding < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "CreateDOEReferenceBuilding"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for the building type
    building_type_chs = OpenStudio::StringVector.new
    building_type_chs << "Midrise Apartment"
    building_type_chs << "Large Office"
    building_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_type', building_type_chs, true)
    building_type.setDisplayName("Select a Building Type.")
    building_type.setDefaultValue("Large Office")
    args << building_type

    #make an argument for the building vintage
    building_vintage_chs = OpenStudio::StringVector.new
    building_vintage_chs << "Pre-1980"
    building_vintage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_vintage', building_vintage_chs, true)
    building_vintage.setDisplayName("Select a Vintage.")
    building_vintage.setDefaultValue("Pre-1980")
    args << building_vintage    

    #make an argument for the climate zone
    climate_zone_chs = OpenStudio::StringVector.new
    climate_zone_chs << "1A"
    climate_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('climate_zone', climate_zone_chs, true)
    climate_zone.setDisplayName("Select a Climate Zone.")
    climate_zone.setDefaultValue("1A")
    args << climate_zone      
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #load some libraries to use
    @resource_path = "#{File.dirname(__FILE__)}/resources"
    require "#{@resource_path}/utilities.rb"
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables that can be accessed across the measure
    @building_type = runner.getStringArgumentValue("building_type",user_arguments)
    @building_vintage = runner.getStringArgumentValue("building_vintage",user_arguments)
    @climate_zone = runner.getStringArgumentValue("climate_zone",user_arguments)
    
    #allow the model and runner to be accessed globally
    @model = model
    @runner = runner
    @runner.registerInfo("got here")
        
    #make the building
    case @building_type
    when "Midrise Apartment"
      @runner.registerInfo("starting Midrise Apartment")
      require "#{@resource_path}/midrise_apartment.rb"
      model = MidriseApartment.new
      model = add_geometry(model)
      model = add_hvac(model)
    when "Large Office" 
      @runner.registerInfo("starting Large Office")
      require "#{@resource_path}/large_office.rb"
      model = add_geometry(model)
      #model = add_loads(model) TODO replace with version not requiring json gem
      model = add_hvac(model)
      @runner.registerInfo("plant loops = #{model.getPlantLoops.size}")
      @runner.registerInfo("air loops = #{model.getAirLoopHVACs.size}")
    else
      @runner.registerError("Building Type = #{@building_type} not recognized")
    end
    
    model.save(OpenStudio::Path.new("#{Dir.pwd}/output_model.osm"), true)
    
    runner = @runner
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
CreateDOEReferenceBuilding.new.registerWithApplication