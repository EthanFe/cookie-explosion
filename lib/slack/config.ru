require './auth'
require './bot'

# Initialize the app and create the SlackAPI (bot) and Auth objects.
run Rack::Cascade.new [SlackAPI, Auth]
