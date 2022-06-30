require "optparse"
require "yaml"
require_relative "google_tag_manager.rb"

class GoogleTagManagerCLI
  Version = "1.0.0"

  ACTIONS = %w[fake]
  ENVIRONMENTS = %w[integration staging]
  INTERACTIONS = YAML.load_file("interactions.yml").keys

  class Options
    attr_accessor :action, :environment, :interaction, :iterations

    def initialize
      self.action = ""
      self.environment = ""
      self.interaction = ""
      self.iterations = 1
    end

    def define_options(parser)
      parser.banner = "Usage: cli.rb [options]"
      parser.separator ""
      parser.separator "Specific options:"

      get_action(parser)
      get_environment(parser)
      get_interaction(parser)
      get_iterations(parser)

      parser.separator ""
      parser.separator "Common options:"

      parser.on_tail("-h", "--help", "Show this message") do
        puts parser
        exit
      end

      parser.on_tail("-v", "--version", "Show version") do
        puts Version
        exit
      end
    end

    def get_action(parser)
      actions = ACTIONS.join(", ")
      parser.on("-a", "--action [ACTION]", ACTIONS, "The action to take (#{actions})") do |action|
        self.action = action
      end
    end

    def get_environment(parser)
      environments = ENVIRONMENTS.join(", ")
      parser.on("-e", "--environment [ENVIRONMENT]", ENVIRONMENTS, "The environment to take the action on (#{environments})") do |environment|
        self.environment = environment
      end
    end

    def get_interaction(parser)
      interactions = INTERACTIONS.join(", ")
      parser.on("-i", "--interaction [INTERACTION]", INTERACTIONS, "The interaction to action (#{interactions})") do |interaction|
        self.interaction = interaction
      end
    end

    def get_iterations(parser)
      parser.on("-n", "--number [N]", Integer, "The number of times each event will be executed") do |n|
        self.iterations = n
      end
    end
  end

  def parse(args)
    options = Options.new
    args = OptionParser.new do |parser|
      options.define_options(parser)
      parser.parse!(args)
    end
    options
  end
end

cli = GoogleTagManagerCLI.new
options = cli.parse(ARGV)

gtm = GoogleTagManager.new(options)
gtm.run
