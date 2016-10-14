# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class VAVTerminalReverseToReverseWithLimits < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "VAV Terminal Reverse to ReverseWithLimits"
  end

  # human readable description
  def description
    return "Changes all AirTerminalSingleDuctVAVReheat Damper Heating Action fields in model from Reverse to ReverseWithLimits.  This is to address an issue identified with OS 1.12.0 to 1.13.0 updates:  https://github.com/NREL/OpenStudio/issues/2372"
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end 

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    # get all air terminals in the starting model
    vav_terms = workspace.getObjectsByType("AirTerminal:SingleDuct:VAV:Reheat".to_IddObjectType)

    # reporting initial condition of model
    runner.registerInitialCondition("The building started with #{vav_terms.size} VAV terminals.")

    # Change from Reverse to ReverseWithLimits
    terms_changed = 0
    vav_terms.each do |term|
      orig_htg_action = term.getString(15).get
      if orig_htg_action == 'Reverse'
        terms_changed += 1
        term.setString(15, 'ReverseWithLimits')
        runner.registerInfo("'#{term.getString(0)}' Damper Heating Action changed from 'Reverse' to 'ReverseWithLimits'.")
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The Damper Heating Action in #{terms_changed} VAV terminals was changed from 'Reverse' to 'ReverseWithLimits'.")
    
    return true
 
  end

end 

# register the measure to be used by the application
VAVTerminalReverseToReverseWithLimits.new.registerWithApplication
