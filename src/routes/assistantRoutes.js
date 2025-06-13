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
    .isArray({ max: 5 }).withMessage('Context cannot contain more than 5 messages')
    // .custom((value) => { // Replaced custom validation with isArray({ max: 5 })
    //   if (value && value.length > 10) { 
    //     throw new Error('Context cannot contain more than 10 messages');
    //   }
    //   return true;
    // }), // Retaining .optional() so it's not required
    // Ensure each item in the array is an object with specific properties if needed,
    // but for now, just limiting length.
    .custom((value) => { // Keep custom validation to ensure it's an array of objects if that's intended.
                         // For now, the primary goal is to limit length.
                         // If further validation of array elements is needed, it can be added here.
      if (value) { // value is already known to be an array due to .isArray()
        if (value.length > 5) { // This check is redundant if isArray({max:5}) works as expected,
                                // but kept for explicit clarity or if isArray({max:5}) isn't supported in this version.
                                // express-validator's isArray() can take options like { min, max }.
          throw new Error('Context cannot contain more than 5 messages');
        }
        // Optionally, validate structure of each message in context:
        // for (const item of value) {
        //   if (typeof item !== 'object' || item === null || !item.role || !item.content) {
        //     throw new Error('Each context message must be an object with role and content');
        //   }
        // }
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
