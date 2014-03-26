#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ScaleBuildingSize < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ScaleBuildingSize"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for the X direction scale
    x_scale = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("x_scale",true)
    x_scale.setDisplayName("X-dimension scale")
    x_scale.setDefaultValue(1.0)
    args << x_scale

    #make an argument for the Y direction scale
    y_scale = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("y_scale",true)
    y_scale.setDisplayName("Y-dimension scale")
    y_scale.setDefaultValue(1.0)
    args << y_scale

    #make an argument for the Z direction scale
    z_scale = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("z_scale",true)
    z_scale.setDisplayName("Z-dimension scale")
    z_scale.setDefaultValue(1.0)
    args << z_scale    
      
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
    x_scale = runner.getDoubleArgumentValue("x_scale",user_arguments)
    y_scale = runner.getDoubleArgumentValue("y_scale",user_arguments)
    z_scale = runner.getDoubleArgumentValue("z_scale",user_arguments)
    
    #check the user_name for reasonableness
    if x_scale <= 0 or y_scale <= 0 or z_scale <= 0
      runner.registerError("X, Y, and Z scale values must all be > 0")
      return false
    end 
 
    #report the initial building area
    if model.building.is_initialized
      initial_building_area = OpenStudio::convert(model.building.get.floorArea,"m^2","ft^2").get
      runner.registerInitialCondition("The building floor area started at #{initial_building_area} ft^2.")
    end
 
    model.getPlanarSurfaces.each do |surface|
      new_vertices = OpenStudio::Point3dVector.new
      surface.vertices.each do |vertex|
        new_vertices << OpenStudio::Point3d.new(vertex.x * x_scale, vertex.y * y_scale, vertex.z * z_scale)
      end    
      surface.setVertices(new_vertices)
    end
 
    model.getPlanarSurfaceGroups.each do |surface_group|
      transformation = surface_group.transformation
      translation = transformation.translation
      euler_angles = transformation.eulerAngles
      new_translation = OpenStudio::Vector3d.new(translation.x * x_scale, translation.y * y_scale, translation.z * z_scale)
      #TODO these might be in the wrong order
      new_transformation = OpenStudio::createRotation(euler_angles) * OpenStudio::createTranslation(new_translation) 
      surface_group.setTransformation(new_transformation)
    end
    
    #report the final building area
    if model.building.is_initialized
      final_building_area = OpenStudio::convert(model.building.get.floorArea,"m^2","ft^2").get
      runner.registerFinalCondition("The building floor area ended at #{final_building_area} ft^2.")
    end 

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ScaleBuildingSize.new.registerWithApplication