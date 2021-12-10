module SpaceGtk3
module Utility
  module Glade
    def self.collect_widgets(gtk_builder, names)
      widget_hash = {}
      names.each{|name|
        widget_hash[name] = gtk_builder.get_object(name)
      }
      return widget_hash
    end
  end
end
end
