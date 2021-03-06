require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'
require_relative './flash'
require_relative './sql_object'

class ControllerBase
  attr_reader :req, :res, :params
  @@protect_from_forgery = false

  def method_missing(name, *args, &prc)
    if [:new, :index, :update, :destroy, :show, :edit, :create].include?(name)
      
    else
      super
    end
  end

  # Setup the controller
  def initialize(req, res, params = {})
    @res = res
    @req = req
    @params = params
    # Dir["app/*.rb"].each {|file| require file }
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise_if_response_set
    @res.status = 302
    @res.set_header('Location', url)
    response_built
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise_if_response_set
    @res['Content-Type'] = content_type
    @res.write(content)
    response_built
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    directory = self.class.name.underscore[0..-12]
    template = "views/#{directory}/#{template_name}.html.erb"
    content = ERB.new(File.read(template)).result(binding)
    self.render_content(content, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    check_authenticity_token if @@protect_from_forgery && @req.request_method != 'GET'
    self.send(name)
    render(name) unless already_built_response?
  end

  def raise_if_response_set
    raise "Response already built" if @already_built_response
  end

  def response_built
    @already_built_response = true
    session.store_session(@res)
    flash.store_flash(@res)
  end

  def form_authenticity_token
    @authenticity_token ||= SecureRandom::urlsafe_base64
    @res.set_cookie('authenticity_token', {value: @authenticity_token, path: '/'})
    @authenticity_token
  end

  def self.protect_from_forgery
    @@protect_from_forgery = true
  end

  def protect_from_forgery?
    @@protect_from_forgery
  end

  def check_authenticity_token
    authenticity_token = @req.cookies['authenticity_token']
    raise "Invalid authenticity token" unless authenticity_token && authenticity_token == @params['authenticity_token']
  end
end
