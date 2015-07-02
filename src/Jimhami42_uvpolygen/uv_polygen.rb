# encoding: UTF-8
# uv_polygen.rb
#{ ===========================================================================
#  DETAILS:
#
#  U-V Polygon Mesh Generator Plugin for SketchUp with Offset Surfaces.
#
# ----------------------------------------------------------------------------
#  COPYRIGHT(S):
#
#  (C) 2014 by Jim Hamilton (Jimhami42 at GitHub.com)
#  (C) 2015 by Daniel A. Rathbun
#
# ----------------------------------------------------------------------------
#  DISCLAIMER OF WARRANTY:
#
#  THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# ----------------------------------------------------------------------------
#  TERMS OF USE:
#
#  Released under the MIT License, which basically says:
#    Permission granted to freely use this code as long as these terms and 
#    the copyright lines are included in any derivative work(s). ~JRH
#
# ----------------------------------------------------------------------------
#  REVISIONS & RELEASES:  see "Jimhami42_uvpolygen/uv_polygen_revsions.md"
#} ===========================================================================


if !defined?(Sketchup) || Sketchup::version.to_i < 6
  fail(NotImplementedError,"UV PolyGen only runs on SketchUp v6 or higher",caller)
end


module Jimhami42  # Jim Hamilton's toplevel namespace
  
  module UVPolyGen # plugin module

    verbose, $VERBOSE = $VERBOSE, nil # suppress warnings

    #{# 1. IMPORTANT PLUGIN CONSTANTS
    #
      PLUGNAME = 'UVPolyGen'
      OPTSKEY  = 'Plugin_Jimhami42_UVPolyGen' # for registry & plist settings
      
      RELOAD_PATH = __FILE__[PLUGIN_ROOT_PATH.size+1..-1] unless defined?(RELOAD_PATH)

      # NOTICE: Any change in the parameter dictionary name constants
      # after a release, must be accompanied by a major version ordinal bump!
      # Also the old constant must remain, with old version ordinal added to
      # it's identifier. (These are used to find and remove old dictionaries.)
      #
      # The last used parameter dictionary name attached at model level: 
      DICTLAST  = 'Jimhami42_UVPolyGen_Parameters' # vers 2+
      DICTLAST1 = 'UV_Parameters' # vers 1.x - DO NOT CHANGE - HISTORICAL
      # Revisions must update case statement in: get_last_dictionary_name()
      #
      # The parameter dictionary name for individual mesh groups:
      DICTMESH  = 'UV_Parameters'
      # individual mesh dictionary was not used in v1.x, so we use nil:
      DICTMESH1 = nil unless defined?(DICTMESH1)
      # Revisions must update case statement in: get_mesh_dictionary_name()

      # Historical English surface choices (to decipher pre-v2 parameters.)
      SURFENG = ['Offset','Side 1','Side 2','End 1','End 2']
      # Post v1 dictionary saves integer index into locale SURFACE array.
    #
    #}#


    #{# 2. MODULE VARIABLES FOR PLUGIN SETTINGS
    #
      @@scale = Sketchup::read_default(OPTSKEY,'scale',true) ? true : false
      @@scale_check = @@scale ? MF_CHECKED : MF_UNCHECKED

      @@retry = true

      @@cpoint = Sketchup::read_default(OPTSKEY,'cpoint',true) ? true : false
      @@cpoint_check = @@cpoint ? MF_CHECKED : MF_UNCHECKED

      @@debug = Sketchup::read_default(OPTSKEY,'debug_mode',false)
      @@debug = false if @@debug.nil?

      @@calc_debug = Sketchup::read_default(OPTSKEY,'calc_debug_mode',false)
      @@calc_debug = false if @@calc_debug.nil?

      @@calc_debug_call = Sketchup::read_default(OPTSKEY,'calc_debug_call',false)
      @@calc_debug_call = false if @@calc_debug_call.nil?

      @@calc_debug_euro = Sketchup::read_default(OPTSKEY,'calc_debug_euro',false)
      @@calc_debug_euro = false if @@calc_debug_euro.nil?

      @@calc_global = Sketchup::read_default(OPTSKEY,'calc_global',false)
      @@calc_global = false if @@calc_global.nil?
    #
    #}#


    #{# 3. INPUTBOX CONSTANTS
    #
      # ERRORTXT[:param] will be followed by "(#{num}): #{message}"
      #  example: "Error Parameter(4): method call not allowed!"
      #  These are displayed as inputbox caption after an input error.
      ERRORTXT = {
        :error => 'Error',
        :param => 'Error Parameter', # [*see note above]
        :scope => "'::' operator not allowed!",
        :eval  => "method call not allowed!",
        :class => "class reference not allowed!",
        :float => "must evaluate as Float",
        :toint => "must evaluate as Integer",
        :range => "start..end range cannot be 0.0",
        :steps => "step count must round to >= 1",
        :uinfi => "u range divisions cannot be infinite!",
        :vinfi => "v range divisions cannot be infinite!",
        :udivs => "u range divisions below tolerance!",
        :vdivs => "v range divisions below tolerance!"
      }

      BOOLEAN = ['true','false'] # choices in inputbox

      INPUT_TITLE = "Enter PolyGen Parameters:"

      PROMPT = [
        "U Start",
        "U End",
        "U Steps",
        "V Start",
        "V End",
        "V Steps",
        "x =",
        "y =",
        "z =",
        "Offset",
        "Surface",
        "Name",
        "Scaling ?"
      ]

      RETRY   = "Reset fields and Retry?"

      SURFACE = ['Offset','Side 1','Side 2','End 1','End 2']

      # Undo menutext & Undo button tooltip
      UNDOTXT = { 
        :undo => 'UV Mesh:' # Create command: "Undo UV Mesh: #{name}"
      }

      # NOTE: The UI.inputbox is still bugged, as of v15. It sets
      # the prompt width to the width of the input edit controls.
      # In the future when this prompt width bug is fixed, the
      # prompt formatting below will need an if .. else construct.

      INPUT_WIDTH = 50 # spaces, also ref'd from get_parameters()

      allwidth = INPUT_WIDTH-2
      topwidth = PROMPT[0..5].max {|a,b| a.size <=> b.size }.size
      botwidth = PROMPT[9..12].max{|a,b| a.size <=> b.size }.size
      
      PROMPT[0..5].each {|s| s<<" " }
      PROMPT[9..12].each{|s| s<<" " }

      PROMPTS = [ # note plural constant name
        "%#{allwidth-(topwidth-PROMPT[0].size)}s" % PROMPT[0], # U Start
        "%#{allwidth-(topwidth-PROMPT[1].size)}s" % PROMPT[1], # U End
        "%#{allwidth-(topwidth-PROMPT[2].size)}s" % PROMPT[2], # U Steps
        "%#{allwidth-(topwidth-PROMPT[3].size)}s" % PROMPT[3], # V Start
        "%#{allwidth-(topwidth-PROMPT[4].size)}s" % PROMPT[4], # V End
        "%#{allwidth-(topwidth-PROMPT[5].size)}s" % PROMPT[5], # V Steps
        "%#{allwidth}s" % PROMPT[6], # x =
        "%#{allwidth}s" % PROMPT[7], # y =
        "%#{allwidth}s" % PROMPT[8], # z =
        "%#{allwidth-(botwidth-PROMPT[9].size)}s"  % PROMPT[9],  # Offset
        "%#{allwidth-(botwidth-PROMPT[10].size)}s" % PROMPT[10], # Surface
        "%#{allwidth-(botwidth-PROMPT[11].size)}s" % PROMPT[11], # Name
        "%#{allwidth-(botwidth-PROMPT[12].size)}s" % PROMPT[12]  # Scaling ?
      ]

      PARAMS = { # Parameter dictionary keys & default values
        #
        'u_start' => "-PI/2",
        'u_end'   => "PI/2",
        'u_steps' => "10",
        #
        'v_start' => "-PI/2",
        'v_end'   => "PI/2",
        'v_steps' => "10",
        #
        'xf' => "u",
        'yf' => "v",
        'zf' => "sin(u) + cos(v)",
        #
        'offset' => "0.0",
        'choice' => "0", # Surface index (was 'Offset' English word)
        'name'   => "",
        'scale'  => @@scale.to_s # automatically scale to model units
      }
      
      LIST = ['','','','','','','','','','',SURFACE.join('|'),'',BOOLEAN.join('|')]
    #
    #}#


    #{# 4. CUSTOM EXCEPTIONS
    #
      # A custom attribute dictionary error:
      AttrDictCreateError = Class.new(RuntimeError) unless defined?(AttrDictCreateError)

      # A custom inputbox parameter error:
      ParameterError = Class.new(RuntimeError) unless defined?(ParameterError)

      # A custom inputbox retry exception:
      RetryException = Class.new(RuntimeError) unless defined?(RetryException)
    #
    #}#


    #{# 5. LOAD CLASSES & METHODS
    #
      # Load Core methods:
      require File.join(PLUGIN_PATH,'uv_polygen_core.rb')

      # Load Calc class definition:
      require File.join(PLUGIN_PATH,'uv_polygen_calc.rb')

      # Load menus & commands:
      require File.join(PLUGIN_PATH,'uv_polygen_menu.rb')
    #
    #}#


    #{# 6. DEBUG FUNCTIONS
    #
      def self::debug(arg=true)
      # Sets debug mode (default is true.)
        #
        if @@debug != ( arg ? true : false )
          #
          @@debug = arg ? true : false
          Sketchup::write_default(OPTSKEY,'debug_mode',@@debug)
          #
          if @@debug && !Object.methods.include?('UVPG')
            Object.class_eval "
              def UVPG()
                Jimhami42::UVPolyGen::reload()
              end
            "
          end
          #
        end
        #
      end ### self::debug()
      class << self
        alias_method(:debug=,:debug)
      end

      def self::debug?
      # Returns debug mode.
        #
        @@debug
        #
      end ### self::debug?()

      def self::get_calc(
        autoscale = true
      )
      # Creates a Calc class instance to play with at the console.
        #
        Jimhami42::UVPolyGen::Calc.new(autoscale)
        #
      end ### self::get_calc()

      def self::units_options()
      # Returns a reference to the active model's units options provider.
      # Called from Calc class initialize(), so that the Sketchup module
      # reference need not be exposed to instances.
        #
        Sketchup.active_model.options['UnitsOptions']
        #
      end ### self::units_options()

      def self::reload()
      # Reloads the plugin's files.
        #
        verbose, $VERBOSE = $VERBOSE, nil # suppress warnings
        #
        puts "\nReloading files for #{Module::nesting[0].name} ..."
        # Reload "uv_polygen.rb" (THIS file.)
        puts '  Loading: '<<RELOAD_PATH.inspect
        load RELOAD_PATH
        # Reload Calc class definition:
        path = File.join(File.dirname(RELOAD_PATH),'uv_polygen_calc.rb')
        puts '  Loading: '<<path.inspect
        load path
        # Reload Core methods:
        path = File.join(File.dirname(RELOAD_PATH),'uv_polygen_core.rb')
        puts '  Loading: '<<path.inspect
        load path
        # Reload menus & commands:
        path = File.join(File.dirname(RELOAD_PATH),'uv_polygen_menu.rb')
        puts '  Loading: '<<path.inspect
        load path
        #
      rescue => e
        puts "UVPolyGen Reload Error: "<<e.inspect
        puts e.backtrace.first
      ensure
        # restore warnings:
        $VERBOSE = verbose  
        return "$VERBOSE is now: #{$VERBOSE.to_s}\n"
        #
      end ### self::reload()

    #
    #}#

    $VERBOSE = verbose  # restore warnings

  end # module UVPolyGen
  
end # module Jimhami42
