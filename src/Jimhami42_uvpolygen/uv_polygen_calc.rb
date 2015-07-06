# encoding: UTF-8
# uv_polygen_calc.rb
#{ ===========================================================================
#  DETAILS:
#
#  Calc class definition for U-V Polygon Mesh Generator Plugin.
#
# ----------------------------------------------------------------------------
#  COPYRIGHT(S):
#
#  (C) 2014 by Jim Hamilton (Jimhami42 at GitHub.com)
#  (C) 2015 by Daniel A. Rathbun
#
#} ===========================================================================


module Jimhami42  # Jim Hamilton's toplevel namespace
  
  module UVPolyGen # plugin module
  
    ### CLASS DEFINTION - Calc
    ##
    #

    Calc = defined?(BasicObject) ? Class::new(BasicObject) : Class::new(Object)

    class Calc


      #{# DEPENDANCIES
      #
        include Math rescue include ::Math
      #
      #}#


      #{# CONSTANTS
      #
        # The parent plugin namespace reference:
        PLUGIN = Module.nesting[1] rescue ::Module.nesting[1]
        NAMESPACE = PLUGIN.name

        # This file's filename:
        FILENAME = File.basename(__FILE__) rescue ::File.basename(__FILE__)

        # DECIMAL SEPARATOR
        #   Ruby itself always uses decimal point internally.
        begin
          "3,7".to_l     # If no exception is raised, then
          DECPT = false  # UI uses comma as decimal separator.
        rescue
          DECPT = true   # UI uses point as decimal separator.
        end

        # PROXY CONSTANTS
        if defined?(BasicObject)
          #
          #{ We are under Ruby 1.9+ and are a BasicObject subclass.
          #  BasicObject subclasses must (by design) qualify any refs to
          #  Core Ruby classes and/or modules with a toplevel scope operator.
          #
          # Older 1.8 trunk branches cannot accept toplevel scope operator.
          # Includes SketchUp Mac up to v2013 (distro'd w/ Ruby v1.8.5-p0)
          # Includes SketchUp Win up to v7.1* (distro'd w/ Ruby v1.8.0-p0)
          #   *[Users can paste in the Ruby v1.8.6-p287 interpreter DLL.]
          # But Object subclasses have no problem seeing Core modules.
          #
          # So for SketchUp 2014+ (Ruby v1.9+), since we're using a
          # BasicObject subclass, & it cannot see Core classes & modules,
          # we must use proxy constants referencing fully qualified modules.
          #}
          String = ::String # temporary
          ArgumentError  = ::ArgumentError
          LocalJumpError = ::LocalJumpError
          RuntimeError   = ::RuntimeError
          #
        end

        Pi = PI # because I always spell it "Pi" & others likely will too.
      #
      #}#


      #{# CLASS VARIABLES
      #
        # Calc class introspection mode must be manually set in registry.
        # Changing it after startup makes no difference in that session.
        @@intro = PLUGIN::module_eval(  
          'Sketchup::read_default(OPTSKEY,"calc_intro_mode",false)'
        )
        @@intro = false if @@intro.nil? # NEVER RELEASE WITH INTRO TRUE !!
      #
      #}#


      #{# CLASS DEBUG METHODS
      #
      class << self

        def debug(arg=true)
        # Sets debug mode (default is true.)
        #
          # Cannot change class variables when class is frozen, so
          # we keep the debug setting in the parent plugin module.
          # Works to our advantage as we need not expose the Sketchup
          # module reference in the Calc class.
          #
          debug =( arg ? true : false )
          if debug != PLUGIN::module_eval('@@calc_debug')
            PLUGIN::module_eval %Q{
              Sketchup::write_default(OPTSKEY,'calc_debug_mode',#{debug})
              @@calc_debug= #{debug}
            }
          end
          #
          return debug
          #
        end ### self::debug()
        alias_method(:debug=,:debug)

        def debug?
        # Returns debug mode for the Calc class.
          #
          PLUGIN::module_eval('@@calc_debug')
          #
        end ### self::debug?()

      end
      #
      #}#


      #{# ATTRIBUTES
      #
        attr_reader :scale, :sym
      #
      #}#


      #{# CONSTRUCTOR
      #
        def initialize(
          autoscale = true, # Passed in from dialog input in actual use.
          *ignored
        )
          #
          @autoscale = autoscale
          #
          @debug = PLUGIN::module_eval('@@calc_debug')
          @debug_euro = PLUGIN::module_eval('@@calc_debug_euro')
          @debug_call = PLUGIN::module_eval('@@calc_debug_call')
          #
          opts = PLUGIN::units_options
          unit = opts['LengthUnit']
          @scale = case unit
          when 0
            case opts['LengthFormat']
            when 0,1,3
              @sym = '"'
              1.0 # decimal, architectural & fractional inches
            when 2
              @sym = %q{'}
              12.0 #  & engineering feet
            else
              @sym = '"'
              1.0
            end
          when 1
            @sym = %q{'}
            12.0 # decimal feet
          when 2
            @sym = 'mm'
            1.0/25.4 # decimal mm
          when 3
            @sym = 'cm'
            1.0/2.54 # decimal cm
          when 4
            @sym = 'm'
            1.0/0.0254 # decimal meters
          else
            @sym = '"'
            1.0
          end
          #
        end ### initialize()
      #
      #}#


      #{# INPUT VALIDATION METHODS - (Not usable by input fields)
      #
        alias_method(:ieval,:instance_eval)
        undef_method(:instance_eval)

        def control( callers, *ignored )
        # Control who calls the internal validation methods.
        # callers is a callstack array from the Kernel.caller() method.
          #
          # Only allow calling from:
          # (1) control & validation methods in THIS file:
          allowed = [
            :control,:fail,:floatval,
            :intval,:node,:raise,:test #:puts,:ieval,
          ]
          # (2) get_parameters() in 'uv_polygen_core.rb'
          # or
          # (3) from the console command line, during testing.
          #
          called = callers.first
          #
          if @debug && @debug_call
            ::Kernel.puts "\nCallstack:"
            ::Kernel.puts callers.inspect
            #
            ::Kernel.puts "\nCaller:"
            ::Kernel.puts called.inspect
          end
          #
          file = called.split(':')[0] rescue ''
          meth = called.split(':')[2] rescue ''
          if file.size == 1 # PC drive letter
            file = called.split(':')[1] rescue ''
            meth = called.split(':')[3] rescue ''
            file = file.split('/').last
          elsif file == '<main>'
            meth = called.split(':')[1]
          elsif file == 'SketchUp' or file.empty?
            meth = "in `eval'" if meth.empty?
          else
            file = file.split('/').last
          end
          #
          return if meth == "in `fail'" || meth == "in `raise'"
          #
          if file == FILENAME && meth != "in `<main>'"
            meths = meth[4..-2].to_sym
            unless allowed.include?(meths)
              # Only allow control methods to call each other.
              if @debug
                msg = "\n  Called from other Calc function: \"#{meth}\""
                msg<< "\n  Called from: \"#{file}:#{meth}\""
                msg<< "\n  Raising LocalJumpError exception ..."
                puts(msg)
              end
              begin
                Kernel.fail(LocalJumpError,"method call not allowed",callers)
              rescue
                ::Kernel.fail(::LocalJumpError,"method call not allowed",callers)
              end
            end
          elsif !file.empty? && file != 'uv_polygen_core.rb'
            # Do not allow other files to abuse this method:
            unless (file == '' || file == '<main>' || file == 'SketchUp') &&
            ( meth == "in `eval'" || meth == "in `<main>'" )
              if @debug
                msg = "\n  Not called from console or 'uv_polygen_core.rb'"
                msg<< "\n  Called from: \"#{file}:#{meth}\""
                msg<< "\n  Raising RuntimeError exception ..."
                puts(msg)
              end
              begin
                Kernel.fail(RuntimeError,"method call not allowed",callers)
              rescue
                ::Kernel.fail(::RuntimeError,"method call not allowed",callers)
              end
            end
          end
          #
        end ### control()


        def fail( err, msg, stack, *ignored )
          #
          # Control who calls the internal validation methods.
          callers = Kernel.caller(1) rescue ::Kernel.caller(2)
          #control(callers)
          #
          Kernel.fail(err,msg,stack) rescue ::Kernel.fail(err,msg,stack)
          #
        end ### fail()


        def puts( str, *ignored )
          #
          # Control who calls the internal validation methods.
          callers = Kernel.caller(1) rescue ::Kernel.caller(2)
          #control(callers)
          #
          Kernel.puts(str) rescue ::Kernel.puts(str)
          #
        end ### puts()


        def raise( *args )
          #
          # Control who calls the internal validation methods.
          callers = Kernel.caller(1) rescue ::Kernel.caller(2)
          #control(callers)
          #
          if args.empty?
            Kernel.raise rescue ::Kernel.raise
          else
            Kernel.raise(*args) rescue ::Kernel.raise(*args)
          end
          #
        end ### raise()

        # -------------------------------------------------------------------

        def floatval( arg, *ignored )
          #
          str = arg.dup
          #
          if @debug
            msg = "\n#{NAMESPACE}::Calc#floatval() method entry"
            msg<< "\n  arg : \"#{str}\""
            puts(msg)
          end
          #
          # Control who calls the internal validation methods.
          callers = Kernel.caller(1) rescue ::Kernel.caller(2)
          control(callers)
          #
          if str =~ /\A(\+|\-)?[^0-9.,]/i || str =~ /\A(\=|\(|\[|\{)/i
            # Non-digit beginning. Expressions beginning with '=' or '(' can
            # also be used to trigger evaluation, rather than conversion.
            if @debug
              msg = "  Non-digit beginning for arg: evaluating as Ruby code."
              puts(msg)
            end
            # Strip beginning equal sign:
            if str =~ /\A(\=)/i
              if @debug
                msg = "  Stripping beginning equal sign."
                puts(msg)
              end
              str = str[1..-1]
            end
            # Handle euro style numerics using commas as decimal separator:
            if !DECPT || (@debug && @debug_euro)
              # If str contains commas, replace with decimal points:
              if str =~ /(\,)/i
                str.tr!(',','.')
                if @debug
                  msg = "  Replacing comma decimal separators with decimal points."
                  msg<< "\n  str : \"#{str}\""
                  puts(msg)
                end
              end
              # If str contains semi-colons, replace with commas:
              if str =~ /(\;)/i
                str.tr!(';',',')
                if @debug
                  msg = "  Replacing semi-colons with commas."
                  msg<< "\n  str : \"#{str}\""
                  puts(msg)
                end
              end
            end
            # If str contains decimal points (preceded or not by + or -,)
            # insert a zero before the decimal points, if needed:
            if str =~ /([^0-9]+\.[0-9]+|\+\.[0-9]+|\-\.[0-9]+)/i
              str.gsub!(/(\A|[^0-9])\.([0-9])/i,'\10.\2')
              if @debug
                msg = "  Prepending decimal points with zeros."
                puts(msg)
              end
            end
            #
            ###
              #
              num = ieval(str)  #  <--<<< interpreter evaluation
              #
            ###
            #
          else # Begins with a digit, use conversion instead of evaluation:
            #
            if @debug
              msg = "  Digit beginning for arg: converting to Float."
              puts(msg)
            end
            # If str begins with underscore, +underscore or -underscore,
            # insert a zero before the underscore character:
            if str =~ /\A(_[0-9]|\+_[0-9]|\-_[0-9])/i
              str.sub!(/_/,'0_')
              if @debug
                msg = "  Prepending start underscore with zero."
                puts(msg)
              end
            end
            # Handle euro style numerics using commas as decimal separator:
            if !DECPT || (@debug && @debug_euro)
              # If str contains comma within numerics, replace the 1st comma:
              if str =~ /\A(\+?|\-?)([0-9]*\,[0-9_]+|[0-9]+[0-9_]*\,[0-9_]+)/i
                if @debug
                  msg = "  Replacing comma decimal separator with decimal point."
                  puts(msg)
                end
                str.sub!(/\,/,'.')
              end
            end
            # If str has an underscore following the decimal point,
            # remove the underscore character:
            if str =~ /\A(\+?[0-9]*\._|\-?[0-9]*\._)/i
              str.sub!(/\._/,'.')
              if @debug
                msg = "  Removing underscore after decimal point."
                puts(msg)
              end
            end
            #
            ###
              #
              num = str.to_f  #  <--<<< String to Float conversion
              #
            ###
            #
            if str =~ /\A(\+?|\-?)([0-9]+[0-9_]*|[0-9]+[0-9_]*\.[0-9_]+)(\.?deg|\.?degrees)/
              if @debug
                msg = "  Argument expressed in degrees: converting to radians."
                puts(msg)
              end
              num = num.degrees
            elsif str =~ /\A(\+?|\-?)([0-9]+[0-9_]*|[0-9]+[0-9_]*\.[0-9_]+)(\.?rad|\.?radians)/
              if @debug
                msg = "  Argument expressed in radians: converting to degrees."
                puts(msg)
              end
              num = num.radians 
            end
            #
          end # if non-numeric evaluation .. else string conversion block
          #
        rescue => e
          #
          if @debug
            msg = "\n#{NAMESPACE}::Calc#floatval() rescue clause"
            msg << "\n  Error: #{e.inspect}"
            puts(msg)
          end
          #
          raise # ? return e
          #
        else
          #
          if @debug
            msg = "  Return from floatval(): #{num}"
            puts(msg)
          end
          #
          return num.to_f
          #
        end ### floatval()


        def intval( arg, *ignored )
          #
          str = arg.dup
          #
          if @debug
            msg = "\n#{NAMESPACE}::Calc#intval() method entry"
            msg<< "\n  arg : \"#{str}\""
            msg<< "\n  passing value to floatval() method ..."
            puts(msg)
          end
          #
          # Control who calls the internal validation methods.
          callers = Kernel.caller(1) rescue ::Kernel.caller(2)
          control(callers)
          #
          # Leverage all the work we did in the floatval() method
          # with regular expressions & logical branching, etc.,
          # then round the resulting float value to an integer.
          n = floatval(str)
          num = n.round
          #
          if @debug
            msg = "  Return from intval() rounded: #{num}"
            puts(msg)
          end
          #
        rescue => e
          if @debug
            msg = "\n#{NAMESPACE}::Calc#intval() rescue clause"
            msg << "\n  Most likely error comes from float() method:"
            msg << "\n  Error: #{e.inspect}"
            puts(msg)
          end
          if e.message == "invalid value for Float"
            # Then error came from out floatval() function:
            fail(
              (ArgumentError rescue ::ArgumentError),
              "invalid value for Integer",
              caller
            )
          else
            Kernel.raise rescue ::Kernel.raise
          end
          #
        else
          #
          return num
          #
        end ### intval()


        def node( fx,fy,fz, uc,ud,us, vc,vd,vs, *ignored )
        #
          #
          if @debug
            msg = "\n#{NAMESPACE}::Calc#node() method entry"
          end
          #
          # Control who calls the internal validation methods.
          callers = Kernel.caller(1) rescue ::Kernel.caller(2)
          control(callers)
          #
          if @debug
            msg<< "\n  fx : \"#{fx}\""
            msg<< "\n  fy : \"#{fy}\""
            msg<< "\n  fz : \"#{fz}\""
            msg<< "\n  uc : \"#{uc}\""
            msg<< "\n  ud : \"#{ud}\""
            msg<< "\n  us : \"#{us}\""
            msg<< "\n  vc : \"#{vc}\""
            msg<< "\n  vd : \"#{vd}\""
            msg<< "\n  vs : \"#{vs}\""
            puts(msg)
          end
          #
          fx = fx[1..-1] if fx =~ /\A(\=)/i
          fy = fy[1..-1] if fy =~ /\A(\=)/i
          fz = fz[1..-1] if fz =~ /\A(\=)/i
          #
          node = []
          x = 0
          y = 0
          z = 0
          #
          for i in 0..uc
            pts = []
            u = us + i * ud
            for j in 0..vc
              v = vs + j * vd
              ieval('x = '<<fx)
              ieval('y = '<<fy)
              ieval('z = '<<fz)
              if @scale != 1.0 && @autoscale
              # Scale x, y, and z to the model unit:
                x = x * @scale
                y = y * @scale
                z = z * @scale
                # Note: offset is scaled in the get_parameter()
                # method, in the "uv_polygen_core.rb" file.
              end
              p3d = Geom::Point3d rescue ::Geom::Point3d
              pts << p3d.new(x.to_l,y.to_l,z.to_l)
              #pts << p3d.new(x,y,z)
            end
            node << pts
          end
          #
          if @debug && !PLUGIN::module_eval('@@debug')
            msg = "\n  Return (#{node.class.name}) from node():\n#{node.inspect}"
            puts(msg) # plugin module debug will output node inspection.
          end
          #
          return node
          #
        end ### node()


        def test( arg, u, v, *ignored )
        # For testing and input validation. The supplied u & v arguments
        #    are method variables used in the local evaluation of str.
        #
          #
          str = arg.dup
          #
          if @debug
            msg = "\n#{NAMESPACE}::Calc#test() method entry"
            msg<< "\n  arg : \"#{str}\""
            msg<< "\n    u : \"#{u}\""
            msg<< "\n    v : \"#{v}\""
            puts(msg)
          end
          #
          # Control who calls the internal validation methods.
          callers = Kernel.caller(1) rescue ::Kernel.caller(2)
          control(callers)
          #
          num = ieval(str) # ? pass this to float() ?
          #
          if @debug
            msg = "  Return from test(): #{num}"
            puts(msg)
          end
          #
          if ( num.is_a?(Float) rescue num.is_a?(::Float) )
            return num
          else
            return "must evaluate as Float"
          end
          #
        rescue => e
          if @debug
            msg = "\n#{NAMESPACE}::Calc#test() rescue clause"
            msg << "\n  Error: #{e.inspect}"
            puts(msg)
          end
          #
          return e
          #
        end ### test()

      #
      #}#


      #{# MATH FUNCTIONS - (Accessible to parameter input fields)
      #
        def abs( arg, *ignored )
          #
          num = arg.respond_to?(:abs) ? arg.abs : arg
          #
        end ###

        def ceil( arg, *ignored )
          arg.respond_to?(:ceil) ? arg.ceil : arg
        end ###

        def deg( arg, *ignored )
          arg.respond_to?(:degrees) ? arg.degrees : arg
        end ###
        alias_method(:deg2rad,:deg)

        def e( *ignored )
          E
        end ###

        def float( arg, *ignored )
          arg.respond_to?(:to_f) ? arg.to_f : arg
        end ###
        alias_method(:f,:float)

        def floor( arg, *ignored )
          arg.respond_to?(:floor) ? arg.floor : arg
        end ###

        def pi( *ignored )
          PI
        end

        def rad( arg, *ignored )
          arg.respond_to?(:radians) ? arg.radians : arg
        end ###
        alias_method(:rad2deg,:rad)

        def round( arg, places=0, *ignored )
          places = places.to_i unless places.is_a?(Integer)
          if arg.respond_to?(:round)
            if arg.method(:round).arity != 0
              arg.round(places) # Ruby 1.9+
            else
              n =( arg * 10**places ).round / 10**places
              return n.to_i if places < 1
              return n.to_f if places > 0
            end
          else
            arg
          end
        end ###
        alias_method(:rnd,:round)

        def trunc( arg, *ignored )
          arg.respond_to?(:truncate) ? arg.truncate : arg
        end ###
        alias_method(:int,:trunc)
        alias_method(:i,:trunc)
      #
      #}#


      #{# UNDEFINE METHODS
      #
        # We need to undefine some dangerous methods that we do not
        #  want the users to access from the inputbox eval fields.
        # !note: instance_eval() is already aliased and undefined.

        if @@intro
          # introspection of Calc class allowed. NEVER RELEASE AS TRUE !
          @@intro_meths = [
            :caller_locations, :class_eval, :class_variable_defined?,
            :local_variables, :method_defined?, :class_variable_get,
            :class_variable_set, :class_variables, :const_defined?, :const_get,
            :const_missing, :const_set, :constants, :include?, :included_modules,
            :inspect, :instance_eval, :instance_exec, :instance_methods,
            :instance_of?, :instance_variable_defined?, :instance_variable_get,
            :instance_variable_set, :instance_variables, :method_defined?,
            :methods, :module_eval, :module_exec, :private_instance_methods,
            :private_method_defined?, :private_methods, :protected_instance_methods,
            :protected_method_defined?, :protected_methods, :public_instance_methods,
            :public_method_defined?, :public_methods, :respond_to_missing?,
            :respond_to?, :singleton_methods, :tainted?, :untrusted?, :to_s,
            :superclass, :send, :__send__
          ] # keeping these -> :caller,
        else
          @@intro_meths = []
        end

        begin
          # suppress warnings
          verbose, $VERBOSE = $VERBOSE, nil
          # Undefine Instance Methods
          meths = instance_methods(true) - instance_methods(false)
          meths = meths.concat(private_instance_methods(true))
          meths.map! {|m| m.to_sym } if meths[0].is_a?(String)
          keep  = [
            :caller, :initialize, :method_missing,
            :fail, :raise, :puts, :eql?, :equal?, '=='.to_sym
          ]
          meths = meths - keep
          math  = Math rescue ::Math
          math  = math.private_instance_methods(false)
          math.map! {|m| m.to_sym } if math[0].is_a?(String)
          math  = math - keep
          meths = meths - math
          meths = meths - [
            :abs,:ceil,:deg,:deg2rad,:e,:f,:float,:floor,
            :i,:int,:pi,:rad,:rad2deg,:rnd,:round,:scale,:trunc,
            :control,:fail,:floatval,:ieval,:intval,:node,:puts,:sym,:test
          ]
          meths.delete_if{|s| s == :raise || s == :fail }
          if @@intro # allow introspection
            meths = meths - @@intro_meths
            meths.each {|m| undef_method(m) }
          else # suppress unfound method errors
            meths.each {|m| undef_method(m) rescue nil }
          end
          # Undefine Class Methods
          class << self
            keep = [
              :__id__, :ancestors, :class, :const_missing, :raise, :fail,
              :equal?, :freeze, :frozen?, :included_modules, :inspect,
              :is_a?, :kind_of?, :name, :new, :nesting, :nil?,
              :object_id, :superclass, :to_s, :eql?, '=='.to_sym
            ]
            meths = methods(true)
            meths.map! {|m| m.to_sym } if meths[0].is_a?(String)
            meths = meths - keep
            keep  = [:Complex,:Float,:Integer,:Rational,:method_missing,:undef_method]
            priv  = private_methods(true)
            priv.map! {|m| m.to_sym } if priv[0].is_a?(String)
            meths = meths - ( priv - keep )
            meths.delete_if{|s| s == :raise || s == :fail }
            if @@intro # allow introspection
              meths = meths - @@intro_meths
              meths.each {|m| undef_method(m) }
            else # suppress unfound method errors
              meths.each {|m| undef_method(m) rescue nil }
            end
            # lastly
            undef_method('undef_method') rescue nil
            keep = priv = meths = nil
          end
          #
        rescue => e
          #PLUGIN::announce_error(e,"Issue undefining methods in Calc class.")
          puts "#{NAMESPACE}: Issue undefining methods in Calc class."
          puts "Error: "<<e.inspect
          puts e.backtrace
        ensure
          # Cleanup - GC
          keep = math = meths = nil
          @@intro_meths = nil
          remove_class_variable(:@@intro_meths) rescue nil
          if defined?(BasicObject)
            String = nil # point local constant at nil
            remove_const(:String)
          end
          # restore warnings:
          $VERBOSE = verbose
          # garbage collection:
          GC::start rescue ::GC::start
        end

      #
      #}#

    end # class Calc

    #
    ##
    ### class definition


    if @@calc_global
      #
      $calc = Calc.new(@@scale)
      #
    end


    unless Calc::debug?
      #
      Calc.freeze rescue nil  #  <---------------<<<<<<<<  FREEZE Calc class
      #
    end


  end # module UVPolyGen
  
end # module Jimhami42
