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
          Jimhami42 = ::Jimhami42
          Sketchup  = ::Sketchup
          Geom = ::Geom
          Math = ::Math
          #
        end

        Pi = PI # because I always spell it "Pi" & others likely will too.
      #
      #}#


      #{# CLASS VARIABLES
      #
        @@debug = Jimhami42::UVPolyGen::module_eval('@@debug')
      #
      #}#


      #{# ATTRIBUTES
      #
        attr_reader :scale
      #
      #}#


      #{# CONSTRUCTOR
      #
        def initialize(autoscale)
          #
          @autoscale = autoscale
          #
          opts = Sketchup.active_model.options['UnitsOptions']
          unit = opts['LengthUnit']
          @scale = case unit
          when 0
            case opts['LengthFormat']
            when 0,3
              1.0 # decimal & fractional inches
            when 1,2
              12.0 # architectural & engineering feet
            else
              1.0
            end
          when 1
            12.0 # decimal feet
          when 2
            1.0/25.4 # decimal mm
          when 3
            1.0/2.54 # decimal cm
          when 4
            1.0/0.0254 # decimal meters
          else
            1.0
          end
          #
        end ### initialize()
      #
      #}#


      #{# INSTANCE METHODS
      #

        alias_method(:ieval,:instance_eval)
        undef_method(:instance_eval)

        def abs(arg)
          arg.respond_to?(:abs) ? arg.abs : arg
        end

        def ceil(arg)
          arg.respond_to?(:ceil) ? arg.ceil : arg
        end

        def deg(arg)
          arg.respond_to?(:degrees) ? arg.degrees : arg
        end
        alias_method(:deg2rad,:deg)

        def e()
          E
        end

        def float(arg)
          str = arg.dup
          if @@debug
            msg = "\nJimhami42::UVPolyGen::Calc#float() method entry"
            msg<< "\n  arg : \"#{str}\""
            Kernel.puts(msg) rescue ::Kernel.puts(msg)
          end
          retried = false
          begin
            if str =~ /\A(\=|\+?\D+|\+?\w+|\-?\D+|\-?\w+)/i
              # Non-digit beginning. Expressions beginning with '=' or '(' can
              # also be used to trigger evaluation, rather than conversion.
              if @@debug
                msg = "  Non-digit beginning for arg: evaluating as Ruby code."
                Kernel.puts(msg) rescue ::Kernel.puts(msg)
              end
              str = str[1..-1] if str =~ /\A(\=)/i
              num = ieval(str)
            else
              if str =~ /\A(\+?|\-?)(\d+\z|\d+\.\d+\z)/i
                num = str.to_f
              elsif str =~ /\A(\+?|\-?)(\d+\z|\d+\,\d+\z)/i
                num = str.sub(/\,/,'.').to_f
              elsif str =~ /\A(\+?|\-?)(\d+)/i # starts with numerics
                if str =~ /\A(\+?|\-?)(\d+\,\d+)/i
                  num = str.sub!(/\,/,'.').to_f # replace the comma
                else
                  num = str.to_f
                end
                #
                num = num.degrees if str =~ /\A(\+?|\-?)(\d+|\d+\.\d+)(\.?)(deg|degrees)/
                num = num.radians if str =~ /\A(\+?|\-?)(\d+|\d+\.\d+)(\.?)(rad|radians)/
                #
              else
                num = 1.0 # perhaps raise ArgumentError ?
                # retried = true
                # fail(ArgumentError,"invalid value for Float",caller)
              end
            end
            #
          rescue => e
            if @@debug
              msg = "\nJimhami42::UVPolyGen::Calc#float() rescue clause"
              msg << "\n  Error: #{e.inspect}"
              Kernel.puts(msg) rescue ::Kernel.puts(msg)
            end
            if str =~ /(\d+\,\d+)/i && !retried
              str.gsub!(/\,/,'.')
              retried = true
              retry
            else
              Kernel.raise rescue ::Kernel.raise
            end
          else
            return num.to_f
          end
          #
        end ### float()

        def floor(arg)
          arg.respond_to?(:floor) ? arg.floor : arg
        end

        def int(arg)
          str = arg.dup
          retried = false
          begin
            if str =~ /\A(\=|\D+|w+)/i # non-digit beginning
              str = str[1..-1] if str =~ /\A(\=)/i
              num = ieval(str).to_f.round
            else
              if str =~ /\A(\d+\,\d+)/
                str.gsub!(/\,/,'.')
                num = str.to_f.round
              elsif str =~ /\A(\d+\.\d+|\d+)/
                num = str.to_f.round
              end
            end
          rescue => e
            if str =~ /(\d+\,\d+)/i && !retried
              str.gsub!(/\,/,'.')
              retried = true
              retry
            else
              Kernel.raise rescue ::Kernel.raise
            end
          else
            return num
          end
          #
        end ### int()

        def node(fx,fy,fz,uc,ud,us,vc,vd,vs)
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
                x = x * @scale
                y = y * @scale
                z = z * @scale
              end
              pts << Geom::Point3d.new(x.to_l,y.to_l,z.to_l)
              #pts << Geom::Point3d.new(x,y,z)
            end
            node << pts
          end
          #
          return node
          #
        end ### node()

        def pi()
          PI
        end

        def rad(arg)
          arg.respond_to?(:radians) ? arg.radians : arg
        end
        alias_method(:rad2deg,:rad)

        def round(arg,places=0)
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
        end

        def test(arg,u,v)
          #
          str = arg.dup
          ieval(str)
          #
        end ### test()

        def trunc(arg)
          arg.respond_to?(:truncate) ? arg.truncate : arg
        end
      #
      #}#


      #{# UNDEFINE METHODS
      #
        # We need to undefine some dangerous methods that we do not
        #  want the users to access from the inputbox eval fields.
        # !note: instance_eval() is already aliased and undefined.

        if @@debug
          # introspection of Calc class allowed only while debugging.
          @@intro = [
            :caller, :caller_locations, :class_eval, :class_variable_defined?,
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
          ]
        else
          @@intro = []
        end

        begin
          # suppress warnings
          verbose, $VERBOSE = $VERBOSE, nil
          # Undefine Instance Methods
          meths = instance_methods(true) - instance_methods(false)
          meths = meths.concat(private_instance_methods(true))
          keep  = [:initialize, :method_missing, :eql?, :equal?, :==] # :raise, :puts
          meths = meths - keep
          math  = Math.private_instance_methods(false)
          math  = math - keep
          meths = meths - math
          meths = meths - [
            :abs,:ceil,:deg,:deg2rad,:e,:float,:floor,:ieval,:int,
            :node,:pi,:rad,:rad2deg,:round,:scale,:test,:trunc
          ]
          if @@debug # allow introspection
            meths = meths - @@intro
            meths.each {|m| undef_method(m) }
          else # suppress unfound method errors
            meths.each {|m| undef_method(m) rescue nil }
          end
          # Undefine Class Methods
          class << self
            keep  = [
              :__id__, :ancestors, :class, :const_missing,  :eql?,
              :equal?, :freeze, :frozen?, :included_modules, :inspect,
              :is_a?, :kind_of?, :name, :new, :nesting, :nil?,
              :object_id, :superclass, :to_s, :==
            ]
            meths = methods(true) - keep
            keep  = [:Complex,:Float,:Integer,:Rational,:method_missing,:undef_method] 
            meths = meths - ( private_methods(true) - keep )
            if @@debug # allow introspection
              meths = meths - @@intro
              meths.each {|m| undef_method(m) }
            else # suppress unfound method errors
              meths.each {|m| undef_method(m) rescue nil }
            end
            # lastly
            undef_method('undef_method')
          end
          #
        rescue => e
          Jimhami42::UVPolyGen::announce_error(e,"Issue undefining methods in Calc class.")
        ensure
          # restore warnings:
          $VERBOSE = verbose
          # Cleanup - GC
          @@intro.clear
          keep.clear
          math.clear
          meths.clear
          keep = math = meths = nil
          @@intro = nil
          remove_class_variable(:@@intro) rescue nil
          GC::start rescue ::GC::start
        end

      #
      #}#


    end

    #
    ##
    ### class definition


    Calc.freeze unless @@debug  #  <-----------------------<<<<<<<<  FREEZE


  end # module UVPolyGen
  
end # module Jimhami42
