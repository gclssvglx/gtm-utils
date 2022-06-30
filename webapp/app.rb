require "sinatra"
require "yaml"
require "ostruct"
require_relative "../google_tag_manager"

class App < Sinatra::Base
  attr_reader :interactions

  get "/" do
    @actions = %w[fake]
    @environments = %w[integration]
    @interactions = interactions
    @iterations = 1
    last_run_file = Dir.glob("log/*").max_by { |f| File.mtime(f) }
    puts last_run_file
    @last_run = File.readlines(last_run_file)

    erb :index
  end

  post "/run" do
    options = OpenStruct.new(params)
    gtm = GoogleTagManager.new(options)
    gtm.run
    redirect "/"
  end

  def interactions
    interactions = interactions || YAML.load_file("interactions.yml").keys
  end
end
