const plantIdService = require('../services/plantIdService');
const imageProcessor = require('../utils/imageProcessor');
const logger = require('../utils/logger');
const { AppError } = require('../middleware/errorHandler');

const diagnosisController = {

  async analyzePlant(req, res, next) {
    try {
      if (!req.file) {
        throw new AppError('No image file provided', 400);
      }

      logger.info(`Processing plant diagnosis request for file: ${req.file.originalname}`);

      const processedImage = await imageProcessor.processImage(req.file.buffer);

      const options = {
        latitude: req.body.latitude ? parseFloat(req.body.latitude) : null,
        longitude: req.body.longitude ? parseFloat(req.body.longitude) : null,
        similar_images: req.body.similar_images || false, // Now directly use the boolean from validator
        plant_details: req.body.plant_details || ['common_names', 'url'],
        plant_language: req.body.plant_language || 'en'
      };

      const diagnosis = await plantIdService.identifyPlant(processedImage, options);

      const response = {
        success: true,
        data: {
          is_plant: diagnosis.is_plant,
          is_plant_probability: diagnosis.is_plant_probability,
          suggestions: diagnosis.suggestions.map(suggestion => ({
            id: suggestion.id,
            plant_name: suggestion.plant_name,
            plant_details: suggestion.plant_details,
            probability: suggestion.probability,
            confirmed: suggestion.confirmed,
            similar_images: suggestion.similar_images || []
          })),
          health_assessment: diagnosis.health_assessment,
          disease_suggestions: diagnosis.disease_suggestions,
          metadata: {
            date: new Date().toISOString(),
            version: diagnosis.version,
            custom_id: diagnosis.custom_id
          }
        }
      };

      if (options.latitude && options.longitude) {
        response.data.metadata.location = {
          latitude: options.latitude,
          longitude: options.longitude
        };
      }

      logger.info(`Plant diagnosis completed successfully. Is plant: ${diagnosis.is_plant}`);
      res.status(200).json(response);

    } catch (error) {
      logger.error(`Plant diagnosis error: ${error.message}`);
      next(error);
    }
  },


  async getModifiers(req, res, next) {
    try {
      const modifiers = await plantIdService.getAvailableModifiers();
      
      res.status(200).json({
        success: true,
        data: modifiers
      });
    } catch (error) {
      logger.error(`Error fetching modifiers: ${error.message}`);
      next(error);
    }
  }
};

module.exports = diagnosisController;
