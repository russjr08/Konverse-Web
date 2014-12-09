app = angular.module 'ChatApp', ['ngMaterial', 'ngSanitize']

app.controller 'HomeController',
	HomeController = ($scope, $mdToast, $sce, $mdDialog) ->


		# Make sure the user is authenticated
		AuthLib.checkTokens();

		$scope.username = AuthLib.getUsername()

		# Allow access of '$scope' in the browser console... for debugging purposes only!
		window.$scope = $scope

		$scope.version = "v1.0 Alpha"

		$scope.messages = []
		$scope.users = []


		window.promptServer = () ->
			$mdDialog.show({
				controller: ServerPromptController
				templateUrl: 'assets/templates/ServerPrompt.tmpl.html'
				escapeToClose: false
				clickOutsideToClose: false
			})

		if (Notification?) # Some browsers (namely mobile) don't support Notifications.
			$mdDialog.show({
				controller: NotificationDialogController
				templateUrl: 'assets/templates/NotificationDialog.tmpl.html'
				escapeToClose: false
				clickOutsideToClose: false
			})
		else
			$scope.messages.push({
				"user": "Warning"
				"message": "Your browser doesn't support Notifications, you won't be notified when pinged in chat!"
			})
			window.promptServer()

		window.connect = (server, port) ->
		# Socket initialization
			@socket = io("#{server}:#{port}");
			window.socket = @socket # For in browser debugging TODO: Remove this!

			@socket.on('connect', () =>
				$scope.messages = []
				$scope.$apply()
				console.log("Connecting as..." + $scope.username)
				socket.emit('user-join', {
					'user': $scope.username
					'token': AuthLib.getToken()
				})
			)


			@socket.on('user-list-update', (users) ->

				for user in users
					$.get("http://kronosad.com:3000/users/#{user.name}", (res) ->


						if(res.message == "Color found.")
							color = '#' + res.color
						else
							color = '#FAFAFA'

						user.color = color
					)

				$scope.users = users
				$scope.$apply()

			)

			@socket.on('chatmessage', (chat) =>
				if(Notification?)
					if chat.message.indexOf($scope.username) > -1 and chat.user != "Server" and chat.user != $scope.username
						n = new Notification("[Konverse] Someone pinged you in the chat!", {
							body: "#{chat.user} said your name in chat!"
							icon: "/img/icon.png"
						})

				$.get('http://kronosad.com:3000/users/' + chat.user, (res) ->
					username = chat.user

					color = '#FFFFFF'

					if(username == 'Server')
						color = '#F44336'
					if(res.message == "Color found.")
						color = '#' + res.color
					
					$scope.messages.push({
						"user": username
						"message": chat.message
						color: color
					})
					$scope.$apply()

					box = document.getElementById('messagebox')
					box.scrollTop = box.scrollHeight; # Auto scroll down after a message is added

				).error(() ->
					console.error('Could not access the color API server, falling back.')

					username = chat.user

					if(username == 'Server')
						color = "#F44336"

					$scope.messages.push({
						"user": username
						"message": chat.message
					})
					$scope.$apply()

					box = document.getElementById('messagebox')
					box.scrollTop = box.scrollHeight; # Auto scroll down after a message is added
				)
				
			)

			@socket.on('disconnect', () ->
				$scope.messages.push({
					"user": "Error"
					"message": "Disconnected from the server!"
				})
				$scope.$apply()
			)

		# Hook up DOM listeners
		inputcomponent = document.getElementById('inputcomponent')
		inputcomponent.onkeydown = (e) ->
			if(e.keyCode == 13)
				socket.emit('chatmessage', {
					"user": $scope.username
					"message": $scope.input
				})
				$scope.input = "" # Clear the input field after we send a message

		# Util methods
		$scope.getMessageClasses = (msg) ->
			if(msg.message.indexOf($scope.username) > -1 and msg.user != "Server")
				return 'important'


NotificationDialogController = ($scope, $mdDialog) ->
	$scope.status = "Requesting"
	$scope.denied = false

	Notification.requestPermission((permission) ->
		if(permission == "granted")
			$mdDialog.hide()
			window.promptServer()
		else
			$scope.status = permission
			$scope.denied = true
	)

ServerPromptController = ($scope, $mdDialog) ->
	$scope.server = window.location.hostname
	$scope.port = 4040

	$scope.done = () ->
		$mdDialog.hide()
		window.connect($scope.server, $scope.port)