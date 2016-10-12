require 'erb'

class ShowExceptions
  attr_reader :app

  def initialize(app)
    puts "Initializing exceptions"
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue Exception => e
      render_exception(e)
    end
  end

  private

  def render_exception(e)
    @e = e
    template = File.read( File.dirname(__FILE__) + '/templates/rescue.html.erb')
    template = ERB.new(template)
    ['500', {'Content-type' => 'text/html'}, [template.result(binding)]]
  end

end
