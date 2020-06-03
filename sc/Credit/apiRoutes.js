// Initialize express router
let router = require('express').Router();
// Set default API response
router.get('/', function (req, res) {
    res.json({
        status: 'API is Working',
        message: 'This is Money Transfer Module.',
    });
});
// Import contact controller
var creditController = require('./creditController');
// Contact routes
router.route('/credits')
    .post(creditController.new);
// Export API routes
module.exports = router;