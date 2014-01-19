pureautoinc  = require 'mongoose-pureautoinc'

mongo = require '../lib/mongo'

AccesToken = new mongo.Schema(
	id: Number,
	token: {type: String, "default": '', trim: true},
	userID: {type: String, "default": '', trim: true},
	clientID: {type: String, "default": '', trim: true},
	createAt: { type: Date, "default": Date.now },
	lastModified: { type: Date, "default": Date.now }
)

accessTokenModel = mongo.client.model 'AccesToken', AccesToken

AccesToken.plugin(pureautoinc.plugin, {
    model: 'AccesToken',
    field: 'id'
});

module.exports = accessTokenModel

