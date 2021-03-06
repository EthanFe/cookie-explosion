class SlackBot
  #these are both pretty dumbo but w/e
  # Cake workspace token @@token = "xoxa-2-431241021636-431454794578-431243756420-5e277d6052f2e25e25d7b59c9bbcf9d4"
  @@token = "xoxa-2-2727337933-435220560689-437153128614-8809645628b15162e1cf0c25bc33cecc"
  @@starting_ingredients = {Ingredient.find_by(name: "Butter") => 1,
                            Ingredient.find_by(name: "Sugar") => 1,
                            Ingredient.find_by(name: "Egg") => 1,
                            Ingredient.find_by(name: "Flour") => 1,
                            Ingredient.find_by(name: "Chocolate") => 1,
                            Ingredient.find_by(name: "Peanutbutter") => 1
                          }
  @@sendable_ingredient_emoji = Ingredient.all.map { |ingredient| ingredient.emoji }
  @@sendable_cookie_emoji = CookieRecipe.all.map { |cookie| cookie.emoji }

  def self.startup
    self.add_all_users
  end

  def self.give_ingredients_to_all_users(ingredient, count)
    Owner.all.each do |member|
      count.times do 
        member.receive_giveable_ingredient(ingredient)
      end
    end
  end

  def self.add_all_users
    users = self.get_user_list
    if users
      users.each do |user_id|
        self.add_user_if_new(user_id) unless self.user_is_a_bot(user_id)
      end
    end
  end

  def self.get_user_list
    channel_id = "CC7VBU8UW"
    # request_url = "https://slack.com/api/users.list?token=#{@@token}&pretty=1"
    request_url = "https://slack.com/api/channels.info?token=#{@@token}&channel=#{channel_id}&pretty=1"
    response = JSON.parse(RestClient.get(request_url))
    response["ok"] ? response["channel"]["members"] : false
  end

  def self.user_is_a_bot(user_id)
    false # bots are real people too
    # member == "USLACKBOT" || member["profile"]["bot_id"]
  end

  def self.add_user_if_new(user_id)
    Owner.find_or_create_by(slack_id: user_id)
  end

  def self.get_name_of_user(user)
    request_url = "https://slack.com/api/users.info?token=#{@@token}&user=#{user.slack_id}&pretty=1"
    response = JSON.parse(RestClient.get(request_url))
    response["user"]["real_name"]
  end

  def self.sendable_ingredient_emoji
    @@sendable_ingredient_emoji
  end

  def self.sendable_cookie_emoji
    @@sendable_cookie_emoji
  end

  def self.token
    @@token
  end

  def self.send_sent_item_messages(sender, recipient, object)
    Events.send_message(sender.slack_id, "You gave a :#{object}: to #{SlackBot.get_name_of_user(recipient)}!")
    Events.send_message(recipient.slack_id, "#{SlackBot.get_name_of_user(sender)}: gave you a :#{object}:!")
  end

  def self.send_ingredient(sender, recipient, item)
    self.send_sent_item_messages(sender, recipient, item)
    sender.give_ingredient_to(recipient, Ingredient.find_by(emoji: item))
  end

  def self.send_cookie(sender, recipient, item)
    self.send_sent_item_messages(sender, recipient, item)
    sender.give_cookie_to(recipient, CookieRecipe.find_by(emoji: item))
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
      content_type :json
      response = Events.slash_command_received(request_data)
      if response
        return response
      else
        status 200
      end
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
            Events.message_sent(event_data)
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
  end

  def self.send_message(channel_id, text)
    request_url = "https://slack.com/api/chat.postMessage?token=#{SlackBot.token}&channel=#{channel_id}&text=#{text}&pretty=1"
    response = RestClient.get(request_url)
    puts "***************"
    puts response
  end

  def self.parse_url_encoded_data(string)
    properties = string.split("&")
    # some slightly arcane code stolen from stackoverflow
    # turns an array of strings of the form "key=value" into a hash
    Hash[properties.map do |property|
      property.split("=") 
    end]
  end

  def self.message_sent(event_data)
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
          if targeted_user != sending_user
            SlackBot.sendable_ingredient_emoji.each do |sendable_ingredient|
              if text.include?(":#{sendable_ingredient}:")
                SlackBot.send_ingredient(sending_user, targeted_user, sendable_ingredient)
              end
            end
            SlackBot.sendable_cookie_emoji.each do |sendable_cookie|
              if text.include?(":#{sendable_cookie}:")
                SlackBot.send_cookie(sending_user, targeted_user, sendable_cookie)
              end
            end
          else
            Events.send_message(sending_user.slack_id, "You can't send ingredients to yourself!")
          end
        end
      end
    end
  end

  def self.slash_command_received(request_data)
    channel_id = request_data["channel_id"]
    user_id = request_data["user_id"]
    text = request_data["text"]
    case request_data["command"]
    when "%2Fcookie-inventory"
      return Commands.cookie_inventory(user_id)
    when "%2Fcookies-bakeable-list"
      return Commands.list_bakeable_cookies(user_id)
    when "%2Fcookies-bake"
      return Commands.bake_cookies(user_id, text)
    when "%2F%21distribute-ingredients"
      # if user_id == "UCRK08DGA" || user_id == "UCNMEMR08" # test channel ids
      if user_id == "UC95P2WDU" || user_id == "UCEJGLQSK" # flatiron channel ids
        return Commands.distribute_ingredients(channel_id, text)
      end
    end
  end
end

class Commands
  def self.cookie_inventory(user_id)
    #this function is so giant and ugly and inconsistent aaaaah
    owner = Owner.find_by(slack_id: user_id)
    ingredients = owner.list_all_ingredients
    giveable_cookies = owner.list_all_giveable_cookies
    received_cookies = owner.list_all_received_cookies

    response =
    {
      :text => "Your Ingredients:\n\n",
      :attachments => []
    }

    ingredients.each do |ingredient_info|
      ingredient = Ingredient.find(ingredient_info[:id])
      response[:text] << "You have #{ingredient_info[:giveable]} giveable #{ingredient.name} :#{ingredient.emoji}:, and #{ingredient_info[:received]} received from others!\n"
    end

    response[:text] << "\nCookies you've baked (can be sent to others):\n"
    giveable_cookies.each do |cookie_id, count|
      cookie = OwnedCookie.find(cookie_id)
      response[:text] << (":#{cookie.cookie_recipe.emoji}:" * count) + "\n"
    end
    response[:text] << "\nCookies others have sent to you:\n"
    received_cookies.each do |cookie_id, count|
      cookie = OwnedCookie.find(cookie_id)
      response[:text] << (":#{cookie.cookie_recipe.emoji}:" * count) + "\n"
    end

    response.to_json
  end

  def self.list_bakeable_cookies(user_id)
    response =
    {
      :text => "",
      :attachments => []
    }

    user = Owner.find_by(slack_id: user_id)
    recipes = user.list_cookie_recipes_you_can_bake
    if recipes.length > 0
      response[:text] << "Cookies you can make:"
      recipes.each do |recipe|
        response[:attachments] << {"text" => ":#{recipe.emoji}:"}
      end
    else
      closest_cookie = user.list_closest_cookable_cookie
      response[:text] << "You don't have enough ingredients to make a cookie yet. The cookie you're closest to is a :#{closest_cookie.emoji}:, which needs:\n"

      user.remaining_needed_ingredients_for(closest_cookie).each do |ingredient_id, count|
        response[:attachments] << {"text" => ":#{Ingredient.find(ingredient_id).emoji}:" * count}
      end
    end

    response.to_json
  end

  def self.bake_cookies(user_id, cookie_emoji)
    if cookie_emoji
      cookie_emoji = cookie_emoji.gsub("%3A", "")
      recipe = CookieRecipe.find_by(emoji: cookie_emoji)
      if recipe
        user = Owner.find_by(slack_id: user_id)
        if user.bake_cookies(recipe)
          "Baked a #{recipe.name} Cookie! :#{recipe.emoji}: :tada:"
        else
          response = "You don't have enough ingredients to make a #{recipe.name} Cookie. You still need:\n"
          needed_ingredients = user.remaining_needed_ingredients_for(recipe)
          needed_ingredients.each do |ingredient_id, count|
            response << ":#{Ingredient.find(ingredient_id).emoji}:" * count + "\n"
          end
          response
        end
      else
        "\":#{cookie_emoji}:\" is not a recognized cookie emoji. Use `/cookies-bakeable-list` to see available types."
      end
    else
      "Enter a cookie type after `/cookies-bake` to make cookies. Use `/cookies-bakeable-list` to see available types."
    end
  end

  def self.distribute_ingredients(channel_id, text)
    ingredient_type, count = text.split("+")
    ingredient = Ingredient.find do |ingredient|
      ingredient.name.downcase == ingredient_type.downcase
    end
    SlackBot.give_ingredients_to_all_users(ingredient, count.to_i)
    Events.send_message(channel_id, "Everyone has received #{count} more :#{ingredient.emoji}: to send to others!")
    "(ADMIN) Sent all users #{count} #{ingredient.name}"
  end
end

SlackBot.startup