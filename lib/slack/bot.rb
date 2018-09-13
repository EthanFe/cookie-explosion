class SlackBot
  #these are both pretty dumbo but w/e
  @@token = "xoxa-2-431241021636-431454794578-431243756420-5e277d6052f2e25e25d7b59c9bbcf9d4"
  @@starting_ingredients = {Ingredient.find_by(name: "Butter") => 1,
                            Ingredient.find_by(name: "Sugar") => 1,
                            Ingredient.find_by(name: "Egg") => 1,
                            Ingredient.find_by(name: "Flour") => 1,
                            Ingredient.find_by(name: "Chocolate") => 1,
                            Ingredient.find_by(name: "Peanut Butter") => 1
                          }
  @@sendable_ingredient_emoji = Ingredient.all.map do |ingredient|
    ingredient.emoji
  end

  def self.startup
    self.add_all_users
    self.give_starting_ingredients_to_all_users
  end

  def self.give_starting_ingredients_to_all_users
    Owner.all.each do |member|
      self.give_starting_ingredients(member)
    end
  end

  def self.give_starting_ingredients(member)
    @@starting_ingredients.each do |ingredient, count|
      # if owner.receive_giveable_ingredient had a count argument this could be simplified
      count.times do 
        member.receive_giveable_ingredient(ingredient)
      end
    end
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

  def self.get_name_of_user(user)
    request_url = "https://slack.com/api/users.info?token=#{@@token}&user=#{user.slack_id}&pretty=1"
    response = JSON.parse(RestClient.get(request_url))
    response["user"]["real_name"]
  end

  def self.sendable_ingredient_emoji
    @@sendable_ingredient_emoji
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
      text = request_data["text"]
      case request_data["command"]
      when "%2Fingredients"
        content_type :json
        return Commands.list_ingredients(user_id)
      when "%2Flist-bakeable-cookies"
        content_type :json
        return Commands.list_bakeable_cookies(user_id)
      when "%2Fbake_cookies"
        return Commands.bake_cookies(user_id, text)
      end

      status 200
    elsif request.content_type == "application/json"
      # Extract the Event payload from the request and parse the JSON
      request_data = JSON.parse(request.body.read)
      puts "JSON DATA"
      # puts request_data
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
            puts "message text: #{text}"
            if text
              if text[0..1] == "<@"
                targeted_slack_id = text[2..10]
                sending_user = Owner.find_by(slack_id: user_id)
                targeted_user = Owner.find_by(slack_id: targeted_slack_id)
                if targeted_user
                  SlackBot.sendable_ingredient_emoji.each do |sendable_ingredient|
                    if text.include?(":#{sendable_ingredient}:")
                      sending_user.give_ingredient_to(targeted_user, Ingredient.find_by(emoji: sendable_ingredient))
                      Events.send_message(channel_id, "#{SlackBot.get_name_of_user(sending_user)} gave a :#{sendable_ingredient}: to #{SlackBot.get_name_of_user(targeted_user)}!")
                    end
                  end
                end
              end
            end
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
  # A new user joins the team
  def self.user_join(team_id, event_data)
    user_id = event_data['user']['id']
    binding.pry
  end

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
  def self.list_ingredients(user_id)
    ingredients = Owner.find_by(slack_id: user_id).list_all_ingredients

    response =
    {
      :text => "Your Ingredients:\n",
      :attachments => []
    }

    ingredients.each do |ingredient_info|
      ingredient = Ingredient.find(ingredient_info[:id])
      response[:text] << "You have #{ingredient_info[:giveable]} giveable #{ingredient.name} :#{ingredient.emoji}:, and #{ingredient_info[:received]} received from others!\n"
    end

    response.to_json
  end

  def self.list_bakeable_cookies(user_id)
    response =
    {
      :text => "Cookies you can make:",
      :attachments => []
    }

    recipes = Owner.find_by(slack_id: user_id).list_cookie_recipes_you_can_bake
    recipes.each do |recipe|
      response[:attachments] << {"text" => "#{recipe.name} cookies!"}
    end

    response.to_json
  end

  def self.bake_cookies(user_id, cookie_type)
    if cookie_type
      cookie_type = cookie_type.gsub("+", " ")
      recipe = CookieRecipe.find do |cookie_recipe|
        cookie_type.downcase == cookie_recipe.name.downcase
      end
      if recipe
        user = Owner.find_by(slack_id: user_id)
        if user.bake_cookies(recipe)
          "Baked a #{recipe.name} Cookie! :#{recipe.emoji}: :tada:"
        else
          #change this to say/display what ingredients are still needed
          "You don't have enough ingredients to make a #{recipe.name} Cookie. Use `/list_bakeable_cookies` to see available types."
        end
      else
        "\"#{cookie_type}\" is not a recognized cookie type. Use `/list_bakeable_cookies` to see available types."
      end
    else
      "Enter a cookie type after `/bake_cookies` to make cookies. Use `/list_bakeable_cookies` to see available types."
    end
  end
end

SlackBot.startup