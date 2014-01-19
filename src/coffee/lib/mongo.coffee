mongoose = require 'mongoose'
pureautoinc  = require 'mongoose-pureautoinc'
logger = require 'winston'

config = require '../conf/config'

options =
  db: { native_parser: false },
  server: { poolSize: 5 },
  user: config.mongo.username,
  pass: config.mongo.password

url = "mongodb://#{config.mongo.hostname}:#{config.mongo.port}/#{config.mongo.dbname}"
logger.info("config: " + JSON.stringify(config))
logger.info("config: " + JSON.stringify(config.mongo))
logger.info("Mongo Url: #{url}")
mongoose.connect url, options


client = mongoose.connection
client.on 'error', console.error.bind(console, 'connection error:')
client.once 'open', () ->
	logger.info "Connected to MongoBD on url: #{url}"

pureautoinc.init client

module.exports =
	client: client
	Schema: mongoose.Schema
