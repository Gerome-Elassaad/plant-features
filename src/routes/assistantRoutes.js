const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const assistantController = require('../controllers/assistantController');
const validateRequest = require('../middleware/validateRequest');

const rateLimit = require('express-rate-limit');
const chatLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 20, // 20 requests per minute
  message: 'Too many chat requests, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Validation rules
const chatValidation = [
  body('message')
    .notEmpty().withMessage('Message is required')
    .isString().withMessage('Message must be a string')
    .isLength({ min: 1, max: 2000 }).withMessage('Message must be between 1 and 2000 characters'),
  body('context')
    .optional()
    .isArray().withMessage('Context must be an array')
    .custom((value) => {
      if (value && value.length > 10) {
        throw new Error('Context cannot contain more than 10 messages');
      }
      return true;
    }),
  body('language')
    .optional()
    .isString()
    .isIn(['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ko'])
    .withMessage('Unsupported language')
];

// Routes
router.post(
  '/chat',
  chatLimiter,
  chatValidation,
  validateRequest,
  assistantController.chat
);

// Get conversation starters
router.get('/starters', assistantController.getConversationStarters);

// Get supported languages
router.get('/languages', assistantController.getSupportedLanguages);

module.exports = router;