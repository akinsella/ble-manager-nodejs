pureautoinc  = require 'mongoose-pureautoinc'

mongo = require '../lib/mongo'

Client = new mongo.Schema(
	id: Number,
	name: { type: String, "default": '', trim: true },
	clientId: { type: String, "default": '', trim: true },
	clientSecret: { type: String, "default": '', trim: true },
	createAt: { type: Date, "default": Date.now },
	lastModified: { type: Date, "default": Date.now }
)

clientModel = mongo.client.model 'Client', Client

Client.plugin(pureautoinc.plugin, {
    model: 'Client',
    field: 'id'
});

module.exports = clientModel

