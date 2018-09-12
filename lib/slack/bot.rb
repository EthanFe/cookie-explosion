class SlackBot
  @@token = "xoxa-2-431241021636-431454794578-431243756420-5e277d6052f2e25e25d7b59c9bbcf9d4"

  def self.startup
    self.add_all_users
  end

  def self.add_all_users
    users = self.get_user_list
    if users
      users.each do |member|
        self.add_user_if_new(member) unless self.user_is_a_bot(member)
      end
    end
  end

  def self.get_user_list
    request_url = "https://slack.com/api/users.list?token=#{@@token}&pretty=1"
    response = JSON.parse(RestClient.get(request_url))
    response["ok"] ? response["members"] : false
  end

  def self.user_is_a_bot(member)
    member["id"] == "USLACKBOT" || member["profile"]["bot_id"]
  end

  def self.add_user_if_new(member)
    Owner.find_or_create_by(slack_id: member["id"])
  end
end

# This class contains all of the webserver logic for processing incoming requests from Slack.
class SlackAPI < Sinatra::Base
  # This is the endpoint Slack will post Event data to.
  post '/events' do
    puts "received event!"
    if request.content_type == "application/x-www-form-urlencoded"
      puts "URL ENCODED DATA"
      request_data = Events.parse_url_encoded_data(request.body.read)
      user_id = request_data["user_id"]
      case request_data["command"]
      when "%2Fingredients"
        return Commands.list_ingredients
      end

      status 200
    elsif request.content_type == "application/json"
      # Extract the Event payload from the request and parse the JSON
      request_data = JSON.parse(request.body.read)
      puts "JSON DATA"
      puts request_data
      # Check the verification token provided with the request to make sure it matches the verification token in
      # your app's setting to confirm that the request came from Slack.
      unless SLACK_CONFIG[:slack_verification_token] == request_data['token']
        halt 403, "Invalid Slack verification token received: #{request_data['token']}"
      end

      case request_data['type']
        # When you enter your Events webhook URL into your app's Event Subscription settings, Slack verifies the
        # URL's authenticity by sending a challenge token to your endpoint, expecting your app to echo it back.
        # More info: https://api.slack.com/events/url_verification
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
            # Events.send_message(channel_id, text) unless event_data["bot_id"] == "BCQPJU5ML"
            when 'team_join'
              # Event handler for when a user joins a team
              Events.user_join(team_id, event_data)
          end
          # Return HTTP status code 200 so Slack knows we've received the Event
          status 200
      end
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
    binding.pry
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

  def self.send_ephemeral_message_to_user(user_id, text)
  end

  def self.parse_url_encoded_data(string)
    properties = string.split("&")
    # some slightly arcane code stolen from stackoverflow
    # turns an array of strings of the form "key=value" into a hash
    Hash[properties.map do |property|
      property.split("=") 
    end]
  end
end

class Commands
  def self.list_ingredients
    "Current ingredients: :cookie: :cookie:"
  end
end

SlackBot.startup