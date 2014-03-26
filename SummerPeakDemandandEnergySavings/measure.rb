#start the measure
class SummerPeakDemandandEnergySavings < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SummerPeakDemandandEnergySavings"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #Choose Measure Application
	measure_application_chs = OpenStudio::StringVector.new
	#measure_application_chs << "New"
	measure_application_chs << "Retrofit"
	measure_application = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('measure_application',measure_application_chs,true)
	measure_application.setDefaultValue("Retrofit")
	measure_application.setDisplayName("Choose Measure Application Type")
	args << measure_application
	
	#Specify building size (only necessary if building is present in both size categories)
	building_size_chs = OpenStudio::StringVector.new
	building_size_chs << "Small"
	building_size_chs << "Large"
	building_size_chs << "Not Applicable"
	building_size = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_size',building_size_chs,true)
	building_size.setDisplayName("Choose your building size")
	args << building_size
	
	#Choose Facility Type
	facility_type_chs = OpenStudio::StringVector.new
	facility_type_chs << "Auto Related"
	facility_type_chs << "Bakery"
	facility_type_chs << "Banks"
	facility_type_chs << "Church"
	facility_type_chs << "College - Cafeteria"
	facility_type_chs << "College - Dormitory"
	facility_type_chs << "Commercial Condos"
	facility_type_chs << "Convenience Stores"
	facility_type_chs << "Convention Center"
	facility_type_chs << "Court House"
	facility_type_chs << "Dining: Bar Lounge/Leisure"
	facility_type_chs << "Dining: Cafeteria/Fast Food"
	facility_type_chs << "Dining: Family"
	facility_type_chs << "Entertainment"
	facility_type_chs << "Exercise Center"
	facility_type_chs << "Fast Food Restaurants"
	facility_type_chs << "Fire Station (Unmanned)"
	facility_type_chs << "Food Stores"
	facility_type_chs << "Gymnasium"
	facility_type_chs << "Hospitals"
	facility_type_chs << "Hospitals/Health Care"
	facility_type_chs << "Industrial - 1 Shift"
	facility_type_chs << "Industrial - 2 Shift"
	facility_type_chs << "Industrial - 3 Shift"
	facility_type_chs << "Laundromats"
	facility_type_chs << "Library"
	facility_type_chs << "Light Manufacturers"
	facility_type_chs << "Lodging (Hotels)"
	facility_type_chs << "Lodging (Motels)"
	facility_type_chs << "Mall Concourse"
	facility_type_chs << "Manufacturing Facility"
	facility_type_chs << "Medical Offices"
	facility_type_chs << "Motion Picture Theatre"
	facility_type_chs << "Multi-Family High-rise"
	facility_type_chs << "Multi-Family Low-rise"
	facility_type_chs << "Multi-Family (Common Areas)"
	facility_type_chs << "Museum"
	facility_type_chs << "Nursing Homes"
	facility_type_chs << "Office (Large)"
	facility_type_chs << "Office (Small)"
	facility_type_chs << "Office/Retail (Large)"
	facility_type_chs << "Office/Retail (Small)"
	facility_type_chs << "Parking Garages"
	facility_type_chs << "Parking Lots"
	facility_type_chs << "Performing Arts Theatre"
	facility_type_chs << "Police/Fire Stations (24 hrs)"
	facility_type_chs << "Post Office"
	facility_type_chs << "Pump Stations"
	facility_type_chs << "Refrigerated Warehouse"
	facility_type_chs << "Religious Building"
	facility_type_chs << "Restaurants"
	facility_type_chs << "Retail (Large)"
	facility_type_chs << "Retail (Small)"
	facility_type_chs << "Schools/University"
	facility_type_chs << "Schools (Jr./Sr. High)"
	facility_type_chs << "Schools (Preschool/Elementary)"
	facility_type_chs << "Schools (Technical/Vocational)"
	facility_type_chs << "Single Family Residential"
	facility_type_chs << "Small Services"
	facility_type_chs << "Sports Arena"
	facility_type_chs << "Town Hall"
	facility_type_chs << "Transportation"
	facility_type_chs << "Warehouse (Not Refrigerated)"
	facility_type_chs << "Waste Water Treatment Plant"
	facility_type_chs << "Workshop"
	facility_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('facility_type',facility_type_chs,true)
	facility_type.setDisplayName("Choose a facility type that best reflects your building")
	args << facility_type
	
	#Choose Facility Type
#	facility_type_chs = OpenStudio::StringVector.new
#	facility_type_chs << "Museum"
#	facility_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('facility_type',facility_type_chs,true)
#	facility_type.setDisplayName("Choose a facility type that best reflects your building")
#	args << facility_type
	
	#Choose City
	city_chs = OpenStudio::StringVector.new
	city_chs << "Albany"
	city_chs << "Binghamton"
	city_chs << "Buffalo"
	city_chs << "Massena"
	city_chs << "NYC"
	city_chs << "Poughkeepsie"
	city_chs << "Syracuse"
	city = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('city',city_chs,true)
	city.setDisplayName("Choose the city that your building resides within")
	args << city
	
	#Choose HVAC System
	hvac_system_chs = OpenStudio::StringVector.new
	hvac_system_chs << "AC with gas heat (Small)"
	hvac_system_chs << "Heat Pump (Small)"
	hvac_system_chs << "AC with electric heat (Small)"
	hvac_system_chs << "Electric heat only (Small)"
	hvac_system_chs << "Gas heat only (Small)"
	hvac_system_chs << "CV Noecon (Large)"
	hvac_system_chs << "CV Econ (Large)"
	hvac_system_chs << "VAV Econ (Large)"
	hvac_system_chs << "Fan coil with chiller and hot water boiler (Multifamily High-rise and College - Dormitory)"
	hvac_system_chs << "Steam heat only (Multifamily High-rise and College - Dormitory)"
	hvac_system_chs << "Water Cooled Ammonia Screw Compressors (Refrigerated Warehouse)"
	hvac_system = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('hvac_system',hvac_system_chs,true)
	hvac_system.setDisplayName("Choose an HVAC system for your building")
	args << hvac_system

	#Enter Watts of base building
	watts_base = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('watts_base',true)
	watts_base.setDisplayName("Enter the Watts value of your base building")
	args << watts_base
	
	#Enter Units of base building
	units_base = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('units_base',true)
	units_base.setDisplayName("Enter the Units value of your base building")
	args << units_base
	
	#Enter Watts of improved building
	watts_improved = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('watts_improved',true)
	watts_improved.setDisplayName("Enter the Watts value of your improved building")
	args << watts_improved
	
	#Enter Units of improved building
	units_improved = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('units_improved',true)
	units_improved.setDisplayName("Enter the Units value of your improved building")
	args << units_improved
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    #assign the user inputs to variables
	measure_application = runner.getStringArgumentValue("measure_application",user_arguments)
	building_size = runner.getStringArgumentValue("building_size",user_arguments)
	facility_type = runner.getStringArgumentValue("facility_type",user_arguments)
	city = runner.getStringArgumentValue("city",user_arguments)
	hvac_system = runner.getStringArgumentValue("hvac_system",user_arguments)
	watts_base = runner.getDoubleArgumentValue("watts_base",user_arguments)
	units_base = runner.getDoubleArgumentValue("units_base",user_arguments)
	watts_improved = runner.getDoubleArgumentValue("watts_improved",user_arguments)
	units_improved = runner.getDoubleArgumentValue("units_improved",user_arguments)

	#Check to ensure that the user did not input an incorrect arrangement of choices
	if building_size == "Small" and facility_type != "Auto Related" and facility_type != "Bakery" and facility_type != "Banks" and facility_type != "Church" and facility_type != "College - Cafeteria" and facility_type != "Commercial Condos" and facility_type != "Convenience Stores" and facility_type != "Dining: Bar Lounge/Leisure" and facility_type != "Dining: Cafeteria / Fast Food" and facility_type != "Dining: Family" and facility_type != "Entertainment" and facility_type != "Exercise Center" and facility_type != "Fast Food Restaurants" and facility_type != "Fire Station (Unmanned)" and facility_type != "Food Stores" and facility_type != "Gymnasium" and facility_type != "Laundromats" and facility_type != "Lodging (Hotels)" and facility_type != "Lodging (Motels)" and facility_type != "Medical Offices" and facility_type != "Motion Picture Theatre" and facility_type != "Museum" and facility_type != "Office (Small)" and facility_type != "Performing Arts Theatre" and facility_type != "Police / Fire Stations (24 Hr)" and facility_type != "Post Office" and facility_type != "Religious Building" and facility_type != "Restaurants" and facility_type != "Retail (Small)" and facility_type != "Small Services" and facility_type != "Sports Arena" and facility_type != "Town Hall" and facility_type != "Transportation" and facility_type != "Warehouse (Not Refrigerated)"
		runner.registerError("The Building Size and Facility Type inputs are not a valid combination. Change inputs to appropriate values and rerun the simulation (1)")
	elsif building_size == "Large" and (facility_type == "Auto Related" or facility_type == "Bakery" or facility_type == "Banks" or facility_type == "Church" or facility_type == "College - Cafeteria" or facility_type == "Commercial Condos" or facility_type == "Convenience Stores" or facility_type == "Dining: Bar Lounge/Leisure" or facility_type == "Dining: Cafeteria / Fast Food" or facility_type == "Dining: Family" or facility_type == "Entertainment" or facility_type == "Exercise Center" or facility_type == "Fast Food Restaurants" or facility_type == "Fire Station (Unmanned)" or facility_type == "Food Stores" or facility_type == "Gymnasium" or facility_type == "Laundromats" or facility_type == "Lodging (Hotels)" or facility_type == "Lodging (Motels)" or facility_type == "Medical Offices" or facility_type == "Motion Picture Theatre" or facility_type == "Museum" or facility_type == "Office (Small)" or facility_type == "Performing Arts Theatre" or facility_type == "Police / Fire Stations (24 Hr)" or facility_type == "Post Office" or facility_type == "Religious Building" or facility_type == "Restaurants" or facility_type == "Retail (Small)" or facility_type == "Small Services" or facility_type == "Sports Arena" or facility_type == "Town Hall" or facility_type == "Transportation" or facility_type == "Warehouse (Not Refrigerated)" or facility_type == "Single Family Residential" or facility_type == "Multi-Family Low-rise" or facility_type == "Multi-Family High-rise" or facility_type == "College - Dormitory" or facility_type == "Refrigerated Warehouse")
		runner.registerError("The Building Size and Facility Type inputs are not a valid combination. Change inputs to appropriate values and rerun the simulation (2)")
	elsif building_size == "Not Applicable" and facility_type != "Single Family Residential" and facility_type != "Multi-Family Low-rise" and facility_type != "Multi-Family High-rise" and facility_type != "College - Dormitory" and facility_type != "Refrigerated Warehouse"
		runner.registerError("The Building Size and Facility Type inputs are not a valid combination. Change inputs to appropriate values and rerun the simulation (3)")
	end
	
	###getting data from a resource .xml file###
	
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
    if facility_types.elements["facility_type[name='#{facility_type}']"]
      ltg_hrs = facility_types.elements["facility_type[name='#{facility_type}']"].get_elements("lighting_hours").first.text
      hvac_int = facility_types.elements["facility_type[name='#{facility_type}']"].get_elements("hvac_int").first.text
    else
      runner.registerError("could not find a facility_type named #{facility_type}")
      return false
    end
	
	#show the user the results of the lookups
    runner.registerInfo("building type #{facility_type} has #{ltg_hrs} lighting hours")
	
	#find the hvacc, hvacd, and hvacg values based on hvac_int and building city
	hvacc = nil
	hvacd = nil
	hvacg = nil
	if hvac_ints.elements["hvac_int[name='#{hvac_int}']"] and hvac_ints.elements["city[name='#{city}']"]
		if hvac_system == "AC with gas heat (Small)" or hvac_system == "CV Noecon (Large)" or hvac_system == "Fan coil with chiller and hot water boiler (Multifamily High-rise and College - Dormitory)" or hvac_system == "Water Cooled Ammonia Screw Compressors (Refrigerated Warehouse)"
			hvacc = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacc1").first.text
			hvacd = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacd1").first.text
			hvacg = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacg1").first.text
		elsif hvac_system == "Heat Pump (Small)" or hvac_system == "CV Econ (Large)" or hvac_system == "Steam heat only (Multifamily High-rise and College - Dormitory)"
			hvacc = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacc2").first.text
			hvacd = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacd2").first.text
			hvacg = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacg2").first.text
		elsif hvac_system == "AC with electric heat (Small)" or hvac_system == "VAV Econ (Large)"
			hvacc = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacc3").first.text
			hvacd = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacd3").first.text
			hvacg = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacg3").first.text
		elsif hvac_system == "Electric heat only (Small)"
			hvacc = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacc4").first.text
			hvacd = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacd4").first.text
			hvacg = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacg4").first.text
		elsif hvac_system == "Gas heat only (Small)"
			hvacc = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacc5").first.text
			hvacd = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacd5").first.text
			hvacg = hvac_ints.elements["hvac_int[name='#{hvac_int}']"].elements["city[name='#{city}']"].get_elements("hvacg5").first.text
		end		
	else
		runner.registerError("The combination of values you entered is either invalid or missing from the table. See Model Description for a list of correct combinations")
		return false
	end
	
	#show the user the results of the lookups
    runner.registerInfo("The following values were recovered: hvacc=#{hvacc} hvacd=#{hvacd} hvacg=#{hvacg}")
	
	
	#Undergo method for Calculating Summer Peak Demand and Energy Savings (Retrofit)
	deltakWs = ((((watts_base*units_base)-(watts_improved*units_improved))/1000)*(1+hvacd.to_f))
	if deltakWs < 0
		runner.registerWarning("deltakWs is less than zero")
	else runner.registerInfo("deltakWs = #{deltakWs}")
	end
	
	deltakWh = ((((watts_base*units_base)-(watts_improved*units_improved))/1000)*ltg_hrs.to_f*(1+hvacc.to_f))
	if deltakWh < 0
		runner.registerWarning("deltakWh is less than zero")
	else runner.registerInfo("deltakWh = #{deltakWh}")
	end
	
	deltatherm = (deltakWh*(0-hvacg.to_f))
	runner.registerInfo("deltatherm = #{deltatherm}")
	if deltatherm < 0
		runner.registerWarning("deltatherm less than zero")
	end
	
	return true
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
SummerPeakDemandandEnergySavings.new.registerWithApplication