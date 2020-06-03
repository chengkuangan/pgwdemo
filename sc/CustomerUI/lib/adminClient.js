
const axios = require('axios');
var querystring = require('querystring');
//const keycloak = require('keycloak-connect');
//const jwt = require('jsonwebtoken');

//const request = require('request-promise-native');

class KeyCloakAdminRequest {

    constructor(config) {
        this.config = KeyCloakAdminRequest.createAdminClientConfig(config);
    }

    static createAdminClientConfig(config) {
        const authServerUrl = `${config.serverUrl}/auth`;
        return {
            realm: config.realm,
            baseUrl: authServerUrl,
            resource: config.resource,
            username: config.adminLogin,
            password: config.adminPassword,
            grant_type: 'password',
            client_id: config.adminClienId || 'admin-cli',
            token: ''
        };
        console.log('herere');
    }

    authenticate() {
        let config = this.config;
        var promise = new Promise(function (resolve, reject) {
            axios.post(config.baseUrl + `/realms/${config.realm}/protocol/openid-connect/token`,
                querystring.stringify({
                    username: `${config.username}`, //gave the values directly for testing
                    password: `${config.password}`,
                    grant_type: 'password',
                    client_id: 'admin-cli'
                }),
                {
                    headers: { "Content-Type": "application/x-www-form-urlencoded" }
                }).then(response => {
                    //console.log('response.data = ' + response.data);
                    //console.log('access token = ' + response.data.access_token);
                    resolve(response.data.access_token);
                })
                .catch(function (error) {
                    reject(error);
                    console.log("Error in authenticate()");
                    console.log(error);
                });

        });
        return promise;
    }

    getUser(username, success, error) {
        //return this.authenticate().then(token => this.doGet(`/admin/realms/${this.config.realm}/users?username=${username}`, token));
        return this.authenticate()
            .then(token => this.doGet(`/admin/realms/${this.config.realm}/users?username=${username}`, token)
                .then(response => {
                    success(response.data[0]);
                }
                ))
            .catch(err => {
                error(err);
            });
    }

    currentUsername(request) {
        return this.getAccessToken(request)
            .then(token => Promise.resolve(jwt.decode(token).preferred_username));
    }

    getAccessToken(request) {
        let tokens = this.keyCloak.stores[1].get(request);
        let result = tokens && tokens.access_token;
        return result ? Promise.resolve(result) : Promise.reject('There is not token.');
    }

    async doGet(url, token) {
        let baseUrl = this.config.baseUrl;
        //console.log("token = " + token);
        return await axios.get(baseUrl + url,
            {
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${token}`
                }
            }).then(response => {
                //console.log('--> response = ' + response.data[0].username);
                return response;
            })
            .catch(function (error) {
                console.log(error);
            });

        //return promise;
        /*
        return this.authenticate().then(token => {
            console.log ('typeof = ' + typeof(token));
            axios.get(baseUrl + url,
                {
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${token}`
                    }
                }).then(response => {
                    //console.log('access token = ' + response.data.access_token);
                    callback(response);
                })
                .catch(function (error) {
                    console.log(error);
                });
        });
        */
    }

    /*
    doRequest(method, url, accessToken, jsonBody) {
        let options = {
            url: this.config.baseUrl + url,
            auth: {
                bearer: accessToken
            },
            method: method,
            json: true
        };

        if (jsonBody !== null) {
            options.body = jsonBody;
        }

        return request(options).catch(error => Promise.reject(error.message ? error.message : error));
    }
    */

}

module.exports = KeyCloakAdminRequest;