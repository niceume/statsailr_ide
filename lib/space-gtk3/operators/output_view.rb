module SpaceGtk3
module Operators
class OutputView
  attr :output_clear_cb, :output_add_str_cb, :output_scroll_down_to_bottom_cb, :output_scroll_up_to_top_cb

  def initialize()
    @output_clear_cb = lambda{| widget, data |
      textview = data["textview"]
      Utility::Textview.textview_clear(textview)
    }

    @output_add_str_cb = lambda{| widget, data |
      textview = data["textview"]
      str = data["str"]
      Utility::Textview.textview_append(textview, str)
    }

    @output_scroll_down_to_bottom_cb = lambda{| widget, data|
      scroll_win = data["scroll_win"]
      vadj = scroll_win.get_vadjustment()
      vadj.set_value(vadj.get_upper() - vadj.get_page_size())
    }

    @output_scroll_up_to_top_cb = lambda{| widget, data|
      scroll_win = data["scroll_win"]
      vadj = scroll_win.get_vadjustment()
      vadj.set_value(vadj.get_page_size() - vadj.get_upper())
    }
  end

end
end
end
