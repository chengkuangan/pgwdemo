const express = require("express"),
  path = require("path");
const app = express();
const axios = require("axios");

//setup our app to use handlebars.js for templating
app.set("view engine", "hbs");
app.set("views", path.join(__dirname, "views"));

// --- instantiate Keycloak admin client
const AdminClient = require("../lib/adminClient");

var customerAPI_URL =
  process.env.CUSTOMER_API_URL || "http://localhost:8083/ws/pg/customer";
var creditAPI_URL =
  process.env.CREDIT_API_URL || "http://localhost:8084/ws/pg/credits";
var rhsso_URL =
  process.env.RHSSO_URL || "http://localhost:8080";
  

let adminClient = new AdminClient({
  realm: "PaymentGateway",
  serverUrl: rhsso_URL,
  resource: "CustomerAccount",
  adminLogin: "pg_admin",
  adminPassword: "password",
});

var customer;

// Display index page.
exports.index = function (req, res) {
  // retrieve the current login username
  let currentUsername = req.kauth.grant.access_token.content.preferred_username;
  // get the accountId from the keycloak user custom attributes
  adminClient.getUser(
    currentUsername,
    function (user) {
      let accountId = user.attributes.accountId[0];
      console.log("accountId: " + accountId);
      console.log("customerAPI_URL: " + customerAPI_URL);
      axios
        .get(customerAPI_URL + "/" + accountId)
        .then((response) => {
          customer = response.data[0];
          console.log("customer: " + customer);
          console.log("customer.accountId: " + customer.accountId);
          console.log("customer.balance: " + customer.balance);
          res.render("index", { customer: customer });
        })
        .catch((error) => {
          console.log("Error:" + error);
        });
    },
    function (error) {
      console.log("error =" + error);
    }
  );
};

// Display transfer view.
exports.transfer = function (req, res) {
  console.log("creditAPI_URL: " + creditAPI_URL);
  //res.header("Access-Control-Allow-Origin", "*");
  res.render("transfer", { customer: customer, creditAPI_URL: creditAPI_URL });
};

exports.post_transfer = function (req, res) {
  console.log("Here in customerController - > post_tranfser");

  var amount = req.body.amount;
  var sourceAccount = req.body.fromAccountId;
  var targetAccount = req.body.toAccountId;

  console.log("amount = " + amount);
  console.log("sourceAccount = " + sourceAccount);
  console.log("targetAccount = " + targetAccount);

  axios
    .post(creditAPI_URL, {
      amount: amount,
      sourceAccount: sourceAccount,
      targetAccount: targetAccount,
    })
    .then((response) => {
      console.log("Response.status = " + response.status);
      console.log("response.data = " + response.data);
      result = response.data;
      if (response.status == 200) {
        res.render("transfer", { 
            status: "ok", 
            error: null,
            amount: amount,
            sourceAccount: sourceAccount,
            targetAccount: targetAccount
        });
      } else {
        res.render("transfer", {
            status: "error",
            error: result.message,
            amount: amount,
            sourceAccount: sourceAccount,
            targetAccount: targetAccount
        });
      }
    })
    .catch((error) => {
      console.log(". Error: " + error);
      res.render("transfer", {
        status: "error",
        error: "Error submitting the credit transfer",
        amount: amount,
        sourceAccount: sourceAccount,
        targetAccount: targetAccount
      });
    });
};
