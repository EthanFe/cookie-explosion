require 'sinatra/base'
require 'slack-ruby-client'
require 'rest-client'
require "json"
require "pry"

class SlackBot
  @@token = "xoxa-2-431241021636-431454794578-431243756420-5e277d6052f2e25e25d7b59c9bbcf9d4"
  @@users = []
  def self.startup
    self.add_all_users
  end

  def self.add_all_users
    request_url = "https://slack.com/api/users.list?token=#{@@token}&pretty=1"
    response = JSON.parse(RestClient.get(request_url))
    if response["ok"]
      response["members"].each do |member|
        existing_member = @@users.find {|user| user["id"] == member["id"]}
        if member["id"] != "USLACKBOT" && !member["profile"]["bot_id"] && !existing_member
          self.add_user(member)
        end
      end
    end
    binding.pry
  end

  def self.add_user(member)
    @@users << member
  end
end

# This class contains all of the webserver logic for processing incoming requests from Slack.
class SlackAPI < Sinatra::Base
  # This is the endpoint Slack will post Event data to.
  post '/events' do
    puts "received event!"
    # Extract the Event payload from the request and parse the JSON
    request_data = JSON.parse(request.body.read)
    puts request_data
    # Check the verification token provided with the request to make sure it matches the verification token in
    # your app's setting to confirm that the request came from Slack.
    unless SLACK_CONFIG[:slack_verification_token] == request_data['token']
      halt 403, "Invalid Slack verification token received: #{request_data['token']}"
    end

    case request_data['type']
  #     # When you enter your Events webhook URL into your app's Event Subscription settings, Slack verifies the
  #     # URL's authenticity by sending a challenge token to your endpoint, expecting your app to echo it back.
  #     # More info: https://api.slack.com/events/url_verification
      when 'url_verification'
        request_data['challenge']

      when 'event_callback'
        # Get the Team ID and Event data from the request object
        team_id = request_data['team_id']
        event_data = request_data['event']

        # Events have a "type" attribute included in their payload, allowing you to handle different
        # Event payloads as needed.
        case event_data['type']
        when 'message'
          user_id = event_data["user"]
          text = event_data["text"]
          channel_id = event_data["channel"]
          # Events.send_echo_to_user(user_id, text)
          Events.send_message(channel_id, text) unless event_data["bot_id"] == "BCQPJU5ML"
  #         when 'team_join'
  #           # Event handler for when a user joins a team
  #           Events.user_join(team_id, event_data)
  #         when 'reaction_added'
  #           # Event handler for when a user reacts to a message or item
  #           Events.reaction_added(team_id, event_data)
  #         when 'pin_added'
  #           # Event handler for when a user pins a message
  #           Events.pin_added(team_id, event_data)
  #         when 'message'
  #           # Event handler for messages, including Share Message actions
  #           Events.message(team_id, event_data)
  #         else
  #           # In the event we receive an event we didn't expect, we'll log it and move on.
  #           puts "Unexpected event:\n"
  #           puts JSON.pretty_generate(request_data)
        end
        # Return HTTP status code 200 so Slack knows we've received the Event
        status 200
    end
  end
end

# This class contains all of the Event handling logic.
class Events
  # You may notice that user and channel IDs may be found in
  # different places depending on the type of event we're receiving.

  # A new user joins the team
  def self.user_join(team_id, event_data)
    user_id = event_data['user']['id']
    # Store a copy of the tutorial_content object specific to this user, so we can edit it
    $teams[team_id][user_id] = {
      tutorial_content: SlackTutorial.new
    }
    # Send the user our welcome message, with the tutorial JSON attached
    self.send_response(team_id, user_id)
  end

  # A user reacts to a message
  def self.reaction_added(team_id, event_data)
    user_id = event_data['user']
    if $teams[team_id][user_id]
      channel = event_data['item']['channel']
      ts = event_data['item']['ts']
      SlackTutorial.update_item(team_id, user_id, SlackTutorial.items[:reaction])
      self.send_response(team_id, user_id, channel, ts)
    end
  end

  # A user pins a message
  def self.pin_added(team_id, event_data)
    user_id = event_data['user']
    if $teams[team_id][user_id]
      channel = event_data['item']['channel']
      ts = event_data['item']['message']['ts']
      SlackTutorial.update_item(team_id, user_id, SlackTutorial.items[:pin])
      self.send_response(team_id, user_id, channel, ts)
    end
  end

  def self.message(team_id, event_data)
    user_id = event_data['user']
    # Don't process messages sent from our bot user
    unless user_id == $teams[team_id][:bot_user_id]

      # This is where our `message` event handlers go:

      # SHARED MESSAGE EVENT
      # To check for shared messages, we must check for the `attachments` attribute
      # and see if it contains an `is_shared` attribute.
      if event_data['attachments'] && event_data['attachments'].first['is_share']
        # We found a shared message
        user_id = event_data['user']
        ts = event_data['attachments'].first['ts']
        channel = event_data['channel']
        # Update the `share` section of the user's tutorial
        SlackTutorial.update_item( team_id, user_id, SlackTutorial.items[:share])
        # Update the user's tutorial message
        self.send_response(team_id, user_id, channel, ts)
      end
    end
  end

  # Send a response to an Event via the Web API.
  def self.send_response(team_id, user_id, channel = user_id, ts = nil)
    # `ts` is optional, depending on whether we're sending the initial
    # welcome message or updating the existing welcome message tutorial items.
    # We open a new DM with `chat.postMessage` and update an existing DM with
    # `chat.update`.
    if ts
      $teams[team_id]['client'].chat_update(
        as_user: 'true',
        channel: channel,
        ts: ts,
        text: SlackTutorial.welcome_text,
        attachments: $teams[team_id][user_id][:tutorial_content]
      )
    else
      $teams[team_id]['client'].chat_postMessage(
        as_user: 'true',
        channel: channel,
        text: SlackTutorial.welcome_text,
        attachments: $teams[team_id][user_id][:tutorial_content]
      )
    end
  end

  # def self.open_im(user_id)
  #   token = "xoxa-2-431241021636-431454794578-431243756420-5e277d6052f2e25e25d7b59c9bbcf9d4"
  #   request_url = "https://slack.com/api/im.open?token=#{token}&user=#{user_id}&pretty=1"
  #   response = JSON.parse((RestClient.get(request_url)))
  #   binding.pry
  #   response["channel"]["id"]
  # end

  def self.send_message(channel_id, text)
    token = "xoxa-2-431241021636-431454794578-431243756420-5e277d6052f2e25e25d7b59c9bbcf9d4"
    request_url = "https://slack.com/api/chat.postMessage?token=#{token}&channel=#{channel_id}&text=#{text}&pretty=1"
    RestClient.get(request_url)
  end

  def self.send_echo_to_user(user_id, text)
    send_message_to_user(user_id, "You said: #{text}")
  end

  def self.send_message_to_user(user_id, text)
    send_message(user_id, text)
  end
end

SlackBot.startup