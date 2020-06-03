const express = require('express'), path = require('path');

//create our express app
const app = express();
var cors = require('cors');
app.use(cors());

var port = process.env.PORT || 3000;

// const axios = require('axios');

//setup our app to use handlebars.js for templating
app.set('view engine', 'hbs');
app.set('views', path.join(__dirname, 'views'));
app.use('/js', express.static(path.join(__dirname, 'js')));
app.use(express.urlencoded());

var hanldebars_helpers = require('./helpers/handlebarHelper');
var hbs = require('hbs');
hbs.registerHelper('ifEquals', hanldebars_helpers.ifEquals);
hbs.registerHelper('ifNull', hanldebars_helpers.ifNull);

// ----- setting for keyclock 

var session = require('express-session');
var Keycloak = require('keycloak-connect');

var memoryStore = new session.MemoryStore();
app.use(session({
  secret: 'e9c8f236-66c7-4034-9758-ab29541f9cec',
  resave: false,
  saveUninitialized: true,
  store: memoryStore
}));
var keycloak = new Keycloak({ store: memoryStore });
app.use(keycloak.middleware());

var custRouter = require('./routers/customerRouter.js');
//app.use('/', custRouter);
app.use('/', keycloak.protect('customer'), custRouter);

//have our app listen on port 3000
app.listen(port);
console.log('Customer UI is listening on port ' + port);


app.use((req, res, next) => {
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private')
  next()
})