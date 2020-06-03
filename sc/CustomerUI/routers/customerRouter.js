var express = require('express');
var router = express.Router();

// Require controller modules.
var customer_controller = require('../controllers/customerController');

// display index view
router.get('/', customer_controller.index);
router.get('/transfer', customer_controller.transfer);
router.post('/transfer', customer_controller.post_transfer);

// display create view
//router.get('/customer', customer_controller.customer);

module.exports = router;