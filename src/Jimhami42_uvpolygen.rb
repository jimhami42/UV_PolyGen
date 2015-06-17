# encoding: UTF-8
#{ ===========================================================================
#{ DETAILS:
#
#  Name        :  UV Polygen
#
#  Description :  U-V Polygon Mesh Generator Plugin with Offset Surfaces.
#
#  Menu Item   :  Extensions > U-V PolyGen
#
#  Date        :  2014-07-04 - original release of v1.0
#
#  License     :  MIT License
#
#  Revisions   :  see "Jimhami42_uvpolygen/uv_polygen_revsions.md"
#
#}----------------------------------------------------------------------------
#{ COPYRIGHT(S):
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
#}
#}============================================================================


if !defined?(Sketchup) || Sketchup::version.to_i < 6
  fail(NotImplementedError,"UV PolyGen only runs on SketchUp v6 or higher",caller)
end

require 'sketchup.rb'
require 'extensions.rb'

# ----------------------------------------------------------------------------

module Jimhami42  # Jim Hamilton's toplevel namespace
  module UVPolyGen
  
    # In SU2014, with Ruby 2.0 the __FILE__ constant return an UTF-8 string with
    # incorrect encoding label which will cause load errors when the file path
    # contain multi-byte characters. This happens when the user has non-English
    # characters in their username.
    current_path = File.dirname(__FILE__)
    if current_path.respond_to?(:force_encoding)
      current_path.force_encoding('UTF-8')
    end

    PLUGIN_ROOT_PATH = current_path.freeze
    PLUGIN_PATH      = File.join(PLUGIN_ROOT_PATH, 'Jimhami42_uvpolygen').freeze


    # The extension instance:

    EXTENSION = SketchupExtension.new(
      "U-V PolyGen",
      File.join(PLUGIN_PATH, "uv_polygen.rb")
    )

    EXTENSION.version   = "2.0"
    EXTENSION.creator   = "Jim Hamilton & other contributors."
    EXTENSION.copyright = "2014..2015, under the MIT License"

    EXTENSION.description = "U-V Polygon Mesh Generator Plugin for SketchUp with Offset Surfaces."

    Sketchup.register_extension( EXTENSION, true )

  end # plugin module

end # toplevel module
