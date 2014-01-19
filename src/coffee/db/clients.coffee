Client = require "../model/client"

find = (id, done) ->
	Client.find { id: id }, (err, client) ->
		done err, client

findById = (clientId, done) ->
	Client.find { clientId: clientId }, (err, client) ->
		done err, client

module.exports =
	find: find
	findById: findById