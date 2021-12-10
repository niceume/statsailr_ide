module SpaceGtk3
module Utility
module Dialog
  def self.dialog_confirm_yes_no_cancel( title, btn_label1, btn_label2, btn_label3 , &add_message_widgets )
    dialog = Gtk::Dialog.new()
    dialog.set_title( title )
    content = dialog.get_content_area()
    add_message_widgets.call( content )
    content.show_all()
    dialog.add_button(btn_label1, 1) # Yes(Save)
    dialog.add_button(btn_label2, 2) # No(Discard)
    dialog.add_button(btn_label3, 3) # Cancel
    dialog_close_cb = lambda(){|_widget, data| _widget.close() }
    dialog_response_cb = lambda(){|_widget, response_id, data| _widget.close() }
    GObject.signal_connect( dialog, "close" , &dialog_close_cb )
    GObject.signal_connect( dialog, "response" , &dialog_response_cb )
    response = dialog.run()
    dialog.destroy()
    case response
    when 1
      return "Yes"
    when 2
      return "No"
    when 3
      return "Cancel"
    else
      return "Cancel"
    end
  end

  def self.file_chooser_get_save_filepath( filename, bool_saved_file )
    file_chooser = Gtk::FileChooserDialog.new("Save as", nil , Gtk::FileChooserAction::SAVE ,
      [["Cancel",Gtk::ResponseType::CANCEL ] , ["Save",Gtk::ResponseType::ACCEPT ]] )
    file_chooser.set_do_overwrite_confirmation( true )
    if ( bool_saved_file )
      file_chooser.set_current_name( filename ) # User cannot change filename
    else
      file_chooser.set_filename( filename) # User can change filename
    end
    response = file_chooser.run();

    if(response == Gtk::ResponseType::ACCEPT)
      save_path = file_chooser.get_filename()
      file_chooser.destroy()
      return save_path
    else
      file_chooser.destroy()
      return nil
    end
  end


  def self.file_chooser_get_open_filepath()
    file_chooser = Gtk::FileChooserDialog.new("Open", nil , Gtk::FileChooserAction::OPEN ,
      [["Cancel",Gtk::ResponseType::CANCEL ] , ["Open",Gtk::ResponseType::ACCEPT ]] )
    response = file_chooser.run();

    if(response == Gtk::ResponseType::ACCEPT)
      open_path = file_chooser.get_filename()
      file_chooser.destroy()
      return open_path
    else
      file_chooser.destroy()
      return nil
    end
  end

end
end
end
