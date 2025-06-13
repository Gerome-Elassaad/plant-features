const express = require('express');
const router = express.Router();
const multer = require('multer');
const { body } = require('express-validator');
const diagnosisController = require('../controllers/diagnosisController');
const validateRequest = require('../middleware/validateRequest');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024,
    files: 1
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, and WebP images are allowed.'), false);
    }
  }
});

const diagnosisValidation = [
  body('latitude').optional().isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude'),
  body('longitude').optional().isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude'),
  body('similar_images').optional().isBoolean().withMessage('similar_images must be boolean'),
  body('plant_details').optional().isArray().withMessage('plant_details must be an array'),
  body('plant_language').optional().isString().isLength({ min: 2, max: 5 }).withMessage('Invalid language code')
];

router.post(
  '/',
  upload.single('image'),
  diagnosisValidation,
  validateRequest,
  diagnosisController.analyzePlant
);

router.get('/modifiers', diagnosisController.getModifiers);

module.exports = router;