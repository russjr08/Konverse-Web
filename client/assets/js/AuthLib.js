var AuthLib = {

    checkTokens: function() {
      if(!$.cookie('auth-token') || !$.cookie('auth-username')) {
          window.location = 'http://auth.kronosad.com/'
      } else {
        // Verify that the stored token is still valid.
        $.ajax({
            type: "POST",
            url: "http://auth.kronosad.com/api/check_token/",
            data: {
                username: $.cookie('auth-username'),
                auth_token: $.cookie('auth-token')
            },
            success: function(data) {
                if(data.message !== "Authentication Token is valid."){
                    console.log("Warning: Saved auth token is no longer valid. Redirecting to login page!");
                    window.location = 'http://auth.kronosad.com/'
                }
            },
            error: function(error) {
                console.log(error);
            }
        });
      }
    },

    getUsername: function() {
        AuthLib.checkTokens();
        return $.cookie('auth-username');
    },

    getToken: function() {
        AuthLib.checkTokens();
        return $.cookie('auth-token');
    }





}
