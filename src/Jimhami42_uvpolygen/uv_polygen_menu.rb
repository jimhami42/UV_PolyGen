# encoding: UTF-8
# uv_polygen_menu.rb
#{ ===========================================================================
#  DETAILS:
#
#  UI menu & command definitions for U-V Polygon Mesh Generator Plugin.
#
# ----------------------------------------------------------------------------
#  COPYRIGHT(S):
#
#  (C) 2014 by Jim Hamilton (Jimhami42 at GitHub.com)
#  (C) 2015 by Daniel A. Rathbun
#
#} ===========================================================================

require 'sketchup.rb'

module Jimhami42  # Jim Hamilton's toplevel namespace
  
  module UVPolyGen # plugin module

    #{# RUN ONCE UPON STARTUP
    #
      thisfile = "#{OPTSKEY}:"<<File.basename(__FILE__)

      unless file_loaded?(thisfile)

        # ----------------------------------------------

        COMMANDS = {}

        COMMANDS[:mesh]= UI::Command.new('Create UV Mesh...') {
          do_mesh_command()
        }

        COMMANDS[:scale]= UI::Command.new('Scale to Model Unit') {
          do_scale_toggle()
        }
        COMMANDS[:scale].set_validation_proc { @@scale_check }

        COMMANDS[:cpoint]= UI::Command.new('Guidepoint at Origin') {
          do_cpoint_toggle()
        }
        COMMANDS[:cpoint].set_validation_proc { @@cpoint_check }

        # ----------------------------------------------

        submenu = UI.menu('Plugins').add_submenu('U-V PolyGen')

        # ----------------------------------------------

        submenu.add_item(COMMANDS[:mesh])

        submenu.add_separator

        submenu.add_item(COMMANDS[:scale])
        submenu.add_item(COMMANDS[:cpoint])

        # ----------------------------------------------

        UI.add_context_menu_handler {|popup|
          if Sketchup.active_model.selection.length == 0
            popup.add_item(COMMANDS[:mesh])
          end
        }

        # ----------------------------------------------
        file_loaded(thisfile)
        # ----------------------------------------------

      end
    #
    #}#

  end # module UVPolyGen
  
end # module Jimhami42
