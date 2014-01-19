start = new Date()

logger = require 'winston'

config = require './conf/config'

if config.devMode
	logger.info "Dev Mode enabled."

if config.offlineMode
	logger.info "Offline mode enabled."

if config.monitoring.newrelic.apiKey
	logger.info "Initializing NewRelic with apiKey: '#{config.monitoring.newrelic.apiKey}'"
	newrelic = require 'newrelic'

fs = require 'fs'
path = require 'path'
util = require 'util'
express = require 'express'

device = require './route/device'
notification = require './route/notification'

MongoStore = require('connect-mongo')(express)
mongo = require './lib/mongo'

passport = require 'passport'
role = require './lib/connect-roles-fixed'

requestLogger = require './lib/requestLogger'
allowCrossDomain = require './lib/allowCrossDomain'
utils = require './lib/utils'

security = require './lib/security'

api = require './route/api'
auth = require './route/auth'
client = require './route/client'
user = require './route/user'
oauth2 = require './oauth2'
authMiddleware = require './middleware/authMiddleware'
authService = require './service/authService'

logger.info "Application Name: #{config.appname}"
logger.info "Env: #{JSON.stringify config}"

# Express
app = express()

gracefullyClosing = false

#cacheMiddleware = (seconds) -> (req, res, next) ->
#    res.setHeader "Cache-Control", "public, max-age=#{seconds}"
#    next()

passport.serializeUser authService.serializeUser
passport.deserializeUser authService.deserializeUser

passport.use authMiddleware.GoogleStrategy
passport.use authMiddleware.BasicStrategy
passport.use authMiddleware.ClientPasswordStrategy
passport.use authMiddleware.BearerStrategy

role.use authService.checkRoleAnonymous
role.use authService.ROLE_AGENT, authService.checkRoleAgent
role.use authService.ROLE_SUPER_AGENT, authService.checkRoleSuperAgent
role.use authService.ROLE_ADMIN, authService.checkRoleAdmin
role.setFailureHandler authService.failureHandler

app.configure ->
	logger.info "Environment: #{app.get('env')}"
	app.set 'port', config.port or process.env.PORT or 9000

#	app.use connectDomain()
	app.use (req, res, next) ->
		return next() unless gracefullyClosing
		res.setHeader "Connection", "close"
		res.send 502, "Server is in the process of restarting"

	app.use (req, res, next) ->
		req.forwardedSecure = (req.headers["x-forwarded-proto"] == "https")
		next()

	app.use '/', express.static("#{__dirname}/public")

	app.use express.favicon()

	app.use express.json()
	app.use express.urlencoded()
	app.use express.cookieParser()

	app.use express.session(
		secret: process.env.SESSION_SECRET,
		maxAge: new Date(Date.now() + 3600000),
		store: new MongoStore(
			db: config.mongo.dbname,
			host: config.mongo.hostname,
			port: config.mongo.port,
			username: config.mongo.username,
			password: config.mongo.password,
			collection: "sessions",
			auto_reconnect: true
		)
	)
	app.use express.logger()
	app.use express.methodOverride()
	app.use allowCrossDomain()

	app.use requestLogger()

	# Initialize Passport!  Also use passport.session() middleware, to support
	# persistent login sessions (recommended).
	app.use passport.initialize()
	app.use passport.session()

	app.use role

	app.use app.router

	app.use (err, req, res, next) ->
		console.error "Error: #{err}, Stacktrace: #{err.stack}"
		res.send 500, "Something broke! Error: #{err}, Stacktrace: #{err.stack}"



app.configure 'development', () ->
	app.use express.errorHandler
		dumpExceptions: true,
		showStack: true


app.configure 'production', () ->
	app.use express.errorHandler()

app.get "/api/info", api.informations

#app.get "/users/me", passport.authenticate("bearer", session: false), user.me
app.get "/users/me", security.ensureAuthenticated, user.me

app.post '/login', auth.login
app.get '/login', auth.loginForm
app.get '/logout', auth.logout

app.get '/auth/google', passport.authenticate('google', { failureRedirect: '/#/login' })
app.get '/auth/google/callback', passport.authenticate('google', { failureRedirect: '/#/login' }), auth.authGoogleCallback

app.delete "/devices/:id", security.ensureAuthenticated, device.removeById
app.post "/devices", security.ensureAuthenticated, device.create
app.get "/devices", security.ensureAuthenticated, device.list
app.get "/devices/:id", security.ensureAuthenticated, device.findById

app.delete "/clients/:id", security.ensureAuthenticated, client.removeById
app.post "/clients", security.ensureAuthenticated, client.create
app.get "/clients", security.ensureAuthenticated, client.list
app.get "/clients/:id", security.ensureAuthenticated, client.findById

app.post "/users", security.ensureAuthenticated, user.create
app.get "/users", security.ensureAuthenticated, user.list
app.get "/users/me", security.ensureAuthenticated, user.me
app.get "/users/:id", security.ensureAuthenticated, user.findById
app.delete "/users/:id", security.ensureAuthenticated, user.removeById

app.delete "/notifications", security.ensureAuthenticated, notification.removeById
app.post "/notifications", security.ensureAuthenticated, notification.create
app.get "/notifications", security.ensureAuthenticated, notification.list
app.get "/notifications/:id/push", security.ensureAuthenticated, notification.push
app.get "/notifications/:id", security.ensureAuthenticated, notification.findById


httpServer = app.listen app.get('port')

process.on 'SIGTERM', ->
	logger.info "Received kill signal (SIGTERM), shutting down gracefully."
	gracefullyClosing = true
	httpServer.close ->
		logger.info "Closed out remaining connections."
		process.exit()

	setTimeout ->
		console.error "Could not close connections in time, forcefully shutting down"
		process.exit(1)
	, 30 * 1000

process.on 'uncaughtException', (err) ->
	console.error "An uncaughtException was found, the program will end. #{err}, stacktrace: #{err.stack}"
	process.exit 1

logger.info "Express listening on port: #{app.get('port')}"
logger.info "Started in #{(new Date().getTime() - start.getTime()) / 1000} seconds"
