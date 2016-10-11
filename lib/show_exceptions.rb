require 'erb'

class ShowExceptions
  attr_reader :app

  def initialize(app)
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
    template = File.read('lib/templates/rescue.html.erb')
    template = ERB.new(template)
    ['500', {'Content-type' => 'text/html'}, [template.result(binding)]]
  end

end
