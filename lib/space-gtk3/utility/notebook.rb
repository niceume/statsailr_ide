# Widget Base Functions


#CodeNotebook.add_page(nb, Gtk::Label("new_page") ){
#      textview = Gtk::SourceView.new()
#      scroll_win = Gtk::ScrolledWindow.new(nil , nil)
#      scroll_win.add(textview)
#      scroll_win
#}

module SpaceGtk3
module Utility
  module Notebook
    def self.notebook_get_n_pages(nb)
      return nb.get_n_pages()  # number of pages
    end

    def self.notebook_add_page(nb, label, &create_child_widget )
      nb.append_page( create_child_widget , label)
      scroll_win.show_all()
      return textview
    end

    def self.notebook_current_page_idx(nb)
      return nb.get_current_page() # return idx
    end

    def self.notebook_current_page(nb)
      idx = notebook_current_page_idx(nb)
      return nb.get_nth_page(idx) # return child widget
    end

    def self.notebook_current_page_apply(nb, &fun)
      fun.call( notebook_current_page( nb ) )
    end

    def self.notebook_current_page_close_if(nb, &cb)
      notebook_nth_page_close_if(nb, notebook_current_page_idx( nb ), &cb)
    end

    def self.notebook_page_exist?(nb)
      if( notebook_get_n_pages(nb) == 0 )
        return false
      else
        return true
      end
    end

    def self.notebook_find_idx_that_is(nb, &cond_cb )
      n_pages = notebook_get_n_pages(nb)
      if n_pages > 0
        idx_found = nil
        Range.new(0, n_pages -1).each(){|idx|
          widget = nb.get_nth_page(idx)
          if cond_cb.call( widget )
            idx_found = idx
            break
          end
        }
        return idx_found
      else
        return nil
      end
    end

    def self.notebook_switch_current_page_that_is(nb , &cb)
      idx = notebook_find_idx_that_is(nb, &cb)
      nb.set_current_page(idx)
    end

    def self.notebook_nth_page_close_if(nb, idx, &cb)
      if ( 0 <= idx && idx < nb.get_n_pages())
        # Usually within callback, widgets in this page can be closable?
        result_cb = cb.call( nb.get_nth_page(idx) )
        if result_cb
          nb.remove_page( idx )
          return true
        else
          # not closed
          return false
        end
      else
        puts "Specified idx page does not exist: #{idx} in #{nb.page_num()}"
        return false
      end
    end

    def self.notebook_close_all_pages(nb, &cb)
      n_page = nb.get_n_pages()
      idx = n_page
      while(n_page >= 0)
        page_close(nb, idx, &cb)
        idx = idx - 1
      end
    end
  end
end
end
