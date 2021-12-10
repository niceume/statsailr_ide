module SpaceGtk3
module Operators
class PlotView
  attr :plot_copy_cb

  def initialize()

    @plot_copy_cb = lambda{|widget, data|
      drawing_area = data["drawing_area"]
      gdk_win = drawing_area.get_window
      image_width = drawing_area.get_allocated_width
      image_height = drawing_area.get_allocated_height

      src_x = 0
      src_y = 0

      pixbuf = Gdk.pixbuf_get_from_window(gdk_win, src_x, src_y,image_width, image_height)
      Gtk::Clipboard.get_default(Gdk::Display.get_default).set_image(pixbuf)
    }

  end

end
end
end
