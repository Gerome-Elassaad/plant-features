const axios = require('axios');
const logger = require('../utils/logger');
const { AppError } = require('../middleware/errorHandler');

class PlantIdService {
  constructor() {
    this.apiKey = process.env.PLANT_ID_API_KEY;
    this.apiUrl = process.env.PLANT_ID_API_URL || 'https://api.plant.id/v3/identification';
    this.timeout = parseInt(process.env.PLANT_ID_TIMEOUT) || 30000;

    if (!this.apiKey) {
      throw new Error('PLANT_ID_API_KEY is not configured');
    }
  }


  async identifyPlant(imageBuffer, options = {}) {
    try {
      // Convert image buffer to base64
      const base64Image = imageBuffer.toString('base64');

      // Prepare request payload
      const payload = {
        images: [`data:image/jpeg;base64,${base64Image}`],
        plant_details: options.plant_details || ['common_names', 'url'],
        plant_language: options.plant_language || 'en',
        similar_images: options.similar_images || false
      };

      // Add location if provided
      if (options.latitude && options.longitude) {
        payload.latitude = options.latitude;
        payload.longitude = options.longitude;
      }

      // Add health assessment
      payload.health = 'all';

      // Make API request
      const response = await axios.post(this.apiUrl, payload, {
        headers: {
          'Api-Key': this.apiKey,
          'Content-Type': 'application/json'
        },
        timeout: this.timeout
      });

      // Validate response
      if (!response.data || !response.data.result) {
        throw new AppError('Invalid response from Plant.id API', 500);
      }

      // Process and return results
      return this.processPlantIdResponse(response.data.result);

    } catch (error) {
      if (error.response) {
        // API error response
        const status = error.response.status;
        const message = error.response.data?.error?.message || 'Plant.id API error';
        
        if (status === 401) {
          throw new AppError('Invalid Plant.id API key', 401);
        } else if (status === 429) {
          throw new AppError('Plant.id API rate limit exceeded', 429);
        } else if (status === 400) {
          throw new AppError(`Invalid request: ${message}`, 400);
        }
        
        throw new AppError(message, status);
      } else if (error.code === 'ECONNABORTED') {
        throw new AppError('Plant.id API request timeout', 504);
      }
      
      throw error;
    }
  }

  /**
   * Process Plant.id API response
   * @param {Object} result - Raw API result
   * @returns {Object} Processed result
   */
  processPlantIdResponse(result) {
    const processed = {
      is_plant: result.is_plant.binary,
      is_plant_probability: result.is_plant.probability,
      suggestions: [],
      health_assessment: null,
      disease_suggestions: [],
      version: result.classification?.version,
      custom_id: result.custom_id
    };

    // Process plant suggestions
    if (result.classification?.suggestions) {
      processed.suggestions = result.classification.suggestions.slice(0, 5).map(suggestion => ({
        id: suggestion.id,
        plant_name: suggestion.name,
        plant_details: {
          scientific_name: suggestion.details?.scientific_name || suggestion.name,
          common_names: suggestion.details?.common_names || [],
          url: suggestion.details?.url,
          description: suggestion.details?.description?.value,
          synonyms: suggestion.details?.synonyms || [],
          image: suggestion.details?.image?.value
        },
        probability: suggestion.probability,
        confirmed: suggestion.confirmed || false,
        similar_images: suggestion.similar_images?.map(img => ({
          id: img.id,
          url: img.url,
          similarity: img.similarity
        })) || []
      }));
    }

    // Process health assessment
    if (result.health_assessment) {
      processed.health_assessment = {
        is_healthy: result.health_assessment.is_healthy.binary,
        is_healthy_probability: result.health_assessment.is_healthy.probability,
        diseases: []
      };

      // Process disease suggestions
      if (result.health_assessment.diseases) {
        processed.disease_suggestions = result.health_assessment.diseases.slice(0, 3).map(disease => ({
          id: disease.id,
          name: disease.name,
          probability: disease.probability,
          disease_details: {
            description: disease.disease_details?.description,
            treatment: disease.disease_details?.treatment,
            cause: disease.disease_details?.cause,
            url: disease.disease_details?.url
          },
          similar_images: disease.similar_images?.map(img => ({
            id: img.id,
            url: img.url,
            similarity: img.similarity
          })) || []
        }));

        processed.health_assessment.diseases = processed.disease_suggestions;
      }
    }

    return processed;
  }

  async getAvailableModifiers() {
    try {
      const response = await axios.get(`${this.apiUrl}/modifiers`, {
        headers: {
          'Api-Key': this.apiKey
        },
        timeout: 10000
      });

      return response.data;
    } catch (error) {
      logger.error('Error fetching Plant.id modifiers:', error);
      throw new AppError('Failed to fetch available modifiers', 500);
    }
  }
}

module.exports = new PlantIdService();