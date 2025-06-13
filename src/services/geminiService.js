const { GoogleGenerativeAI } = require('@google/generative-ai');
const logger = require('../utils/logger');
const { AppError } = require('../middleware/errorHandler');

class GeminiService {
  constructor() {
    this.apiKey = process.env.GEMINI_API_KEY;
    this.modelName = process.env.GEMINI_MODEL || 'gemini-pro';
    
    if (!this.apiKey) {
      throw new Error('GEMINI_API_KEY is not configured');
    }

    this.genAI = new GoogleGenerativeAI(this.apiKey);
    this.model = this.genAI.getGenerativeModel({ model: this.modelName });
    
    this.systemPrompt = `You are Arco, a knowledgeable and friendly virtual cultivation assistant. 
Your role is to help users with gardening, plant care, and cultivation questions. 

Key guidelines:
- Provide accurate, practical advice based on best gardening practices
- Consider the user's climate, season, and location when relevant
- Suggest organic and sustainable methods when possible
- Be encouraging and supportive, especially for beginners
- Keep responses concise but informative (2-3 paragraphs max)
- If you're unsure about something, acknowledge it and suggest consulting local experts
- Focus on plant health, growth optimization, and problem-solving
- Include specific actionable steps when giving advice`;
  }

  async generateResponse(userMessage, options = {}) {
    try {
      // Build conversation history
      const conversationHistory = this.buildConversationHistory(options.context || []);
      
      // Prepare the prompt
      const prompt = this.buildPrompt(userMessage, conversationHistory, options.language);
      
      // Configure generation settings
      const generationConfig = {
        temperature: options.temperature || 0.7,
        topP: 0.9,
        topK: 40,
        maxOutputTokens: options.maxTokens || 2048,
      };

      // Generate response
      const result = await this.model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig,
      });

      const response = await result.response;
      const text = response.text();

      if (!text) {
        throw new AppError('No response generated from Gemini', 500);
      }

      // Count tokens (approximate)
      const tokensUsed = this.estimateTokens(prompt + text);

      // Generate follow-up suggestions
      const suggestions = await this.generateSuggestions(text, options.language);

      return {
        text: text.trim(),
        tokensUsed,
        suggestions
      };

    } catch (error) {
      logger.error('Gemini service error:', error);
      
      if (error.message?.includes('API key')) {
        throw new AppError('Invalid Gemini API key', 401);
      } else if (error.message?.includes('quota')) {
        throw new AppError('API quota exceeded', 429);
      } else if (error.message?.includes('SAFETY')) {
        throw new AppError('Content was blocked for safety reasons', 400);
      }
      
      throw new AppError('Failed to generate response', 500);
    }
  }

  buildConversationHistory(context) {
    if (!context || context.length === 0) {
      return '';
    }

    // Take only the last 5 messages to keep context manageable
    const recentContext = context.slice(-5);
    
    return recentContext.map(msg => {
      const role = msg.role === 'user' ? 'User' : 'Assistant';
      return `${role}: ${msg.content}`;
    }).join('\n');
  }

  buildPrompt(userMessage, conversationHistory, language = 'en') {
    let prompt = this.systemPrompt + '\n\n';
    
    // Add language instruction if not English
    if (language !== 'en') {
      const languageNames = {
        es: 'Spanish',
        fr: 'French',
        de: 'German',
        it: 'Italian',
        pt: 'Portuguese',
        zh: 'Chinese',
        ja: 'Japanese',
        ko: 'Korean'
      };
      prompt += `Please respond in ${languageNames[language] || 'English'}.\n\n`;
    }
    
    // Add conversation history if available
    if (conversationHistory) {
      prompt += 'Previous conversation:\n' + conversationHistory + '\n\n';
    }
    
    // Add current message
    prompt += `User: ${userMessage}\nAssistant:`;
    
    return prompt;
  }

  /**
   * Generate follow-up suggestions based on the response
   * @param {string} response - Generated response
   * @param {string} language - Language for suggestions
   * @returns {Promise<Array>} Suggested follow-up questions
   */
  async generateSuggestions(response, language = 'en') {
    try {
      const prompt = `Based on this gardening advice: "${response.substring(0, 200)}..."
      
Generate 3 short follow-up questions a user might ask (in ${language}). 
Format: Return only the questions, one per line, no numbering or bullets.`;

      const result = await this.model.generateContent({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.8,
          maxOutputTokens: 150,
        },
      });

      const suggestionsText = result.response.text();
      const suggestions = suggestionsText
        .split('\n')
        .filter(line => line.trim().length > 0)
        .slice(0, 3)
        .map(line => line.trim());

      return suggestions;
    } catch (error) {
      logger.error('Error generating suggestions:', error);
      return []; // Return empty array if suggestions fail
    }
  }

  estimateTokens(text) {
    // Rough estimation: ~4 characters per token
    return Math.ceil(text.length / 4);
  }
}

module.exports = new GeminiService();