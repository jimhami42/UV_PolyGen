# encoding: UTF-8
# uv_polygen_core.rb
#{ ===========================================================================
#  DETAILS:
#
#  Core method definitions for U-V Polygon Mesh Generator Plugin.
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
    
    class << self  # singleton proxy class instance
    
      # These methods can be called without qualification, like
      # instance method calls, from outside this proxy class block.

      def add_mesh_to_model( mesh, params, op_name )
      # Callers: do_mesh_command()
        #
        group_name = params[11]
        #
        if @@debug
          puts "\n#{PLUGNAME}: entry to add_mesh_to_model()"
          puts "  mesh value    : #{mesh.inspect}"
          puts "  params value  : #{params.inspect}"
          puts "  op_name value : #{op_name.inspect}"
          puts "  group_name is : #{group_name.inspect}"
        end
        #
        begin
          #
          mod = Sketchup.active_model
          #{# UNDO OPERATION
          #
          mod.start_operation(op_name,true) rescue mod.start_operation(op_name)
            #
            group  = mod.active_entities.add_group
            result = group.entities.fill_from_mesh( mesh, true, 0 )
              # entities.fill_from_mesh must start with empty entities!
              # result is true for success, nil for failure
            if result.nil?
              group  = mod.active_entities.add_group if !group.valid?
              result = group.entities.add_faces_from_mesh( mesh, 0 )
              # result is exit code 0 for success; ? for failure
            end
            fail(RuntimeError) if result != true && result != 0
            if @@cpoint
              cpoint = group.entities.add_cpoint(group.transformation.origin)
            end
            group.name = group_name
            set_mesh_dictionary(group,params) # always use params['scale']
            set_last_dictionary(params)       # always use @@scale
            #
          mod.commit_operation
          #
          #}#
        rescue => error
          mod.abort_operation
          announce_error( error, 'Error in add_mesh_to_model() method!' )
          retval = false
        else
          retval = group
          @mesh  = nil unless @@debug_mesh
        ensure
          if @@debug
            puts "\n#{PLUGNAME}: return from add_mesh_to_model()"
            puts "  result of group.entities.fill_from_mesh() was #{result.inspect}"
            puts "  return value: #{retval.inspect}"
          end
          return retval
        end
        #
      end # add_mesh_to_model()

      def add_polygon_to_mesh( pt1, pt2, pt3 )
        #
        if @@debug_mesh
          msg = "\n#{PLUGNAME}: add_polygon_to_mesh() method entry"
          puts "  pt1: #{pt1.inspect}"
          puts "  pt2: #{pt2.inspect}"
          puts "  pt3: #{pt3.inspect}"
        end
        #
        index = @mesh.add_polygon( pt1, pt2, pt3 )
        #
      ensure
        if @@debug_mesh
          puts "\n#{PLUGNAME}: return from add_polygon_to_mesh()"
          puts "  result of @mesh.add_polygon() was #{index.inspect}"
        end
      end

      def announce_error( exception, tagline )
      # Simplified edition.
        #
        msg  = "#{PLUGNAME}: #{tagline}"
        msg << "\nError: #{exception.inspect}"
        msg << "\n"
        msg << "\nBacktrace:\n"
        msg << exception.backtrace.join("\n")
        #
        if !@@debug
          UI.messagebox( msg, MB_MULTILINE, PLUGNAME )
        else
          puts msg<<"\n\n"
        end
        #
      end ### announce_error()

      def build_parameters( dict )
      # Build the parameter array from the dictionary reference,
      #   or initiate a default parameter array for those models
      #   that never before had a UV PolyGen mesh created in it.
      # Callers: 
        #
        if @@debug
          puts "\n#{PLUGNAME}: entry to build_parameters()"
          puts "  dict value: #{dict.inspect}"
        end
        #
        if dict.nil?
          # Model never before had a UV PolyGen mesh in it.
          params = init_parameters()
        else
          # Build the params array from the dictionary reference:
          #
          if dict['scale'].nil?
            # Likely an old v1 parameter dictionary. (no 'scale')
            scale = @@scale ? BOOLEAN[0] : BOOLEAN[1]
          else
            scale = dict['scale']=='true' ?  BOOLEAN[0] : BOOLEAN[1]
          end
          #
          if SURFENG.include?(dict['choice'])
          # Historical v1 last used dictionary used English surface name.
            choice = SURFACE[SURFENG.index(dict['choice'])]
          else
            choice = SURFACE[dict['choice'].to_i]
          end
          #
          params = [
            dict['u_start'],
            dict['u_end'],
            dict['u_steps'],
            dict['v_start'],
            dict['v_end'],
            dict['v_steps'],
            dict['xf'],
            dict['yf'],
            dict['zf'],
            dict['offset'],
            choice,
            dict['name'],
            scale
          ]
          #
        end
        #
        retval = params
        #
      rescue => error
        announce_error( error, 'Error in build_parameters() method!' )
        retval = nil
      ensure
        if @@debug
          puts "\n#{PLUGNAME}: return from build_parameters()"
          puts "  return value: #{retval.inspect}"
        end
        return retval
      end ### build_parameters()

      def create_uv_polygen()
      #
        #
        if @@debug || @@debug_mesh
          puts "\n#{PLUGNAME}: entry to create_uv_polygen()"
          puts "  @vars value: #{@vars.inspect}"
        end
        #
        us,ue,uc,ud,vs,ve,vc,vd,offset,surface,gname,autoscale,node = @vars
        #
        calced_num_points = (uc + 1) * (vc + 1)
        calced_num_polys  = uc * vc * 2
        #
        begin # building mesh:
          #
          @mesh = Geom::PolygonMesh.new( calced_num_points, calced_num_polys )
          #
          if offset.nil? || (offset == 0.0) # infinitesimal numerics still not == 0
            #
            for i in 0...uc
              for j in 0...vc
                add_polygon_to_mesh( node[i][j],   node[i+1][j], node[i][j+1]   )
                add_polygon_to_mesh( node[i][j+1], node[i+1][j], node[i+1][j+1] )
              end
            end
            #
          else
            #{# Create the offset points instead
            node2 = []
            np = vc
            sg = uc
            for j in 0..sg
              pt2 = []
              for i in 0..np
                if ( i != 0 && j != 0 && i != np && j != sg )
                  #{# in the middle
                  v1 = Geom::Vector3d.new(
                    node[j+1][i].x - node[j][i].x,
                    node[j+1][i].y - node[j][i].y,
                    node[j+1][i].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j][i+1].x - node[j][i].x,
                    node[j][i+1].y - node[j][i].y,
                    node[j][i+1].z - node[j][i].z
                  )
                  v3 = Geom::Vector3d.new(
                    node[j-1][i+1].x - node[j][i].x,
                    node[j-1][i+1].y - node[j][i].y,
                    node[j-1][i+1].z - node[j][i].z
                  )
                  v4 = Geom::Vector3d.new(
                    node[j-1][i].x - node[j][i].x,
                    node[j-1][i].y - node[j][i].y,
                    node[j-1][i].z - node[j][i].z
                  )
                  v5 = Geom::Vector3d.new(
                    node[j][i-1].x - node[j][i].x,
                    node[j][i-1].y - node[j][i].y,
                    node[j][i-1].z - node[j][i].z
                  )
                  v6 = Geom::Vector3d.new(
                    node[j+1][i-1].x - node[j][i].x,
                    node[j+1][i-1].y - node[j][i].y,
                    node[j+1][i-1].z - node[j][i].z
                  )
                  v = (v1 * v2).normalize +
                      (v2 * v3).normalize +
                      (v3 * v4).normalize +
                      (v4 * v5).normalize +
                      (v5 * v6).normalize +
                      (v6 * v1).normalize
                  #}#
                elsif ( i == 0 && j == 0 )
                  #{# lower left corner
                  v1 = Geom::Vector3d.new(
                    node[j+1][i].x - node[j][i].x,
                    node[j+1][i].y - node[j][i].y,
                    node[j+1][i].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j][i+1].x - node[j][i].x,
                    node[j][i+1].y - node[j][i].y,
                    node[j][i+1].z - node[j][i].z
                  )
                  v = v1 * v2
                  #}#
                elsif ( i == 0 && j == sg )
                  #{# lower right corner
                  v1 = Geom::Vector3d.new(
                    node[j][i+1].x - node[j][i].x,
                    node[j][i+1].y - node[j][i].y,
                    node[j][i+1].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j-1][i+1].x - node[j][i].x,
                    node[j-1][i+1].y - node[j][i].y,
                    node[j-1][i+1].z - node[j][i].z
                  )
                  v3 = Geom::Vector3d.new(
                    node[j-1][i].x - node[j][i].x,
                    node[j-1][i].y - node[j][i].y,
                    node[j-1][i].z - node[j][i].z
                  )
                  v = (v1 * v2).normalize +
                      (v2 * v3).normalize
                  #}#
                elsif ( i == np && j == 0 )
                  #{# upper left corner
                  v1 = Geom::Vector3d.new(
                    node[j][i-1].x - node[j][i].x,
                    node[j][i-1].y - node[j][i].y,
                    node[j][i-1].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j+1][i-1].x - node[j][i].x,
                    node[j+1][i-1].y - node[j][i].y,
                    node[j+1][i-1].z - node[j][i].z
                  )
                  v3 = Geom::Vector3d.new(
                    node[j+1][i].x - node[j][i].x,
                    node[j+1][i].y - node[j][i].y,
                    node[j+1][i].z - node[j][i].z
                  )
                  v = (v1 * v2).normalize +
                      (v2 * v3).normalize
                  #}#
                elsif ( i == np && j == sg )
                  #{# upper right corner
                  v1 = Geom::Vector3d.new(
                    node[j-1][i].x - node[j][i].x,
                    node[j-1][i].y - node[j][i].y,
                    node[j-1][i].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j][i-1].x - node[j][i].x,
                    node[j][i-1].y - node[j][i].y,
                    node[j][i-1].z - node[j][i].z
                  )
                  v = v1 * v2
                  #}#
                elsif ( i == 0 )
                  #{# lower edge
                  v1 = Geom::Vector3d.new(
                    node[j+1][i].x - node[j][i].x,
                    node[j+1][i].y - node[j][i].y,
                    node[j+1][i].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j][i+1].x - node[j][i].x,
                    node[j][i+1].y - node[j][i].y,
                    node[j][i+1].z - node[j][i].z
                  )
                  v3 = Geom::Vector3d.new(
                    node[j-1][i+1].x - node[j][i].x,
                    node[j-1][i+1].y - node[j][i].y,
                    node[j-1][i+1].z - node[j][i].z
                  )
                  v4 = Geom::Vector3d.new(
                    node[j-1][i].x - node[j][i].x,
                    node[j-1][i].y - node[j][i].y,
                    node[j-1][i].z - node[j][i].z
                  )
                  v = (v1 * v2).normalize +
                      (v2 * v3).normalize +
                      (v3 * v4).normalize
                  #}#
                elsif ( i == np )
                  #{# upper edge
                  v1 = Geom::Vector3d.new(
                    node[j-1][i].x - node[j][i].x,
                    node[j-1][i].y - node[j][i].y,
                    node[j-1][i].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j][i-1].x - node[j][i].x,
                    node[j][i-1].y - node[j][i].y,
                    node[j][i-1].z - node[j][i].z
                  )
                  v3 = Geom::Vector3d.new(
                    node[j+1][i-1].x - node[j][i].x,
                    node[j+1][i-1].y - node[j][i].y,
                    node[j+1][i-1].z - node[j][i].z
                  )
                  v4 = Geom::Vector3d.new(
                    node[j+1][i].x - node[j][i].x,
                    node[j+1][i].y - node[j][i].y,
                    node[j+1][i].z - node[j][i].z
                  )
                  v = (v1 * v2).normalize +
                      (v2 * v3).normalize +
                      (v3 * v4).normalize
                  #}#
                elsif ( j == 0 )
                  #{# left edge
                  v1 = Geom::Vector3d.new(
                    node[j][i-1].x - node[j][i].x,
                    node[j][i-1].y - node[j][i].y,
                    node[j][i-1].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j+1][i-1].x - node[j][i].x,
                    node[j+1][i-1].y - node[j][i].y,
                    node[j+1][i-1].z - node[j][i].z
                  )
                  v3 = Geom::Vector3d.new(
                    node[j+1][i].x - node[j][i].x,
                    node[j+1][i].y - node[j][i].y,
                    node[j+1][i].z - node[j][i].z
                  )
                  v4 = Geom::Vector3d.new(
                    node[j][i+1].x - node[j][i].x,
                    node[j][i+1].y - node[j][i].y,
                    node[j][i+1].z - node[j][i].z
                  )
                  v = (v1 * v2).normalize +
                      (v2 * v3).normalize +
                      (v3 * v4).normalize
                  #}#
                else
                  #{# right edge
                  v1 = Geom::Vector3d.new(
                    node[j][i+1].x - node[j][i].x,
                    node[j][i+1].y - node[j][i].y,
                    node[j][i+1].z - node[j][i].z
                  )
                  v2 = Geom::Vector3d.new(
                    node[j-1][i+1].x - node[j][i].x,
                    node[j-1][i+1].y - node[j][i].y,
                    node[j-1][i+1].z - node[j][i].z
                  )
                  v3 = Geom::Vector3d.new(
                    node[j-1][i].x - node[j][i].x,
                    node[j-1][i].y - node[j][i].y,
                    node[j-1][i].z - node[j][i].z
                  )
                  v4 = Geom::Vector3d.new(
                    node[j][i-1].x - node[j][i].x,
                    node[j][i-1].y - node[j][i].y,
                    node[j][i-1].z - node[j][i].z
                  )
                  v = (v1 * v2).normalize +
                      (v2 * v3).normalize +
                      (v3 * v4).normalize
                  #}#
                end
                #
                v.length = offset
                ptmp = node[j][i].offset( v )
                pt2 << ptmp
              end # for i
              node2 << pt2
            end # for j
            #}#
            #
            #{# Handle Surface option:
            case surface
            when 0  # Offset Surface
              for j in 0...uc
                for i in 0...vc
                  add_polygon_to_mesh( node2[j][i],   node2[j+1][i], node2[j][i+1] )
                  add_polygon_to_mesh( node2[j][i+1], node2[j+1][i], node2[j+1][i+1] )
                end
              end
            when 1  # Side 1
              for j in 0...uc
                add_polygon_to_mesh( node2[j][0],   node[j][0],    node[j+1][0] )
                add_polygon_to_mesh( node[j+1][0], node2[j+1][0], node2[j][0] )
              end
            when 2  # Side 2
              for j in 0...uc
                add_polygon_to_mesh( node2[j][np],  node2[j+1][np], node[j][np] )
                add_polygon_to_mesh( node2[j+1][np], node[j+1][np], node[j][np] )
              end
            when 3  # End 1
              for i in 0...vc
                add_polygon_to_mesh( node[0][i],  node2[0][i],   node[0][i+1] )
                add_polygon_to_mesh( node2[0][i], node2[0][i+1], node[0][i+1] )
              end
            when 4  # End 2
              for i in 0...vc
                add_polygon_to_mesh( node2[sg][i], node[sg][i],   node2[sg][i+1] )
                add_polygon_to_mesh( node[sg][i],  node[sg][i+1], node2[sg][i+1] )
              end
            end # case surface
            #}#
            #
          end # if offset
          #
        end # building mesh.
        #
        retval = @mesh
        #
      rescue => error
        announce_error( error, 'Error in create_uv_polygen() method!' )
        retval = nil
      ensure
        if @@debug || @@debug_mesh
          puts "\n#{PLUGNAME}: return from create_uv_polygen()"
          puts "  return value: #{retval.inspect}"
          if retval.is_a?(Geom::PolygonMesh)
            puts "  mesh points:"
            puts "    calc'ed = #{calced_num_points}"
            puts "    actuals = #{retval.count_points}"
            puts "  mesh polygons:"
            puts "    calc'ed = #{calced_num_polys}"
            puts "    actuals = #{retval.count_polygons}"
          else
            puts "  Whoops! Return was not a Geom::PolygonMesh object!"
          end
        end
        return retval
      end # create_uv_polygen()

      def do_cpoint_toggle()
      # Toggle flag for guidepoint at origin.
      # Toggles guidepoint at origin on / off.
        #
        @@cpoint = !@@cpoint
        @@cpoint_check = @@cpoint ? MF_CHECKED : MF_UNCHECKED
        Sketchup::write_default(OPTSKEY,'cpoint',@@cpoint ? true : false)
        #
      end ### do_cpoint_toggle()

      def do_mesh_command()
      # Returns false if user cancelled the command.
      # Returns false if error. (Should we return nil ?)
      # Returns grouped mesh upon success.
      # 
        #
        if @@debug
          puts "\n#{PLUGNAME}: entry to do_mesh_command()"
        end
        #
        # We reference pre-validated parameter array as: fields
        # We reference post-validated parameter array as: params
        #
        dict = get_last_dictionary()
          # Returns nil if active_model never had a polygen mesh.
        fields = build_parameters( dict )
          # Returns a valid parameter array, (whether dict valid or nil.)
        params = get_parameters( fields )
          # Returns false if user cancelled this command.
        return false if !params
          # The get_parameters() method set creation variables in @vars
        mesh = create_uv_polygen()
          # If no errors, mesh is a new Geom::PolygonMesh object.
        return false unless mesh && mesh.count_polygons>0
          # UNDOTXT[:undo] contains "UV Mesh:"
          # Undo menutext & tooltip should read like: 'Undo UV Mesh: "#{name}"'
        if params[11].empty?
          op_name = "#{UNDOTXT[:undo]} \"{x,y,z} = f(u,v)\""
        else
          op_name = "#{UNDOTXT[:undo]} \"#{params[11]}\""
        end
          # Within an undo operation, add the mesh to the model 
          # then update the mesh and last used dictionaries.
        retval = add_mesh_to_model( mesh, params, op_name )
          # Returns false if error, grouped mesh upon success.
      rescue => error
        announce_error( error, 'Error in do_mesh_command method!' )
        retval = false
      ensure
        if @@debug
          puts "\n#{PLUGNAME}: return from do_mesh_command()"
          puts "  return value: #{retval.inspect}"
        end
        @vars.clear if @vars && !@vars.empty?
        return retval
      end ### do_mesh_command()

      def do_scale_toggle()
      # Toggle flag for scale to model unit.
        #
        @@scale = !@@scale
        @@scale_check = @@scale ? MF_CHECKED : MF_UNCHECKED
        Sketchup::write_default(OPTSKEY,'scale',@@scale ? true : false)
        #
      end ### do_scale_command()

      def get_last_dictionary()
      # Gets a reference to the last used parameter dictionary
      # that is attached at the model level. 
      # Does NOT & should NOT create nor modify the dictionary!
      # May be called before the undo operation starts, to
      # read the old historical parameters for user input.
      # But the user might cancel during the process of input.
        #
        parent = get_last_dictionary_parent()
        dictname = get_last_dictionary_name()
        dict = parent.attribute_dictionary(dictname,false)
        #
        if dict.nil?
          # Check if there is a historical attribute dictionary
          # attached to historical dictionary parent object:
          last_ver = EXTENSION.version.to_i-1
          if last_ver > 0
            last_ver.downto(1) {|ver|
              parent = get_last_dictionary_parent(ver)
              histname = get_last_dictionary_name(ver)
              next if histname.nil? || histname.empty?
              next if histname == dictname # update instead of delete
              dict = parent.attribute_dictionary(histname,false)
              break dict if !dict.nil?
            }
          end
        end
        #
        return dict
        #
      end ### get_last_dictionary()

      def get_last_dictionary_name(
        ver = EXTENSION.version.to_i
      )
      # Gets a reference to the name of the last used
      # parameter dictionary, for the version specified.
      # Default argument is the current version.
      #
      # @param ver [Integer] Major version of UV PolyGen extension.
      #   #to_i() will be called upon argument. So it can be version
      #   string, a float, or major version integer.
      #
      # @return [String] The name of last used parameter dictionary.
        # See file: "uv_polygen.rb", section 1, "NOTICE"
        #
        case ver.to_i
        when 1
          DICTLAST1 # DO NOT CHANGE - HISTORICAL
        when 2
          # IF changed after release, copy old DICTLAST
          # string to DICTLAST2, in file "uv_polygen.rb",
          # and change reference here to DICTLAST2, then
          # bump major version to next ordinal number.
          DICTLAST
        else
          DICTLAST # Assume this is latest going forward.
        end
        #
      end ### get_last_dictionary_name()

      def get_last_dictionary_parent(
        ver = EXTENSION.version.to_i
      )
      # Gets a reference to the object that the last used
      # parameter dictionary is assigned to be attached to.
      # @param ver [Integer] major version of UV PolyGen extension
      #   #to_i() will be called upon argument. So it can be version
      #   string, a float, or major version integer.
      # @return [Sketchup::Model,Sketchup::Entity]
        #
        # This object must be a singleton unique to each model.
        # It can be the model itself, or a singleton Entity
        # subclass, such as a model toplevel collection.
        #
        case ver.to_i
        when 1
          # Versions 1.x attached to the model as DICTLAST1
          Sketchup.active_model # DO NOT CHANGE - HISTORICAL
        when 2
          Sketchup.active_model
        else
          Sketchup.active_model
        end
        #
      end ### get_last_dictionary_parent()

      def get_mesh_dictionary_name(
        ver = EXTENSION.version.to_i
      )
      # Gets a reference to the name of the individual mesh 
      # parameter dictionary, for the version specified.
      # Default argument is the current version.
      #
      # @param ver [Integer] major version of UV PolyGen extension
      #   #to_i() will be called upon argument. So it can be version
      #   string, a float, or major version integer.
      #
      # @return [String] The name of the mesh parameter dictionary.
        #
        # See file: "uv_polygen.rb", section 1, "NOTICE"
        #
        case ver.to_i
        when 1
          DICTMESH1 # DO NOT CHANGE - HISTORICAL (nil)
        when 2
          # IF changed after release, copy old DICTMESH
          # string to DICTMESH2, in file "uv_polygen.rb",
          # and change reference here to DICTMESH2, then
          # bump major version to next ordinal number.
          DICTMESH
        else
          DICTMESH # Assume this is latest going forward.
        end
        #
      end ### get_last_dictionary_name()

      def get_parameters( fields )
      #
      # Callers: do_mesh_command()
        #
        if @@debug
          puts "\n#{PLUGNAME}: entry to get_parameters()"
          puts "  fields value: #{fields.inspect}"
        end
        #
        # Validate the parameter fields:
        #
        caption = INPUT_TITLE
        # Keep fields intact in case of user reset:
        input   = fields.map{|s| s.dup }
        #
        begin
          #
          input = get_user_input( input, caption )
          #
          if input == false # false if user cancelled inputbox
            if @@retry
              reset = UI.messagebox(RETRY,MB_RETRYCANCEL)
              fail(RetryException) if reset == IDRETRY
            end
            return false
          end
          #
          # input[12] from boolean choice in local language
          autoscale = input[12]==BOOLEAN[0] ? true : false
          #
          # Check eval'd fields for "no-no"s:
          input[0..9].each_with_index {|p,i|
            #
            # Check for :: scope operator:
            fail(ParameterError,"(#{i+1}): #{ERRORTXT[:scope]}") if p =~ /(\:\:)/
            #
            # Check for call to Calc control or validation methods:
            if 
            p =~ /(control|fail|floatval|ieval|initialize|intval|
            node|module_eval|puts|raise|test|call|send|__send__)/
              fail(ParameterError,"(#{i+1}): #{ERRORTXT[:eval]}")
            end
            #
            # Check for call to eval or other global methods:
            if 
            p =~ /(`|abort|binding|caller|catch|class_eval|eval|eql|equal|exec|
            exit|fail|false|fatal|fork|initialize|instance_eval|loop|new|open|
            method_missing|proc|raise|read|readline|readlines|select|sleep|warn|
            set_trace_func|syscall|system|throw|tracevar|trap|true|untrace_var)/
              fail(ParameterError,"(#{i+1}): #{ERRORTXT[:eval]}")
            end
            #
            # Check for call to dangerous base classes:
            if p =~ /(BasicObject|Binding|Class|Dir|Error|Fiber|File|GC|
            Interrupt|IO|Kernel|Math|Method|Marshal|Module|Mutex|Object|
            Proc|Process|Signal|Socket|SKSocket|System|Thread|UnboundMethod)/
              fail(ParameterError,"(#{i+1}): #{ERRORTXT[:class]}")
            end
            #
            # Check for call to other base classes:
            if p =~ /(Array|Bignum|Comparable|Continuation|Complex|Data|
            Enumerable|Enumerator|Errno|Error|Exception|FalseClass|Fixnum|
            Float|Geom|Hash|Integer|Length|Numeric|NilClass|Precision|
            Range|Rational|Sketchup|String|Struct|Symbol|TrueClass|UI)/
              fail(ParameterError,"(#{i+1}): #{ERRORTXT[:class]}")
            end
            #
          }
          #
          calc = Calc::new(autoscale) # the safer calculation namespace
          #
          ### Validate us, ue & uc:
            #
            msg = ERRORTXT[:float]
            us = calc.floatval(input[0]) rescue fail(ParameterError,"(1): "<<msg)
            ue = calc.floatval(input[1]) rescue fail(ParameterError,"(2): "<<msg)
            msg = ERRORTXT[:range]
            fail(ParameterError,"(2): "<<msg) if (ue - us)==0.0
            msg = ERRORTXT[:toint]
            uc = calc.intval(input[2]) rescue fail(ParameterError,"(3): "<<msg)
            uc = uc.abs
            msg = ERRORTXT[:steps] # be sure u steps are not zero:
            fail(ParameterError,"(3): "<<msg) if uc < 1
            #
            # Test the ud division:
            ud = (ue - us) / uc.to_f
            # Test for infinity or nan:
            msg = ERRORTXT[:uinfi]
            fail(ParameterError,"(3): "<<msg) unless ud.finite?
            #
          ### Validate vs, ve & vc:
            #
            vs = calc.floatval(input[3]) rescue fail(ParameterError,"(4): "<<msg)
            ve = calc.floatval(input[4]) rescue fail(ParameterError,"(5): "<<msg)
            msg = ERRORTXT[:range]
            fail(ParameterError,"(5): "<<msg) if (ve - vs)==0.0
            #
            msg = ERRORTXT[:toint]
            vc = calc.intval(input[5]) rescue fail(ParameterError,"(6): "<<msg)
            vc = vc.abs
            msg = ERRORTXT[:steps] # be sure v steps are not zero:
            fail(ParameterError,"(6): "<<msg) if vc < 1
            #
            # Test the vd division:
            vd = (ve - vs) / vc.to_f
            # Test for infinity or nan:
            msg = ERRORTXT[:vinfi]
            fail(ParameterError,"(6): "<<msg) unless vd.finite?
            #
          ### Create some test values for validating x, y & z:
            #
            tud = Math::PI/10 # test ud value
            tvd = Math::PI/10 # test vd value
            u   = -Math::PI/2 * tud # test u value
            v   = -Math::PI/2 * tvd # test v value
            msg = ERRORTXT[:float]
            #
          ### Validate x:
            #
            tx = "x = #{input[6]}"
            tx = calc.test(tx,u,v) rescue fail(ParameterError,"(7): "<<msg)
            fail(ParameterError,"(7): "<<tx.message) if tx.is_a?(Exception)
            fail(ParameterError,"(7): "<<msg) unless tx.is_a?(Float)
            #
            fx = input[6]
            #
          ### Validate y:
            #
            ty = "y = #{input[7]}"
            ty = calc.test(ty,u,v) rescue fail(ParameterError,"(8): "<<msg)
            fail(ParameterError,"(8): "<<ty.message) if ty.is_a?(Exception)
            fail(ParameterError,"(8): "<<msg) unless ty.is_a?(Float)
            #
            fy = input[7]
            #
          ### Validate z:
            #
            tz = "z = #{input[8]}"
            tz = calc.test(tz,u,v) rescue fail(ParameterError,"(9): "<<msg)
            fail(ParameterError,"(9): "<<tz.message) if tz.is_a?(Exception)
            fail(ParameterError,"(9): "<<msg) unless tz.is_a?(Float)
            #
            fz = input[8]
            #
          ### Validate offset:
            #
            msg = ERRORTXT[:float]
            n = input[9].strip
            if n.empty?
              offset = nil
              input[9]= Calc::DECPT ? '0.0' : '0,0'
            elsif n =~ /\A(nil|none|no|null)\z/i
              offset = nil
            elsif ['0','0.0','0,0','.0',',0','0.','0,'].include?(n)
              offset = nil
              input[9]= Calc::DECPT ? '0.0' : '0,0'
            else
              o = calc.floatval(n) rescue fail(ParameterError,"(10): "<<msg)
              if calc.scale != 1.0 && autoscale
                # Scale offset to the model unit:
                offset = o * calc.scale
              else
                offset = o
              end
              # check that offset is >= SketchUp's tolerance of 0.001":
              msg = ERRORTXT[:obtol]
              unless offset.abs >= 0.001
                if autoscale
                  # We create our own unit string because Length.to_s() and
                  # Sketchup.format_length() both round to precision setting.
                  # This can result in strange error messages
                  o = offset / calc.scale
                  fail(ParameterError,"(10): #{o}#{calc.sym} "<<msg)
                else
                  fail(ParameterError,"(10): #{offset}\" "<<msg)
                end
              end
            end
            #
          ### Create node:
          #
          node = calc.node(fx,fy,fz,uc,ud,us,vc,vd,vs)
          #
          # input[10] from choice in locale language
          surface = SURFACE.index(input[10])
          #
          # input[11] is already stripped of leading and trailing whitespace.
          gname = input[11]
          #
        rescue RetryException
          # Reset the input array & window caption, then retry:
          input = fields.map{|s| s.dup }
          caption = INPUT_TITLE
          retry
        rescue ParameterError => e
          caption = "#{ERRORTXT[:param]}"<<e.message
          retry
        rescue => e # StandardError & subclasses
          caption = "#{ERRORTXT[:error]}: "<<e.message
          retry
        else
          #
          @vars = [us,ue,uc,ud,vs,ve,vc,vd,offset,surface,gname,autoscale,node]
          #
        end
        #
        return input
        #
      ensure
        if @@debug
          puts "\n#{PLUGNAME}: return from get_parameters()"
          puts "  return value: #{input.inspect}"
        end
      end ### get_parameters()

      def get_user_input( params, caption = nil )
      # The primary inputbox control loop.
      # Callers: get_parameters()
        #
        caption = INPUT_TITLE if caption.nil?
        # Pad the 'name' field to cause a wide input width:
        input_width = INPUT_WIDTH-params[11].size
        params[11]= "%-#{input_width}s" % params[11]
        #params[11]= params[11]+(' '*(INPUT_WIDTH-params[11].size))
        #
        begin
          input = UI.inputbox( PROMPTS, params, LIST, caption )
          if input # user did not cancel
            input[11].strip! # de-pad the 'name' field
          end
        rescue => e
          # API UI.inputbox() will raise an exception upon type mismatch;
          # if any entered value cannot be converted to it's original type.
          # So grab the exception message, set it as the caption and retry:
          caption = 'Error: '<<e.message
          retry
          # NOTE: These inputbox type errors are cryptic and confusing to
          # users not familiar with SketchUp's Ruby engine. They also do
          # not tell user what actual input field had the typing issue.
          # Therefore we will switch to all string parameter fields, and
          # do input validation ourselves in the method that calls this one.
          # This way we can control what error message is displayed to the
          # user in the window caption, and also show the parameter number.
        else
          return input  # false if user cancelled inputbox
        end
        #
      end ### 

      def init_dictionary( dict )
      # Must be called from within an undo operation !
      #
        #
        dict['u_start']= PARAMS['u_start']
        dict['u_end']=   PARAMS['u_end']
        dict['u_steps']= PARAMS['u_steps']
        dict['v_start']= PARAMS['v_start']
        dict['v_end']=   PARAMS['v_end']
        dict['v_steps']= PARAMS['v_steps']
        dict['xf']=      PARAMS['xf']
        dict['yf']=      PARAMS['yf']
        dict['zf']=      PARAMS['zf']
        dict['offset']=  PARAMS['offset']
        dict['name']=    PARAMS['name']
        #
        dict['choice']=  PARAMS['choice']
        #
        dict['scale']=   PARAMS['scale']
        #
        return dict
        #
      end ### init_dictionary()

      def init_parameters()
      # Initiates an array of parameters using the default values
      #   in the PARAMS hash. Occurs once for new models, or those
      #   that never before had a UV PolyGen mesh created in it.
      # Callers: build_parameters()
        #
        params = [
          PARAMS['u_start'],
          PARAMS['u_end'],
          PARAMS['u_steps'],
          PARAMS['v_start'],
          PARAMS['v_end'],
          PARAMS['v_steps'],
          PARAMS['xf'],
          PARAMS['yf'],
          PARAMS['zf'],
          PARAMS['offset'],
          SURFACE[PARAMS['choice'].to_i],
          PARAMS['name'],
          PARAMS['scale']=='true' ?  BOOLEAN[0] : BOOLEAN[1]
        ]
        #
        return params
        #
      end ### init_parameters()

      def init_var_array()
      # Called at end of this file, from outer plugin module.
        @vars = []
      end

      def set_last_dictionary( 
        params = init_parameters()
      )
      # Must be called from within an undo operation !
        #
        dictname = get_last_dictionary_name()
        # Check if there is a historical attribute dictionary
        # attached to historical dictionary parent object:
        last_ver = EXTENSION.version.to_i-1
        if last_ver > 0
          last_ver.downto(1) {|ver|
            parent = get_last_dictionary_parent(ver)
            histname = get_last_dictionary_name(ver)
            next if histname.nil? || histname.empty?
            next if histname == dictname # update instead of delete
            if parent.attribute_dictionaries[histname]
              parent.attribute_dictionaries.delete(histname)
            end
          }
        end
        #
        parent = get_last_dictionary_parent()
        dict = parent.attribute_dictionary(dictname,true)
        if dict
          dict = update_dictionary( dict, params )
        else
          fail(AttrDictCreateError,"Error creating attribute dictionary: '#{dictname}'.")
        end
        #
        return dict
        #
      end # set_last_dictionary()

      def set_mesh_dictionary( meshgrp, params )
      # Must be called from within an undo operation !
      # Callers: add_mesh_to_model()
        #
        dictname = get_mesh_dictionary_name()
        # Check if there is an old attribute dictionary
        # attached to current mesh object:
        last_ver = EXTENSION.version.to_i-1
        if last_ver > 1
          # Began with v2, so don't need until v3, at least.
          last_ver.downto(2) {|ver|
            histname = get_mesh_dictionary_name(ver)
            next if histname.nil? || histname.empty?
            next if histname == dictname # update instead of delete
            if meshgrp.attribute_dictionaries[histname]
              meshgrp.attribute_dictionaries.delete(histname)
            end
          }
        end
        #
        dict = meshgrp.attribute_dictionary(dictname,true)
        if dict
          dict = update_dictionary( dict, params )
        else
          fail(AttrDictCreateError,"Error creating mesh attribute dictionary: '#{dictname}'.")
        end
        #
        return dict
        #
      end # set_mesh_dictionary()

      def update_dictionary( dict, params )
      # Updates an attribute dictionary that already exists.
      # Must be called from within an undo operation !
      #
      # @return [Sketchup::AttributeDictionary]
        # Callers: set_last_dictionary(), set_mesh_dictionary()
        #
        dict['u_start']= params[0]
        dict['u_end']=   params[1]
        dict['u_steps']= params[2]
        dict['v_start']= params[3]
        dict['v_end']=   params[4]
        dict['v_steps']= params[5]
        dict['xf']=      params[6]
        dict['yf']=      params[7]
        dict['zf']=      params[8]
        dict['offset']=  params[9]
        dict['name']=    params[11]
        #
        dict['choice']=  SURFACE.index(params[10]).to_s rescue "0"
        #
        coll = dict.parent # AttributeDictionaries collection
        if coll.parent == get_last_dictionary_parent()
          # then updating the last used parameters
          # & was called from: set_last_dictionary()
          dict['scale']= @@scale.to_s
        else
          # then updating a mesh group's parameters
          # & was called from: set_mesh_dictionary()
          dict['scale']= params[12]==BOOLEAN[0] ? 'true' : 'false'
        end
        #
        return dict
        #
      end # update_dictionary()


    end # singleton proxy class instance

    init_var_array()


  end # module UVPolyGen
  
end # module Jimhami42
