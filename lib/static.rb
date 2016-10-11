require 'byebug'
require 'rack/mime'

class Static
  attr_reader :app

  def initialize(app)
    puts "Initializing Static"
    @app = app
  end

  def get_mime_type(ext)
    Rack::Mime::MIME_TYPES[ext]
  end

  def call(env)
    path_parts = env['PATH_INFO'].split('/')

    file = path_parts.last.match(/^.{1,}\..{2,}$/) ? path_parts.pop : nil
    path = path_parts.drop(1).join('/')

    ext = file ? file.split('.').last : nil

    possible_file = "#{path}/#{file}"

    if File.directory?(path)
      res = Rack::Response.new

      if File.file?(possible_file)
        mime = get_mime_type(".#{ext}")
        res['Content-Type'] = mime
        res.write(File.read(possible_file))
      else
        res.status = 404
        res.write("File not found")
        res.finish
      end

      res.finish
    else
      @app.call(env)
    end
  end
end
