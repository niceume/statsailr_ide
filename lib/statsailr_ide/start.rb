require "set"
require "gir_ffi-gtk3"
# require "gir_ffi-cairo"

module StatSailrIDE
  MAIN_WINDOW_WIDTH = 800
  MAIN_WINDOW_HEIGHT = 600

def self.start()

## Start Gtk

Gtk.init
GirFFI.setup :GtkSource


## Notebook Space ##

$nb_builder = Gtk::Builder.new()
$nb_builder.add_from_file( __dir__ + "/glade/" + "1_notebook_widget.glade")

### Obtain Widgets via Glade 
nb_widgets = SpaceGtk3::Utility::Glade::collect_widgets( $nb_builder, [
  "code_notebook",
  "code_add_page_button",
  "code_open_file_button",
  "code_close_page_button",
  "code_save_page_as_button",
  "code_save_page_button",
  "code_run_all_button",
  "code_run_selected_button"
])

nb = SpaceGtk3::Operators::CodeNotebook.new( )

nb.add_page_cb.call( nb, {"notebook" => nb_widgets["code_notebook"] } ) # Open one page at startup

nb.custom_after_save_cb = lambda{
  nb_widgets["code_save_page_button"].set_sensitive(false)
}

### Signal connection

GObject.signal_connect(nb_widgets["code_add_page_button"], "clicked", {"notebook" => nb_widgets["code_notebook"] }, &nb.add_page_cb )
GObject.signal_connect(nb_widgets["code_close_page_button"], "clicked", {"notebook" => nb_widgets["code_notebook"], "ask_save_page_cb" => nb.ask_save_page_cb }, &nb.close_page_cb )
GObject.signal_connect(nb_widgets["code_save_page_as_button"], "clicked", {"notebook" => nb_widgets["code_notebook"] }, &nb.save_page_as_cb )
GObject.signal_connect(nb_widgets["code_save_page_button"], "clicked", {"notebook" => nb_widgets["code_notebook"] }, &nb.save_page_cb )
GObject.signal_connect(nb_widgets["code_open_file_button"], "clicked", {"notebook" => nb_widgets["code_notebook"] }, &nb.open_file_cb )


custom_page_added_cb = lambda{|notebook, child, num, data|
  nb_widgets["code_save_page_button"].set_sensitive( false )
  GObject.signal_connect(child.get_child().get_buffer(), "modified-changed", {}){|buffer|
    nb_widgets["code_save_page_button"].set_sensitive( buffer.get_modified() )
  }
}

GObject.signal_connect(nb_widgets["code_notebook"], "page-added", {"notebook" => nb_widgets["code_notebook"] }, &custom_page_added_cb )




## Output View Space ##

$output_view_builder = Gtk::Builder.new()
$output_view_builder.add_from_file( __dir__ + "/glade/" + "2_output_widget.glade")

### Obtain Widgets via Glade 
output_widgets = SpaceGtk3::Utility::Glade::collect_widgets( $output_view_builder, [
  "output_clear_button",
  "output_scroll_bottom",
  "output_scroll_top",
  "output_add_text",
  "output_check_autoscroll",
  "output_scroll_win",
  "output_textview"
])

output_view = SpaceGtk3::Operators::OutputView.new( )


### Signal connection

GObject.signal_connect(output_widgets["output_clear_button"], "clicked", {"textview" => output_widgets["output_textview"] }, &output_view.output_clear_cb )
GObject.signal_connect(output_widgets["output_scroll_bottom"], "clicked", {"scroll_win" => output_widgets["output_scroll_win"] }, &output_view.output_scroll_down_to_bottom_cb )
GObject.signal_connect(output_widgets["output_scroll_top"], "clicked", {"scroll_win" => output_widgets["output_scroll_win"] }, &output_view.output_scroll_up_to_top_cb )
GObject.signal_connect(output_widgets["output_add_text"], "clicked", {"textview" => output_widgets["output_textview"], "str" => ("\n/* StatSailr output */\n") }, &output_view.output_add_str_cb )


GObject.signal_connect(output_widgets["output_clear_button"], "clicked", {"textview" => output_widgets["output_textview"] }, &output_view.output_clear_cb )

custom_output_scroll_down_to_bottom_cb = lambda{|widget, data|
  active = data["checkbox_autoscroll"].get_property("active")
  if active
    output_view.output_scroll_down_to_bottom_cb.call(widget,data)
  else
    # nop
  end
}

GObject.signal_connect_after(output_widgets["output_textview"].get_buffer(), "changed", {"textview" => output_widgets["output_textview"],  "checkbox_autoscroll" => output_widgets["output_check_autoscroll"] , "scroll_win" => output_widgets["output_scroll_win"]}, &custom_output_scroll_down_to_bottom_cb )




## Plot View Space ##

$plot_view_builder = Gtk::Builder.new()
$plot_view_builder.add_from_file( __dir__ + "/glade/" + "3_plot_widget.glade")

### Obtain Widgets via Glade 
plot_widgets = SpaceGtk3::Utility::Glade::collect_widgets( $plot_view_builder, [
  "plot_save_as_button",
  "plot_copy_button",
  "plot_notebook",
  "plot_drawing"
])

plot_view = SpaceGtk3::Operators::PlotView.new( )


### Signal connection

GObject.signal_connect(plot_widgets["plot_copy_button"], "clicked", {"drawing_area" => plot_widgets["plot_drawing"]}, &plot_view.plot_copy_cb )


## StatSailr Setting

require("statsailr")
require("statsailr/sts_controller")

StatSailrController.init( working_dir: File.expand_path('~'), device_info: ["Gtk3", plot_widgets["plot_drawing"].to_ptr ], procs_gem: ["statsailr_procs_base", "statsailr_procs_test" ])


GObject.signal_connect( nb_widgets["code_run_all_button"], "clicked", {"notebook" => nb_widgets["code_notebook"]}){| widget, data|
  notebook_widget = data["notebook"]
  if SpaceGtk3::Utility::Notebook.notebook_page_exist?( notebook_widget )
    current_page = SpaceGtk3::Utility::Notebook.notebook_current_page(notebook_widget)
    whole_text = SpaceGtk3::Utility::Textview.textview_text(current_page.get_child())
    result = StatSailrController.run(whole_text)
    SpaceGtk3::Utility::Textview.textview_append( output_widgets["output_textview"] , result)
  else
    p "Nothing to run"
  end
}

GObject.signal_connect( nb_widgets["code_run_selected_button"], "clicked", {"notebook" => nb_widgets["code_notebook"]}){| widget, data|
  notebook_widget = data["notebook"]
  if SpaceGtk3::Utility::Notebook.notebook_page_exist?( notebook_widget )
    current_page = SpaceGtk3::Utility::Notebook.notebook_current_page(notebook_widget)
    selected_text = SpaceGtk3::Utility::Textview.textview_text_selected(current_page.get_child())
    result = StatSailrController.run(selected_text)
    SpaceGtk3::Utility::Textview.textview_append( output_widgets["output_textview"] , result)
  else
    p "Nothing to run"
  end
}


## Main Window ##

### program is really being closed : destroy signal
exit_program_cb = lambda{|_widget, data|
  StatSailrController.stop()
  Gtk.main_quit()
}

main_window = Gtk::Window.new(:toplevel)
main_window.set_default_size(MAIN_WINDOW_WIDTH , MAIN_WINDOW_HEIGHT )
GObject.signal_connect( main_window , "destroy", &exit_program_cb )


### user's trying to close : delete-event signal
custom_delete_event_cb = lambda{|_widget, event, data|

  result = nb.close_all_cb.call(_widget, data)
  if result.nil?
    # Successfully all pages closed. 
    false # Continue further signal handlings.
  elsif result == false
    # Canceled
    true # Stop further signal handlings.
  else
    p "This branch should never be executed."
    true
  end
}

GObject.signal_connect( main_window, "delete-event", {"notebook" => nb_widgets["code_notebook"], "ask_save_page_cb" => nb.ask_save_page_cb }, &custom_delete_event_cb )


## Add widgets to main window

top_v_box = Gtk::VBox.new( false, 0 )
top_v_box.set_property("expand", true)

top_h_panel = Gtk::Paned.new( Gtk::Orientation::HORIZONTAL)
right_v_panel = Gtk::Paned.new( Gtk::Orientation::VERTICAL)
left_v_panel = Gtk::Paned.new( Gtk::Orientation::VERTICAL)

code_main_widget = $nb_builder.get_object("code_main_widget")
output_main_widget = $output_view_builder.get_object("output_main_widget")
plot_main_widget = $plot_view_builder.get_object("plot_main_widget")

left_v_panel.pack1(code_main_widget, true, false) # 2nd resize option, 3rd shrink option
left_v_panel.pack2(output_main_widget, true, false) # 2nd resize option, 3rd shrink option
left_v_panel.set_position( MAIN_WINDOW_HEIGHT * 0.50 )

right_v_panel.pack1(plot_main_widget, true, false) # 2nd resize option, 3rd shrink option

top_h_panel.pack1(left_v_panel, true, false ) # 2nd resize option, 3rd shrink option
top_h_panel.pack2(right_v_panel, true, false) # 2nd resize option, 3rd shrink option
top_h_panel.set_position( MAIN_WINDOW_WIDTH * 0.50)

top_v_box.add(top_h_panel)

main_window.add(top_v_box)


## Gtk Main loop

main_window.show_all()

Gtk.main

end
end
