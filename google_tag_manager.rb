require "webdrivers"
require "yaml"

class GoogleTagManager
  attr_reader :options, :interactions, :interaction_types, :driver

  def initialize(options)
    @options = options
    @interactions = YAML.load_file("interactions.yml")
    @capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      "goog:chromeOptions": { args: %w(headless disable-gpu) }
    )
    @driver = Selenium::WebDriver.for :chrome, capabilities: @capabilities
    @interaction_types = @interactions.keys
  end

  def run
    send @options.action
  end

  def fake
    @options.iterations.times do
      faker @interactions[@options.interaction]
    end
  end

  def test
    tester @interactions[@options.interaction], @options.interaction
  end

  private

  def faker(interactions)
    klass = interactions["class"]

    interactions["urls"].each do |url|
      @driver.get url
      clickables = @driver.find_elements(class: klass)
      clickables.each do |clickable|
        clickable.click
        last_event = @driver.execute_script("return dataLayer").last
        puts last_event.inspect
        puts "\n"
      end
    end
  end

  def tester(interactions, interaction_type)
    klass = interactions["class"]

    interactions["urls"].each do |url|
      @driver.get url
      clickables = @driver.find_elements(class: klass)
      clickables.each do |clickable|
        event_name = clickable.attribute("data-gtm-event-name")
        data_attributes = JSON.parse(clickable.attribute("data-gtm-attributes"))

        if interaction_type == "tabs"
          clickable.click
          events = @driver.execute_script("return dataLayer")
          expected_event = create_event(event_name, events.length, data_attributes, data_attributes["state"])
          puts events.last == expected_event ? "😀" : "🤮 : #{diff_events(events.last, expected_event)}"
        elsif interaction_type == "accordions"
          %w[opened closed].each do |state|
            clickable.click
            events = @driver.execute_script("return dataLayer")
            expected_event = create_event(event_name, events.length, data_attributes, state)
            puts events.last == expected_event ? "😀" : "🤮 : #{diff_events(events.last, expected_event)}"
          end
        end
      end
    end
  end

  def create_event(event_name, id, data_attributes, state)
    {
      "event" => "analytics",
      "event_name" => event_name,
      "gtm.uniqueEventId" => id,
      "link_url" => URI.parse(@driver.current_url).path,
      "ui" => {
        "index" => data_attributes["index"],
        "index-total" => data_attributes["index-total"],
        "section" => data_attributes["section"],
        "state" => state,
        "text" => data_attributes["text"],
        "type" => data_attributes["type"]
      }
    }
  end

  def diff_events(event_a, event_b)
    Hash[*(
      (event_b.size > event_a.size) ? event_b.to_a - event_a.to_a : event_a.to_a - event_b.to_a
    ).flatten]
  end
end
