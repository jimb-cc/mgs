require 'sinatra'
require "sinatra/base"
require 'mongo'
require 'awesome_print'
require 'json'


# set up connection to the database
#DB = Mongo::Client.new(["#{ARGV[2]}:27017"], :database => "admin", :user => ARGV[0], :password => ARGV[1])
# mongodb+srv://<mapped username>:<password>@iot.px8kv.mongodb.net/mgs



DB = Mongo::Client.new(ARGV[0])
#iotDB = DB.use(:iot)


coll = DB[ARGV[1]]
# set the logger level for the mongo driver
# Mongo::Logger.logger.level = ::Logger::WARN


#set :bind, "0.0.0.0"

get '/' do
  redirect 'http://jimb.cc/'
end

get '/test' do
  ap coll.find().first.to_s()
end

post '/' do
  "Go Away."
end


post "/v1/garden/" do
  # Chris, What does this do? :	
  request.body.rewind  # in case someone already read it
  puts request

  metaData = Hash.new

  # capture the JSON body of the post request and store it an a Hash.
  data = JSON.parse request.body.read
  
  # log some metadata from the request
  metaData.merge! :route => request.env["sinatra.route"]
  metaData.merge! :host => request.env["HTTP_HOST"]
  metaData.merge! :ua => request.env["HTTP_USER_AGENT"]
  
  # append the timestamp to the document
  data.merge! :ts => Time.now()
  # append the metadata to the document
  data.merge! :meta => metaData

  puts JSON.pretty_generate(data)

  # return status code and body
  status 202 
  body "Received, not yet actioned"

  # insert into collection
  result = iotDB[coll].insert_one(data)
  ap result
  puts result.n #=> returns 1, because 1 document was inserted.
end


get '/latest/:num/' do
  #db.garden.find().sort({ts:-1}).limit(10)
    documents = iotDB[coll].find().sort({:ts => -1}).limit(params['num'].to_i)
    documents.each do |document|

          # puts documents.to_json
          # puts JSON.pretty_generate(document)
          ap document

    end
end

get '/vccgraph/:sensor/' do

  documents = iotDB[coll].aggregate([{ :$match => { :thingID => params['sensor'] }},{ :$project => { :_id => 0, :x => "$ts", :y => "$vcc" }},{ :$sort => {:x => 1}}], :allowDiskUse => true)
  #documents = iotDB[coll].aggregate([{ :$project => { :_id => 0, :x => "$ts", :y => "$vcc" }}], :allowDiskUse => true)
  documents2 = documents.map do |document|
      { x: document['x'].to_i, y: ((document['y'].to_f)/1024).round(3)}
      #{ x: document['x'].to_i, y: document['y'].to_i}
  end

  ap documents2.to_json
end

get '/sensorgraph/:sensor/' do

  documents = iotDB[coll].aggregate([{ :$match => { :thingID => params['sensor'] }},{ :$project => { :_id => 0, :x => "$ts", :y => "$sensor" }},{ :$sort => {:x => 1}}], :allowDiskUse => true)
  documents2 = documents.map do |document|
      { x: document['x'].to_i, y: (document['y'].to_f)}
  end

  ap documents2.to_json
end


# Return the most recent Timestamp in the database for this thingID.  
# Returned as a string of the Unix time since Epoc
get '/lastupdate/:sensor/' do

 result = iotDB[coll].aggregate([{ :$match => {:thingID => params['sensor'] }},{ :$sort => {:ts => 1}},{:$limit => 1},{ :$project => { :_id => 0, :lastUpdate => "$ts"}}], :allowDiskUse => true)
 
 thetime = Time.new

  result.each do |doc|
    thetime =  doc[:lastUpdate]
    ap thetime
  end
  thetime.to_i.to_s
end



