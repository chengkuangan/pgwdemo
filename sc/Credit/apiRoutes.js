// Initialize express router
let router = require('express').Router();
// Set default API response
router.get('/', function (req, res) {
    res.json({
        status: 'API is Working',
        message: 'This is Credit Service of Payment Gateway.',
    });
});
// Import contact controller
var creditController = require('./creditController');
// Contact routes
router.post('/ws/pg/credits', creditController.create);
router.get('/metrics', creditController.metrics);    
// Export API routes
module.exports = router;