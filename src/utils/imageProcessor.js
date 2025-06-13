const sharp = require('sharp');
const logger = require('./logger');
const { AppError } = require('../middleware/errorHandler');

class ImageProcessor {
  constructor() {
    this.maxWidth = 1024;
    this.maxHeight = 1024;
    this.quality = 85;
    this.maxFileSize = 1024 * 1024;
  }

  async processImage(imageBuffer) {
    try {
      // Get image metadata
      const metadata = await sharp(imageBuffer).metadata();
      logger.info(`Processing image: ${metadata.width}x${metadata.height}, format: ${metadata.format}`);

      // Calculate new dimensions while maintaining aspect ratio
      let width = metadata.width;
      let height = metadata.height;

      if (width > this.maxWidth || height > this.maxHeight) {
        const aspectRatio = width / height;
        
        if (width > height) {
          width = this.maxWidth;
          height = Math.round(width / aspectRatio);
        } else {
          height = this.maxHeight;
          width = Math.round(height * aspectRatio);
        }
      }

      // Process image
      let processedImage = await sharp(imageBuffer)
        .resize(width, height, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .jpeg({ quality: this.quality, progressive: true })
        .toBuffer();

      // Check file size and reduce quality if needed
      let currentQuality = this.quality;
      while (processedImage.length > this.maxFileSize && currentQuality > 50) {
        currentQuality -= 10;
        processedImage = await sharp(imageBuffer)
          .resize(width, height, {
            fit: 'inside',
            withoutEnlargement: true
          })
          .jpeg({ quality: currentQuality, progressive: true })
          .toBuffer();
      }

      logger.info(`Image processed: ${width}x${height}, size: ${(processedImage.length / 1024).toFixed(2)}KB, quality: ${currentQuality}`);
      return processedImage;

    } catch (error) {
      logger.error('Image processing error:', error);
      throw new AppError('Failed to process image', 400);
    }
  }

  /**
   * Validate image format
   * @param {Buffer} imageBuffer - Image buffer to validate
   * @returns {Promise<boolean>} Is valid image
   */
  async validateImage(imageBuffer) {
    try {
      const metadata = await sharp(imageBuffer).metadata();
      const validFormats = ['jpeg', 'jpg', 'png', 'webp'];
      return validFormats.includes(metadata.format);
    } catch (error) {
      return false;
    }
  }

  async getImageMetadata(imageBuffer) {
    try {
      const metadata = await sharp(imageBuffer).metadata();
      return {
        width: metadata.width,
        height: metadata.height,
        format: metadata.format,
        size: imageBuffer.length,
        density: metadata.density,
        hasAlpha: metadata.hasAlpha,
        orientation: metadata.orientation
      };
    } catch (error) {
      logger.error('Error extracting image metadata:', error);
      throw new AppError('Failed to extract image metadata', 400);
    }
  }
}

module.exports = new ImageProcessor();