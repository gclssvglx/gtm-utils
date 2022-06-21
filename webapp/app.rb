require "sinatra"
require "yaml"

class App < Sinatra::Base
  attr_reader :interactions

  get "/" do
    @actions = %w[fake test]
    @environments = %w[integration staging]
    @interactions = interactions

    erb :index
  end

  post "/run" do
    system("ruby gtm-cli.rb -a #{params[:action]} -e #{params[:environment]} -i #{params[:interaction]} -n #{params[:iterations].to_i}")
    redirect "/"
  end

  def interactions
    interactions = interactions || YAML.load_file("interactions.yml").keys
  end
end
