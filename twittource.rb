require "rubygems"
require "twitter"
require "yajl"
require "date"
require 'uri'
require 'net/http'

# CustomLog doc: http://code.google.com/p/gource/wiki/CustomLogFormat

# Nodes to be displayed on graph
$gource_nodes = []

# Current twitter hashtags to search
$twitter_terms = [
  {:hashtag => "wikileaks", :path => "/wikileaks", :color => "5DBCDE", :last_id => "1"},
  {:hashtag => "toulouse", :path => "/toulouse", :color => "F026C2", :last_id => "1"},
  {:hashtag => "tetalab", :path => "/tetalab", :color => "99F026", :last_id => "1"},
  {:hashtag => "nw", :path => "/empreintes", :color => "F0ED26", :last_id => "1"},
  {:hashtag => "anon", :path => "/anon", :color => "8C39A3", :last_id => "1"},
]

# Empty hashtags, don't search them again
$forbidden_terms =["tetalab","retrogaminglunion2011","LaDynamo","indiacables","ladynamo","featur","opsaveed","anonopscn","operaci","reallywild","moguda","13erue","1","wootwootwoot","centrebel","centrebellegarde","thoughttwitterbrokeupwithme","interculturalism","lebjv","paliotomatoto","cassiones","jevaismecalmer","4","emmajames","peterhinchliffe","gulfofaden","censorshit","911"]

# Invalid image on avatar
$invalid_avatars = ["TownCrier1990.png", "TOPALDERYA.png", "felipe_atene.png", "bant14feb.png"]

# Hashtag to be included in next search
$new_twitter_terms = []

# Current display tag, useful for info.html
$current_term = {}


# ===
# Search hashtag _term_ in Twitter
# ===
def twitter_search(term)
  $current_term = term
  
  # Generate new info.html
  write_info

  # Fetch results from twitter api
  results = Twitter.search("##{term[:hashtag]}", :result_type => "recent", :rpp => 10)

  if results.size < 10
    # Result not interesting, forbid this hashtag and search next hashtag
    $forbidden_terms << term[:hashtag]
    return
  else
    results.each do |r|
        # Create a new path for current node
        path = "#{term[:path]}/#{r.id}" 
      
        # Add node with useful info to gource nodes that'll be display at the end of the method
        $gource_nodes << {
          :timestamp => r.created_at.to_i,
          :user => r.from_user,
          :path => path,
          :color => term[:color],
          :hashtag => term[:hashtag]
        }
        
        # Parse new hashtags in current result text
        r.text.scan(/#\w+/).each do |new_hashtag|
          new_hashtag.gsub!("#", "").downcase!
          if $twitter_terms.select{|term| term[:hashtag] == new_hashtag}.size == 0 && $new_twitter_terms.select{|term| term[:hashtag] == new_hashtag}.size == 0  
            $new_twitter_terms << {:hashtag => new_hashtag, :path => "#{path}/#{new_hashtag}", :color => random_color, :last_id => r.id}
          end
        end

        # Shorten path when too long
        term[:path] = path
        if term[:path].size > 100
          term[:path].gsub(/#{term[:hashtag]}\/\d+/, term[:hashtag])
        end
      
        # Useless at the moment, is interesting if searching for latest tweets 
        term[:last_id] = r.id #if r.id.to_i > term[:last_id].to_i
        
        # Retrieve user avatar, it could be useful to display this avatar in gource
        # retrieve_avatar(r.profile_image_url, r.from_user)
    end
  end
end

# ===
# Create avatar on local filesystem using username, so the avatar could be used in gource
# ===
def retrieve_avatar(image_url, user_id)
  
  # Create avatar filename with username and image extension
  user_avatar = "#{user_id}#{File.extname(image_url)}"

  unless File.exists?("avatars/#{user_avatar}") || $invalid_avatars.include?(user_avatar)
      u = URI.parse(image_url)
      Net::HTTP.start(u.host){ |http|
        resp = http.get(u.path)
        open("avatars/#{user_avatar}", "wb"){ |file|
          file.write(resp.body)
        }
      }

      # Remove avatar if the downloaded file is not an image
      unless `file avatars/#{user_avatar}`.match(/(GIF|JPEG|PNG)/)
        $invalid_avatars << user_avatar
        `rm avatars/#{user_avatar}`
      end
  end
end

# ===
# Update gource with new nodes using STDOUT
# ===
def display_new_nodes
  $gource_nodes.each do |node|
     puts "#{node[:timestamp]}|#{node[:hashtag]}|A|#{node[:path]}.tetalab|#{node[:color]}"  
  end
 
  $gource_nodes = []
  $twitter_terms += $new_twitter_terms
  $new_twitter_terms = []
end

# ===
# Create random hexadecimal color, useful when new node is discovered
# ===
def random_color
  color = ""
  6.times do
    color << ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B", "C", "D", "E", "F"][rand(16)]
  end
  return color
end

# ===
# Generate info.html to display current state of hashtag discoveries
# ===
def write_info
  File.open("info.html", "w") do |file|
    file.write "<h1>#{$current_term[:hashtag]}</h1><p>forbidden: [#{$forbidden_terms.join("\",\"")}]</p><ul>"
    $twitter_terms.each do |term|
       file.write "<li>#{term[:hashtag]}: #{term[:path]}</li>"
    end
    file.write "</ul>"
  end
end

# ===
# Run the program to search hashtag in twitter and then output the result in STDOUT, that'd be use by gource to update its display
# ===
while true
  $twitter_terms.reject{|term| $forbidden_terms.include? term[:hashtag] }.each do |term| 
    twitter_search(term)
    display_new_nodes 
  end
end
