io = require('socket.io').listen(4040)
http = require('http')
request = require('request')
querystring = require('querystring')

users = []
	

io.on('connection', (socket) ->
	user = ''

	console.log('A client is attempting connection...')

	socket.on('user-join', (msg) ->
		console.log(msg.user + ' has joined!');

		user = msg.user

		console.log("Verifying " + msg.user + "'s identity with the Auth server!")

		request.post('http://auth.kronosad.com/api/check_token/', {
			form: {
				username: msg.user
				auth_token: msg.token
			}
		}, (error, response, body) ->
			res = JSON.parse(body)
			console.log(res.message)
			if(res.message == "Authentication Token is valid.")
				console.log('Identity was verified!')
				users.push({"socket": socket, "user": msg.user})

				socket.emit('chatmessage', {
					"user": "Server"
					"message": "Hello there, #{msg.user}!"
				})

				io.emit('chatmessage', {
					"user": "Server"
					"message": "Yay! #{msg.user} has joined the party!"
				})

				updateUsers()				
			else
				console.log('Identity is not valid!')
				socket.disconnect('Authentication failed')
		)		

	)

	socket.on('chatmessage', (msg) ->
		console.log(msg)
		if msg.message != ''
			io.emit('chatmessage', msg)
	)

	socket.on('disconnect', () ->
		console.log('client disconnected')


		for i in [0..users.length] by 1
			if(users[i] != undefined and users[i].user == user)
				console.log(users[i].user + ' has left')
				io.emit('chatmessage', {
					"user": "Server"
					"message": "#{users[i].user} has left the party."
				})
				users.pop(i)
				updateUsers()
		
	)

)

updateUsers = () ->
	users_to_send = []
	for user in users
		users_to_send.push({"name": user.user})

	io.emit('user-list-update', users_to_send)


console.log('Listening on port 4040')