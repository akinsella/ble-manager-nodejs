###
Module dependencies.
###
oauth2orize = require "oauth2orize"
passport = require "passport"

db = require "./db"
utils = require "./lib/utils"
security = require "./lib/security"

# create OAuth 2.0 server
server = oauth2orize.createServer()

# Register serialialization and deserialization functions.
#
# When a client redirects a user to user authorization endpoint, an
# authorization transaction is initiated.  To complete the transaction, the
# user must authenticate and approve the authorization request.  Because this
# may involve multiple HTTP request/response exchanges, the transaction is
# stored in the session.
#
# An application must supply serialization functions, which determine how the
# client object is serialized into the session.  Typically this will be a
# simple matter of serializing the client's ID, and deserializing by finding
# the client by ID from the database.
server.serializeClient (client, done) ->
	done null, client.id

server.deserializeClient (id, done) ->
	db.clients.find id, (err, client) ->
		return done(err)  if err
		done null, client


# Register supported grant types.
#
# OAuth 2.0 specifies a framework that allows users to grant client
# applications limited access to their protected resources.  It does this
# through a process of the user granting access, and the client exchanging
# the grant for an access token.

# Grant authorization codes.  The callback takes the `client` requesting
# authorization, the `redirectURI` (which is used as a verifier in the
# subsequent exchange), the authenticated `user` granting access, and
# their response, which contains approved scope, duration, etc. as parsed by
# the application.  The application issues a code, which is bound to these
# values, and will be exchanged for an access token.
server.grant oauth2orize.grant.code((client, redirectURI, user, ares, done) ->
	code = utils.uid(16)
	db.authorizationCodes.save code, client.id, redirectURI, user.id, (err) ->
		return done(err)  if err
		done null, code
)

# Exchange authorization codes for access tokens.  The callback accepts the
# `client`, which is exchanging `code` and any `redirectURI` from the
# authorization request for verification.  If these values are validated, the
# application issues an access token on behalf of the user who authorized the
# code.
server.exchange oauth2orize.exchange.code((client, code, redirectURI, done) ->
	db.authorizationCodes.find code, (err, authCode) ->
		return done(err) if err
		return done(null, false) if client.id isnt authCode.clientID
		return done(null, false) if redirectURI isnt authCode.redirectURI
		token = utils.uid(256)
		db.accessTokens.save token, authCode.userID, authCode.clientID, (err) ->
			return done(err)  if err
			done null, token
)

# user authorization endpoint
#
# `authorization` middleware accepts a `validate` callback which is
# responsible for validating the client making the authorization request.  In
# doing so, is recommended that the `redirectURI` be checked against a
# registered value, although security requirements may vary accross
# implementations.  Once validated, the `done` callback must be invoked with
# a `client` instance, as well as the `redirectURI` to which the user will be
# redirected after an authorization decision is obtained.
#
# This middleware simply initializes a new authorization transaction.  It is
# the application's responsibility to authenticate the user and render a dialog
# to obtain their approval (displaying details about the client requesting
# authorization).  We accomplish that here by routing through `ensureLoggedIn()`
# first, and rendering the `dialog` view.
exports.authorization = [security.ensureAuthenticated, server.authorization((clientID, redirectURI, done) ->
	db.clients.findByClientId clientID, (err, client) ->
		return done(err)  if err

		# WARNING: For security purposes, it is highly advisable to check that
		#          redirectURI provided by the client matches one registered with
		#          the server.  For simplicity, this example does not.  You have
		#          been warned.
		done null, client, redirectURI

), (req, res) ->
	res.render "dialog",
		transactionID: req.oauth2.transactionID
		user: req.user
		client: req.oauth2.client

]

# user decision endpoint
#
# `decision` middleware processes a user's decision to allow or deny access
# requested by a client application.  Based on the grant type requested by the
# client, the above grant middleware configured above will be invoked to send
# a response.
exports.decision = [security.ensureAuthenticated, server.decision()]

# token endpoint
#
# `token` middleware handles client requests to exchange authorization grants
# for access tokens.  Based on the grant type being exchanged, the above
# exchange middleware will be invoked to handle the request.  Clients must
# authenticate when making requests to this endpoint.
exports.token = [passport.authenticate( ["basic", "oauth2-client-password"], session: false ), server.token(), server.errorHandler()]