const geminiService = require('../services/geminiService');
const logger = require('../utils/logger');
const { AppError } = require('../middleware/errorHandler');

const assistantController = {

  async chat(req, res, next) {
    try {
      const { message, context, language } = req.body;
      
      logger.info(`Processing chat request. Language: ${language || 'en'}`);

      // Prepare chat options
      const options = {
        language: language || 'en',
        context: context || [],
        temperature: 0.7,
        maxTokens: parseInt(process.env.GEMINI_MAX_TOKENS) || 2048
      };

      // Get response from Gemini
      const response = await geminiService.generateResponse(message, options);

      // Format response
      const formattedResponse = {
        success: true,
        data: {
          message: response.text,
          metadata: {
            timestamp: new Date().toISOString(),
            language: options.language,
            tokens_used: response.tokensUsed
          }
        }
      };

      if (response.suggestions && response.suggestions.length > 0) {
        formattedResponse.data.suggestions = response.suggestions;
      }

      logger.info('Chat response generated successfully');
      res.status(200).json(formattedResponse);

    } catch (error) {
      logger.error(`Chat error: ${error.message}`);
      next(error);
    }
  },

  async getConversationStarters(req, res, next) {
    try {
      const language = req.query.language || 'en';
      
      const starters = {
        en: [
          "What vegetables grow well in shade?",
          "How do I know when to water my plants?",
          "What are the best plants for beginners?",
          "How can I improve my soil quality?",
          "What plants attract beneficial insects?"
        ],
        es: [
          "¿Qué vegetales crecen bien en la sombra?",
          "¿Cómo sé cuándo regar mis plantas?",
          "¿Cuáles son las mejores plantas para principiantes?",
          "¿Cómo puedo mejorar la calidad de mi suelo?",
          "¿Qué plantas atraen insectos beneficiosos?"
        ],
        fr: [
          "Quels légumes poussent bien à l'ombre?",
          "Comment savoir quand arroser mes plantes?",
          "Quelles sont les meilleures plantes pour les débutants?",
          "Comment puis-je améliorer la qualité de mon sol?",
          "Quelles plantes attirent les insectes bénéfiques?"
        ]
      };

      res.status(200).json({
        success: true,
        data: {
          language,
          starters: starters[language] || starters.en
        }
      });
    } catch (error) {
      logger.error(`Error fetching conversation starters: ${error.message}`);
      next(error);
    }
  },

  async getSupportedLanguages(req, res, next) {
    try {
      const languages = [
        { code: 'en', name: 'English', native: 'English' },
        { code: 'es', name: 'Spanish', native: 'Español' },
        { code: 'fr', name: 'French', native: 'Français' },
        { code: 'de', name: 'German', native: 'Deutsch' },
        { code: 'it', name: 'Italian', native: 'Italiano' },
        { code: 'pt', name: 'Portuguese', native: 'Português' },
        { code: 'zh', name: 'Chinese', native: '中文' },
        { code: 'ja', name: 'Japanese', native: '日本語' },
        { code: 'ko', name: 'Korean', native: '한국어' }
      ];

      res.status(200).json({
        success: true,
        data: languages
      });
    } catch (error) {
      logger.error(`Error fetching supported languages: ${error.message}`);
      next(error);
    }
  }
};

module.exports = assistantController;