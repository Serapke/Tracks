/**
 * Created by Mantas on 12/03/2017.
 */
window.fbAsyncInit = function() {
    FB.init({
        appId      : '969322433241610',
        xfbml      : true,
        version    : 'v2.8'
    });
};

(function(d, s, id){
    var js, fjs = d.getElementsByTagName(s)[0];
    if (d.getElementById(id)) {return;}
    js = d.createElement(s); js.id = id;
    js.src = "//connect.facebook.net/en_US/sdk.js";
    fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));

function login() {
    FB.login(function(response) {
        if (response.status === 'connected') {
            // Logged into your app and Facebook.
            console.log(response);
            checkLoginState();
        } else {
            // The person is not logged into this app or we are unable to tell.
            console.log(response);
        }
    }, {scope: 'public_profile,email,user_friends'});
}

function statusChangeCallback(response) {
    console.log('statusChangeCallback');
    console.log(response);
    // The response object is returned with a status field that lets the
    // app know the current login status of the person.
    // Full docs on the response object can be found in the documentation
    // for FB.getLoginStatus().
    if (response.status === 'connected') {
        // Logged into your app and Facebook.
        testAPI();
    } else {
        // The person is not logged into your app or we are unable to tell.
        document.getElementById('status').innerHTML = 'Please log ' +
            'into this app.';
    }
}

function testAPI() {
    console.log('Welcome!  Fetching your information.... ');
    FB.api('/me?fields=id,name,email', function(response) {
        console.log(response);
        localStorage.setItem('user', JSON.stringify(response));
        loginUser(response.email, response.id);
    });

}

function loginUser(email, password) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "https://tracks-api.herokuapp.com/sessions");
    xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
    //Send the proper header information along with the request

    xhr.send(JSON.stringify({ session: { email: email, password: password }}));
    console.log("here");
    xhr.onreadystatechange = function() {
        if (this.readyState == 4) {
            console.log(JSON.parse(this.responseText).auth_token);
            localStorage.setItem('user', JSON.parse(this.responseText).auth_token);
            location.href = "/web-client/map.html";
        }
    };
}

function checkLoginState() {
    FB.getLoginStatus(function(response) {
        statusChangeCallback(response);
    });
}