
utils = require '../lib/utils'
Client = require "../model/client"

create = (req, res) ->
	client = new Client(req.body)
	client.save (err) ->
		if (err)
			utils.responseData(500, "Could not save client", req.body, { req:req, res:res})
		else
			utils.responseData(201, "Created", client, { req:req, res:res})
		return

list = (req, res) ->
	Client.find {}, (err, clients) ->
		utils.responseData(200, undefined, clients, { req:req, res:res })
		return

findById = (req, res) ->
	Client.findOne { id: req.params.id }, (err, client) ->
		if (client)
			utils.responseData(200, undefined, client, { req:req, res:res })
		else
			utils.responseData(404, "Not Found", undefined, { req:req, res:res })
		return

removeById = (req, res) ->
	Client.findOneAndRemove { id: req.params.id }, (err, client) ->
		if (client)
			utils.responseData(204, undefined, client, { req:req, res:res })
		else
			utils.responseData(404, "Not Found", undefined, { req:req, res:res })
		return

module.exports =
	create : create,
	list : list,
	findById : findById,
	create : create,
	removeById : removeById
