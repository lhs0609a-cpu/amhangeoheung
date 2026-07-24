const express = require('express');
const router = express.Router();
const seasonController = require('../controllers/seasonController');
const { authenticate } = require('../middleware/auth');

router.get('/', authenticate, seasonController.getActiveSeasons);
router.get('/:id', authenticate, seasonController.getSeasonDetail);

module.exports = router;
