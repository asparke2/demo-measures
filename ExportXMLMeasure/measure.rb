#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ExportXMLMeasure < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ExportXMLMeasure"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #Choose a building type
    bldg_type_chs = OpenStudio::StringVector.new
    bldg_type_chs << "Bakery"
    bldg_type_chs << "Ant Farm (not a real building type)"
    bldg_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('bldg_type',bldg_type_chs,true)
    bldg_type.setDefaultValue("Bakery")
    bldg_type.setDisplayName("Choose Building Type")
    args << bldg_type
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #get the user arguments
    bldg_type = runner.getStringArgumentValue("bldg_type",user_arguments)
    
    ##############getting data from a resource .xml file#####################
    
    #load the ruby xml parser library
    require "rexml/document"

    #load the resource file called "resource.xml"
    resource_path = File.new("#{File.dirname(__FILE__)}/resource.xml")
    resource_xml = REXML::Document.new(resource_path)

    #get the top level element, called "resources"
    resources = resource_xml.get_elements("resources").first

    #get the facility_types element. think of this as the facility types table
    facility_types = resources.get_elements("facility_types").first

    #get the hvac_ints element. think of this as the hvac ints table
    hvac_ints = resources.get_elements("hvac_ints").first

    #find the lighting hours and hvac int for this specific building type
    ltg_hrs = nil
    hvac_int = nil
    if facility_types.elements["facility_type[name='#{bldg_type}']"]
      ltg_hrs = facility_types.elements["facility_type[name='#{bldg_type}']"].get_elements("lighting_hours").first.text
      hvac_int = facility_types.elements["facility_type[name='#{bldg_type}']"].get_elements("hvac_int").first.text
    else
      runner.registerError("could not find a facility_type named #{bldg_type}")
      return false
    end

    #get the coefficient from the hvac int for this building
    coef_1 = nil
    if hvac_ints.elements["hvac_int[name='#{hvac_int}']"]
      coef_1 = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].get_elements("coef_1").first.text
    else
      runner.registerError("could not find an hvac int named #{hvac_int}")
      return false
    end
    
    #show the user the results of the lookups
    runner.registerInfo("building type #{name} has #{ltg_hrs} lighting hours and an hvac coef_1 of #{coef_1}")
    
    ##############appending some results to an external .xml file#####################
    results_file = nil
    results_xml = nil
    results_path = "C:/Users/aparker/Desktop/results.xml"
    if File.exists?(results_path)
      puts "file exists"
      results_file = File.read(results_path) #read the existing file
      results_xml = REXML::Document.new(results_file) #convert contents to xml document
    else
      puts "file doesn't exist; creating new"
      results_file = File.open(results_path, 'w') #create a new file
      results_file.close #close the file
      results_file = File.read(results_path) #reopen the file in read mode
      results_xml = REXML::Document.new(results_file) #read the file in
    end
    
    #numbers for measure results get calc'd
    kwh_saved = 100000.0
    kw_saved = 500.0
    therms_saved = 2000.0
    
    #the results.xml file structure will look like this:
    #results
    #  alternative
    #       name
    #       measure
    #         name
    #         kwh_saved
    #         kw_saved
    #         therms_saved
    #       measure
    #         name
    #         kwh_saved
    #         kw_saved
    #         therms_saved    
    
    #create a not top-level element called "results" if it doesn't exist
    results = nil
    if results_xml.get_elements("results").first
      results = results_xml.get_elements("results").first
    else
      results = results_xml.add_element("results")
    end

    
    #get the name of this alternative
    #TODO how do we get this?
    model_name = "model A"
    
    #create an element for this alternative, if it doesn't exist
    alt = nil
    if results.elements["alternative[name='#{model_name}']"]
      alt = results.elements["alternative[name='#{model_name}']"]
    else
      alt = results.add_element("alternative")
      alt_name = alt.add_element("name")
      alt_name.add_text(model_name)
    end       
    
    #add a measure to this alternative
    measure = alt.add_element("measure")
    measure_name = measure.add_element("name")
    measure_name.add_text("measure xyz")
    measure_kwh_saved = measure.add_element("kwh_saved")
    measure_kwh_saved.add_text("#{kwh_saved}")
    measure_kw_saved = measure.add_element("kw_saved")
    measure_kw_saved.add_text("#{kw_saved}")
    measure_therms_saved = measure.add_element("therms_saved")
    measure_therms_saved.add_text("#{therms_saved}")

    #write the xml to the file
    results_file = File.open(results_path, 'w') #open the file for writing
    results_xml.write(results_file) #write the xml doc to the file
    results_file.close #close the file

    
    ############adding the incentive to the building LCC#####################
    incentive_name = "example incentive"
    incentive_value = -10000.00 #negative cost because this is an incentive
    incentive_type = "CostPerEach" #a single incentive, attached to the building
    incentive_category = "Construction" # incentive will show up in the Construction column (vs. operation, maintenance, etc)
    incentive_repeat_years = 0 #incentive happens 1 time
    years_until_incentive_paid = 0 #incentive part of first year capital construction costs
    
    incentive = OpenStudio::Model::LifeCycleCost.createLifeCycleCost(incentive_name,
                                                                    model.building.get,
                                                                    incentive_value,
                                                                    incentive_type,
                                                                    incentive_category,
                                                                    incentive_repeat_years,
                                                                    years_until_incentive_paid)
                          
    runner.registerInfo("incentive of #{incentive_value} was removed from the initial construction cost")                          
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ExportXMLMeasure.new.registerWithApplication