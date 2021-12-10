# Widget Base Functions

module SpaceGtk3
module Utility
  module Textview
    def self.textview_clear( view )
      buffer = view.get_buffer
      iterStart = buffer.get_start_iter()
      iterEnd = buffer.get_end_iter()
      buffer.delete(iterStart, iterEnd)
    end

    def self.textview_append( view , str )
      buffer = view.get_buffer
      iterEnd = buffer.get_end_iter()
      buffer.insert( iterEnd, str, -1)
    end

    def self.textview_text(view)
      buffer = view.get_buffer
      iterStart = buffer.get_start_iter()
      iterEnd = buffer.get_end_iter()
      whole_text = buffer.get_text(iterStart, iterEnd, false)
      return whole_text
    end

    def self.textview_text_selected(view)
      buffer = view.get_buffer
      markStart = buffer.get_selection_bound()
      markEnd = buffer.get_insert()
      iterStart = buffer.iter_at_mark(markStart)
      iterEnd = buffer.iter_at_mark(markEnd)
      selected_text = buffer.get_text(iterStart, iterEnd, false)
      return selected_text
    end

  end
end
end
