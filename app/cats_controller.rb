require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'
require_relative '../lib/show_exceptions'
require_relative '../lib/static'
require_relative 'cat'
require_relative 'human'
require_relative 'house'
require 'byebug'

class CatsController < ControllerBase
  def index
    @cats = Cat.all
  end

  def new
    @humans = Human.all
  end

  def create
    cat = Cat.new(name: @params['cat']['name'], owner_id: @params['cat']['owner_id'])
    cat.save
    redirect_to '/cats'
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/cats$"), CatsController, :index
  get Regexp.new("^/cats/(?<cat_id>\\d+)$"), CatsController, :show
  get Regexp.new("^/cats/new$"), CatsController, :new
  post Regexp.new("^/cats$"), CatsController, :create
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app = Rack::Builder.new do
  use Static
  use ShowExceptions
  run app
end.to_app

Rack::Server.start(
 app: app,
 Port: 3000,
 Host: '1.2.3.6'
)
