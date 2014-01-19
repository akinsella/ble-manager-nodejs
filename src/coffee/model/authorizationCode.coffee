pureautoinc  = require 'mongoose-pureautoinc'

mongo = require '../lib/mongo'

AuthorizationCode = new mongo.Schema(
	id: Number,
	token: {type: String, "default": '', trim: true},
	userID: {type: String, "default": '', trim: true},
	clientID: {type: String, "default": '', trim: true},
	redirectURI: {type: String, "default": '', trim: true},
	createAt: { type: Date, "default": Date.now },
	lastModified: { type: Date, "default": Date.now }
)

authorizationCodeModel = mongo.client.model 'AuthorizationCode', AuthorizationCode

AuthorizationCode.plugin(pureautoinc.plugin, {
    model: 'AuthorizationCode',
    field: 'id'
});

module.exports = authorizationCodeModel

