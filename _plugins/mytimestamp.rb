module Jekyll
  module MyTimeStamp
        def mydatetime(date)
            date.strftime("%d %B %Y %H%M")
        end
  end
end

Liquid::Template.register_filter(Jekyll::MyTimeStamp)