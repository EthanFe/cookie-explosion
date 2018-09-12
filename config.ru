require_relative './config/environment'

# Initialize the app and create the SlackAPI (bot) and Auth objects.
run Rack::Cascade.new [SlackAPI, Auth]
