module SpaceGtk3
module Operators
class CodeNotebook
  attr :ptr_pages
  attr_accessor :custom_after_save_cb
  attr :add_page_cb, :close_page_cb, :close_all_cb, :save_page_as_cb, :save_page_cb, :callback_cb, :redo_page_cb, :undo_page_cb, :open_file_cb, :ask_save_page_cb

  @ptr_pages = {}  # { widget_ptr_id => {"dir_path" => val , "filename" => val }}

  def page_uid( widget )
    return widget.to_ptr.to_i
  end


  def initialize( )
    @ptr_pages = {}

    # Callbacks and Connect them with widgets

    @add_page_to_notebook = lambda{|nb, label, widget, reorderable|
      nb.append_page( widget , label )
      nb.set_tab_reorderable(widget, reorderable)
    }

    @create_scroll_textview = lambda{ 
      scroll_win = Gtk::ScrolledWindow.new()
      buffer = GtkSource::Buffer.new(nil)
      sourceview = GtkSource::View.new_with_buffer(buffer)
      sourceview.set_monospace(true)
      sourceview.set_top_margin(5)
      sourceview.set_right_margin(5)
      sourceview.set_bottom_margin(5)
      sourceview.set_left_margin(5)
      scroll_win.add( sourceview )
      scroll_win
    }

    @textbuffer_modified_changed_cb = lambda{| buffer,  user_data|
      nb = user_data["notebook"]
      child = user_data["child_widget"]
      filename = @ptr_pages[ page_uid( child ) ]["filename"]
      if buffer.get_modified
        labelname = "*" + filename
      else
        labelname = filename
      end
      nb.set_tab_label_text( child, labelname)
    }

    @add_new_page_cb = lambda{|data|
      label_name = new_filename(prefix: "Untitled")
      label = Gtk::Label.new( label_name )
      scroll_win = @create_scroll_textview.call( )
      @ptr_pages[ page_uid( scroll_win ) ] = { "dir_path" => nil , "filename" => label_name}
      @add_page_to_notebook.call(data["notebook"], label, scroll_win, true)

      GObject.signal_connect(scroll_win.get_child().get_buffer(), "modified-changed", {"child_widget" => scroll_win, "notebook" => data["notebook"]} , &@textbuffer_modified_changed_cb )

      scroll_win.show_all()
      scroll_win
    }

    @add_page_cb = lambda{|_widget, data|
      nb = data["notebook"]
      new_child_page = @add_new_page_cb.call(data)

      Utility::Notebook.notebook_switch_current_page_that_is(nb){|_child_page|
        if( page_uid( _child_page) == page_uid(new_child_page) )
          true
        else
          false
        end
      }
    }

    @ask_save_page_cb = lambda{|nb|
      page_uid = page_uid( Utility::Notebook::notebook_current_page(nb) )
      bool_saved = @ptr_pages[ page_uid ]["dir_path"].nil? ? false : true
      save_path = Utility::Dialog::file_chooser_get_save_filepath( @ptr_pages[ page_uid ]["filename"] , bool_saved )
      if ! save_path.nil?
        p "Save file : #{save_path}" if $DEBUG
        File.open( save_path , "w" ){|f| text = Utility::Notebook::notebook_current_page(nb).get_child().get_buffer().get_property("text")
          f.write text
        }
        @ptr_pages[ page_uid ]["dir_path"] = File.dirname(save_path)
        @ptr_pages[ page_uid ]["filename"] = File.basename(save_path)
        Utility::Notebook::notebook_current_page(nb).get_child().get_buffer().set_modified(false)  # reset modified status
        nb.set_tab_label_text( Utility::Notebook::notebook_current_page(nb), @ptr_pages[ page_uid ]["filename"])   # overwrite tab name
        if @custom_after_save_cb
          @custom_after_save_cb.call()
        end
        "saved"
      else
        p "nop" if $DEBUG
        "canceled"
      end
    }

    @close_page_cb = lambda{|_widget, data|
      nb = data["notebook"]
      if(Utility::Notebook::notebook_get_n_pages(nb) == 0)
        p "nothing to close" if $DEBUG
        return nil
      end
      page_uid = page_uid( Utility::Notebook::notebook_current_page(nb) )
      ask_save_page_cb_func = data["ask_save_page_cb"]

      page_closed = Utility::Notebook.notebook_current_page_close_if(nb){|_child|  
        scroll_win = _child
        source_view = scroll_win.get_child()
        source_buffer = source_view.get_buffer()
        if(source_buffer.get_modified)
          # Ask user
          confirm_save = Utility::Dialog.dialog_confirm_yes_no_cancel( "Save before closing", "Yes (Save)", "NO (Discard)", "Cancel" ){|content|
            content.add( Gtk::Label.new( "#{@ptr_pages[ page_uid ]['filename']}" ))
            content.add( Gtk::Label.new( "File has been changed." ))
            content.add( Gtk::Label.new( "Save before closing?" ))
          }

          case confirm_save
          when "Yes"
            p "Do not close now, and save file first" if $DEBUG
            result2 = ask_save_page_cb_func.call( nb )
            case result2
            when "saved"
              @ptr_pages.delete(page_uid)
              true
            when "no_need_to_save"
              @ptr_pages.delete(page_uid)
              true
            when "canceled"
              false
            end
          when "No" # Close without saving
            @ptr_pages.delete(page_uid)
            p "Close page" if $DEBUG
            true
          when "Cancel" # Nop
            p "Not closed. Cancel." if $DEBUG
            false
          end
        else
          # not modifield page & can be closed safely
          @ptr_pages.delete(page_uid)
          p "Close page" if $DEBUG
          true
        end
      }
    }

    @save_page_as_cb = lambda{|_widget, data|
      nb = data["notebook"]
      if(Utility::Notebook::notebook_get_n_pages(nb) == 0)
        p "nothing to save" if $DEBUG
        return
      end
      @ask_save_page_cb.call( nb )
    }

    @save_page_cb = lambda{|_widget, data|
      nb = data["notebook"]
      if(Utility::Notebook::notebook_get_n_pages(nb) == 0)
        p "nothing to save" if $DEBUG
        return
      end
      page_uid = page_uid( Utility::Notebook::notebook_current_page(nb) )
      if @ptr_pages[page_uid]["dir_path"].nil?
        @ask_save_page_cb.call( nb )
      else
        save_path = @ptr_pages[page_uid]["dir_path"] + "/" + @ptr_pages[page_uid]["filename"]
        File.open( save_path , "w" ){|f| text = Utility::Notebook::notebook_current_page(nb).get_child().get_buffer().get_property("text")
          f.write text
        }
        Utility::Notebook::notebook_current_page(nb).get_child().get_buffer().set_modified(false)  # reset modified status
        if @custom_after_save_cb
          @custom_after_save_cb.call()
        end
        p "Saved to #{save_path}" if $DEBUG
      end
    }

    @callback_cb = lambda{|_widget, data|
      data["callback"].call()
    }

    @redo_page_cb = lambda{|_widget, data|
      nb = data["notebook"]
      if(Utility::Notebook::notebook_get_n_pages(nb) == 0)
        p "nothing to redo" if $DEBUG
        return
      end
      scroll_win = Utility::Notebook::notebook_current_page(nb)
      source_view = scroll_win.get_child()
      source_buffer = source_view.get_buffer()
      if source_buffer.can_redo
        source_buffer.redo()
        p "Redo" if $DEBUG
      else
        p "Cannot redo" if $DEBUG
      end
    }

    @undo_page_cb = lambda{|_widget, data|
      nb = data["notebook"]
      if(Utility::Notebook::notebook_get_n_pages(nb) == 0)
        p "nothing to undo" if $DEBUG
        return
      end
      scroll_win = Utility::Notebook::notebook_current_page(nb)
      source_view = scroll_win.get_child()
      source_buffer = source_view.get_buffer()
      if source_buffer.can_undo
        source_buffer.undo()
        p "Undo" if $DEBUG
      else
        p "Cannot undo" if $DEBUG
      end
    }

    @open_file_cb = lambda{|_widget, data|
      nb = data["notebook"]
      open_path = Utility::Dialog::file_chooser_get_open_filepath( )
      if ! open_path.nil?
        p "Open file : #{open_path}" if $DEBUG

        if path_already_opened?( open_path )
          page_uid = get_page_id_by_path( open_path )

          # switch to the page
          Utility::Notebook.notebook_switch_current_page_that_is(nb){|_child_page|
            if( page_uid( _child_page) == page_uid )
              true
            else
              false
            end
          }
        else
          # Read text
          new_text = ""
          File.open( open_path , "r" ){|f|
            new_text = f.read
          }

          # Add new page with new label + text 
          new_label = File.basename( open_path )
          new_page = @add_new_page_cb.call(data)

          @ptr_pages[ page_uid(new_page) ] = {"dir_path" => File.dirname(open_path), "filename" => File.basename(open_path)}

          source_buffer = new_page.get_child().get_buffer()
          source_buffer.get_property("undo-manager").begin_not_undoable_action()
          iterStart = source_buffer.get_iter_at_offset(0)
          source_buffer.insert( iterStart, new_text, -1)  # insert text
          source_buffer.get_property("undo-manager").end_not_undoable_action()
          nb.set_tab_label_text( new_page, new_label )   # overwrite tab name

          source_buffer.set_modified(false)  # reset modified status

          # switch to the page
          Utility::Notebook.notebook_switch_current_page_that_is(nb){|_child_page|
            if( page_uid( _child_page) == page_uid( new_page) )
              true
            else
              false
            end
          }
        end
        "opened"
      else
        p "nop" if $DEBUG
        "canceled"
      end
    }

    @close_all_cb = lambda{|_widget, data|
      result = true
      loop do
        result = @close_page_cb.call( _widget, data )
        p result
        if result == false # Canceled
          p "closing pages canceled"
          break
        elsif result.nil?  # Nothing to close
          p "all pages closed"
          break
        end
      end
      result
    }
  end

  def show_ptr_pages(  )
    p @ptr_pages
  end

  private
  def test_filename_overlap( name )
    if( @ptr_pages.keys.include?(name) )
      return true
    else
      return false
    end
  end

  def new_filename( prefix: "Untitled" )
    num = (@ptr_pages.length + 1)
    filename = prefix
    loop do
      filename = prefix + "_" + num.to_s
      num = num + 1
      break if( test_filename_overlap(filename) == false || num > 1000 )
    end
    return filename
  end

  def path_already_opened?( open_path )
    open_path_dir_path = File.dirname(open_path)
    open_path_filename = File.basename(open_path)
    ptr_pages_dir_path = @ptr_pages.values.map(){|ptr_page| ptr_page["dir_path"]}
    ptr_pages_filename = @ptr_pages.values.map(){|ptr_page| ptr_page["filename"]}

    if( ptr_pages_dir_path.include?(open_path_dir_path) && ptr_pages_filename.include?(open_path_filename) )
      true
    else
      false
    end
  end

  def get_page_id_by_path( open_path )
    open_path_dir_path = File.dirname(open_path)
    open_path_filename = File.basename(open_path)
    page_id_found = nil
    @ptr_pages.each{|key, ptr_page|
      if (ptr_page["dir_path"] == open_path_dir_path) && (ptr_page["filename"] && open_path_filename)
        page_id_found = key
        break
      end
    }
    return page_id_found
  end
end
end
end


