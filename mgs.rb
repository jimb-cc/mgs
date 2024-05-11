# frozen_string_literal: true

require 'mongo'
require 'slop'
require 'json'
require 'awesome_print'

opts = Slop.parse do |o|
  o.string '-h', '--host', 'the connection string for the MongoDB cluster (default: localhost)',
           default: 'mongodb://localhost'
  o.string '-d', '--database', 'the database to use (default: hs2)', default: 'mgs'
  o.string '-c', '--collection', 'the collection to use (default: p1)', default: 'temp'
end

# Connect to the DB
# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN
puts "## Connecting to #{opts[:host]}, and db #{opts[:database]}\n\n"
DB = Mongo::Client.new(opts[:host], database: opts[:database])

# set the collection to use
coll = DB[opts[:collection]]

ap coll.find().first