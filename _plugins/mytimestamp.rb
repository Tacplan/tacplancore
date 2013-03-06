module Jekyll
  module mytimestamp
     def mydatetime(date)
            date.strftime("%D %B %Y %H%M")
     end
  end
end

Liquid::Template.register_filter(Jekyll::mytimestamp)