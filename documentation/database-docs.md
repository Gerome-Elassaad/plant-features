# 🌱 Aspargo Database Implementation Guide

## 📋 **Overview**

This comprehensive database schema supports the complete Aspargo plant diagnosis and virtual cultivation assistant application. The schema captures user interactions, photo analysis history, chat conversations, and detailed analytics while maintaining GDPR compliance and production-ready performance.

---

## 🏗️ **Database Architecture**

### **Core Components**
1. **User Management** - Anonymous + registered user support
2. **Plant Diagnosis** - Photo uploads and Plant.id API results
3. **Virtual Assistant** - Chat sessions and Gemini AI interactions
4. **Analytics & Logging** - Comprehensive usage tracking
5. **Data Retention** - Automated cleanup and privacy compliance

### **Technology Stack**
- **Database**: PostgreSQL 14+ (required for JSON support)
- **Extensions**: uuid-ossp, pgcrypto, pgTAP (testing)
- **Performance**: Strategic indexing and query optimization
- **Security**: Role-based access control and encryption

---

## 🚀 **Quick Start Setup**

### **1. Prerequisites**
```bash
# Install PostgreSQL 14+
sudo apt update
sudo apt install postgresql-14 postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### **2. Database Creation**
```bash
# Create database and user
sudo -u postgres psql
CREATE DATABASE aspargo_production;
CREATE USER aspargo_app WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE aspargo_production TO aspargo_app;
\q

# Apply schema
psql -U aspargo_app -d aspargo_production -f aspargo_database_schema.sql
```

### **3. Run Tests**
```bash
# Install pgTAP extension
sudo apt install postgresql-14-pgtap

# Run test suite
psql -U aspargo_app -d aspargo_production -f database_testing_suite.sql
```

### **4. Verify Installation**
```sql
-- Check table count and basic functionality
SELECT 
    COUNT(*) as table_count,
    (SELECT COUNT(*) FROM users) as users_ready,
    (SELECT COUNT(*) FROM chat_suggestions) as suggestions_seeded
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
```

---

## 📊 **Database Schema Details**

### **User Management Tables**

#### **users**
- **Primary Purpose**: Central user registry supporting anonymous and registered users
- **Key Features**: GDPR compliance, data retention policies, account status tracking
- **Notable Columns**:
  - `is_anonymous`: Distinguishes temporary vs permanent accounts
  - `gdpr_consent`: GDPR compliance tracking
  - `data_retention_days`: Customizable data retention per user

#### **user_sessions**
- **Primary Purpose**: Track app usage sessions for analytics
- **Key Features**: Device fingerprinting, location tracking, session duration
- **Integration**: Links to all user activities for analytics

#### **user_preferences**
- **Primary Purpose**: Store user-specific app settings
- **Key Features**: Theme, notifications, measurement units, privacy settings

### **Plant Diagnosis Tables**

#### **plant_photos**
- **Primary Purpose**: Metadata for uploaded plant images
- **Key Features**: Cloud storage references, GPS data, auto-deletion
- **Security**: No actual image data stored in database
- **Integration**: Links to diagnosis results and user sessions

#### **plant_diagnoses**
- **Primary Purpose**: Results from Plant.id API analysis
- **Key Features**: Plant identification, health assessment, confidence scores
- **Data Storage**: Full Plant.id response stored as JSONB for future analysis

#### **plant_suggestions** & **disease_suggestions**
- **Primary Purpose**: Detailed breakdown of Plant.id results
- **Key Features**: Multiple suggestions per diagnosis, ranked by confidence
- **Use Cases**: Advanced filtering, plant care recommendations

### **Virtual Assistant Tables**

#### **chat_sessions**
- **Primary Purpose**: Group related chat messages into conversations
- **Key Features**: Session analytics, user satisfaction tracking, context management
- **Integration**: Links to user sessions and message history

#### **chat_messages**
- **Primary Purpose**: Individual chat messages with AI processing details
- **Key Features**: Gemini API metadata, cost tracking, intent detection
- **Analytics**: Response times, token usage, user reactions

#### **chat_suggestions**
- **Primary Purpose**: Pre-defined conversation starters and suggestions
- **Key Features**: Multi-language support, usage tracking, categorization

### **Analytics & Monitoring Tables**

#### **api_usage_logs**
- **Primary Purpose**: Track external API usage and costs
- **Key Features**: Response time monitoring, error tracking, cost analysis
- **Business Value**: API optimization and budget management

#### **feature_analytics**
- **Primary Purpose**: Detailed user interaction tracking
- **Key Features**: Feature adoption, user flows, performance metrics
- **Privacy**: No PII storage, aggregatable data

#### **error_logs**
- **Primary Purpose**: Centralized error tracking and monitoring
- **Key Features**: Error categorization, resolution tracking, stack traces

#### **user_feedback**
- **Primary Purpose**: User feedback, ratings, and feature requests
- **Key Features**: Feedback categorization, priority tracking, contact preferences

---

## 🔧 **Node.js Backend Integration**

### **Database Connection Setup**

```javascript
// src/config/database.js
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'aspargo_app',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'aspargo_production',
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20, // Maximum pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

module.exports = { pool };
```

### **Example Controller Implementation**

```javascript
// src/controllers/userController.js
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class UserController {
  // Create anonymous user
  static async createAnonymousUser(req, res) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // Create user
      const userResult = await client.query(
        'INSERT INTO users (is_anonymous, gdpr_consent) VALUES (true, true) RETURNING id'
      );
      const userId = userResult.rows[0].id;
      
      // Create session
      const sessionResult = await client.query(`
        INSERT INTO user_sessions (
          user_id, device_type, app_version, ip_address, user_agent
        ) VALUES ($1, $2, $3, $4, $5) RETURNING id
      `, [userId, req.body.deviceType, req.body.appVersion, req.ip, req.get('User-Agent')]);
      
      // Create default preferences
      await client.query(
        'INSERT INTO user_preferences (user_id) VALUES ($1)',
        [userId]
      );
      
      await client.query('COMMIT');
      
      res.json({
        success: true,
        data: {
          userId: userId,
          sessionId: sessionResult.rows[0].id
        }
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
  
  // Track feature usage
  static async trackFeatureUsage(userId, sessionId, featureName, actionType, screenName) {
    await pool.query(`
      INSERT INTO feature_analytics (
        user_id, session_id, feature_name, action_type, feature_screen, 
        device_type, app_version
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [userId, sessionId, featureName, actionType, screenName, req.body.deviceType, req.body.appVersion]);
  }
}

module.exports = UserController;
```

### **Plant Diagnosis Integration**

```javascript
// src/controllers/diagnosisController.js
const { pool } = require('../config/database');
const plantIdService = require('../services/plantIdService');

class DiagnosisController {
  static async analyzePlant(req, res) {
    const { userId, sessionId } = req.body;
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Save photo metadata
      const photoResult = await client.query(`
        INSERT INTO plant_photos (
          user_id, session_id, original_filename, file_path, 
          file_size_bytes, mime_type, upload_source, latitude, longitude
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id
      `, [
        userId, sessionId, req.file.originalname, req.file.path,
        req.file.size, req.file.mimetype, req.body.uploadSource,
        req.body.latitude, req.body.longitude
      ]);
      
      const photoId = photoResult.rows[0].id;
      
      // Call Plant.id API
      const plantIdResponse = await plantIdService.identifyPlant(req.file.path, {
        latitude: req.body.latitude,
        longitude: req.body.longitude
      });
      
      // Save diagnosis results
      const diagnosisResult = await client.query(`
        INSERT INTO plant_diagnoses (
          photo_id, user_id, plant_id_request_id, is_plant, is_plant_probability,
          identified_plant_name, scientific_name, plant_probability,
          is_healthy, primary_disease, care_instructions, raw_plant_id_response
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id
      `, [
        photoId, userId, plantIdResponse.custom_id, plantIdResponse.is_plant,
        plantIdResponse.is_plant_probability, plantIdResponse.plant_name,
        plantIdResponse.scientific_name, plantIdResponse.plant_probability,
        plantIdResponse.is_healthy, plantIdResponse.primary_disease,
        plantIdResponse.care_instructions, JSON.stringify(plantIdResponse.raw)
      ]);
      
      const diagnosisId = diagnosisResult.rows[0].id;
      
      // Save plant suggestions
      for (let i = 0; i < plantIdResponse.suggestions.length; i++) {
        const suggestion = plantIdResponse.suggestions[i];
        await client.query(`
          INSERT INTO plant_suggestions (
            diagnosis_id, plant_name, scientific_name, probability, suggestion_rank
          ) VALUES ($1, $2, $3, $4, $5)
        `, [diagnosisId, suggestion.name, suggestion.scientific_name, suggestion.probability, i + 1]);
      }
      
      await client.query('COMMIT');
      
      res.json({
        success: true,
        data: {
          diagnosisId: diagnosisId,
          plantName: plantIdResponse.plant_name,
          confidence: plantIdResponse.plant_probability,
          isHealthy: plantIdResponse.is_healthy,
          careInstructions: plantIdResponse.care_instructions
        }
      });
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = DiagnosisController;
```

---

## 📈 **Performance Optimization**

### **Query Performance**
```sql
-- Efficient user analytics query
SELECT 
  u.id,
  COUNT(DISTINCT pp.id) as photos_uploaded,
  COUNT(DISTINCT cs.id) as chat_sessions,
  AVG(cs.user_satisfaction_rating) as avg_satisfaction
FROM users u
LEFT JOIN plant_photos pp ON u.id = pp.user_id AND pp.upload_timestamp > CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN chat_sessions cs ON u.id = cs.user_id AND cs.started_at > CURRENT_DATE - INTERVAL '30 days'
WHERE u.created_at > CURRENT_DATE - INTERVAL '30 days'
GROUP BY u.id;
```

### **Index Usage Monitoring**
```sql
-- Check index usage
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

### **Connection Pool Monitoring**
```javascript
// Monitor pool health
setInterval(() => {
  console.log('Pool status:', {
    totalCount: pool.totalCount,
    idleCount: pool.idleCount,
    waitingCount: pool.waitingCount
  });
}, 30000);
```

---

## 🔒 **Security Best Practices**

### **Environment Variables**
```bash
# .env file
DB_HOST=localhost
DB_PORT=5432
DB_NAME=aspargo_production
DB_USER=aspargo_app
DB_PASSWORD=secure_random_password_here
DB_SSL_MODE=require
```

### **Database Roles**
```sql
-- Production setup
CREATE ROLE aspargo_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO aspargo_readonly;

CREATE ROLE aspargo_analytics;
GRANT SELECT ON feature_analytics, api_usage_logs, user_analytics_summary TO aspargo_analytics;
```

### **Data Encryption**
```javascript
// Encrypt sensitive data before storage
const crypto = require('crypto');

function encryptSensitiveData(data) {
  const cipher = crypto.createCipher('aes-256-cbc', process.env.ENCRYPTION_KEY);
  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}
```

---

## 🧹 **Maintenance Procedures**

### **Daily Cleanup Task**
```sql
-- Create daily cleanup job
CREATE OR REPLACE FUNCTION daily_maintenance()
RETURNS void AS $$
BEGIN
  -- Clean expired photos
  DELETE FROM plant_photos WHERE auto_delete_at < CURRENT_TIMESTAMP;
  
  -- Update session durations
  UPDATE user_sessions 
  SET session_duration_seconds = EXTRACT(EPOCH FROM (ended_at - started_at))
  WHERE session_duration_seconds IS NULL AND ended_at IS NOT NULL;
  
  -- Clean old anonymous user data (30 days)
  DELETE FROM users 
  WHERE is_anonymous = true 
  AND created_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
  AND id NOT IN (
    SELECT DISTINCT user_id FROM user_sessions 
    WHERE last_activity_at > CURRENT_TIMESTAMP - INTERVAL '7 days'
  );
  
  RAISE NOTICE 'Daily maintenance completed at %', CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Schedule with cron (example for Linux)
-- 0 2 * * * psql -U aspargo_app -d aspargo_production -c "SELECT daily_maintenance();"
```

### **Backup Strategy**
```bash
#!/bin/bash
# backup_database.sh

DB_NAME="aspargo_production"
BACKUP_DIR="/backups/aspargo"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Full database backup
pg_dump -U aspargo_app -h localhost $DB_NAME | gzip > $BACKUP_DIR/aspargo_full_$DATE.sql.gz

# Schema-only backup
pg_dump -U aspargo_app -h localhost --schema-only $DB_NAME > $BACKUP_DIR/aspargo_schema_$DATE.sql

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -name "aspargo_*.gz" -mtime +30 -delete

echo "Backup completed: aspargo_full_$DATE.sql.gz"
```

---

## 📊 **Analytics Queries**

### **User Engagement Metrics**
```sql
-- Daily active users
SELECT 
  DATE(last_activity_at) as date,
  COUNT(DISTINCT user_id) as dau
FROM user_sessions
WHERE last_activity_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(last_activity_at)
ORDER BY date DESC;

-- Feature adoption rates
SELECT 
  feature_name,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(*) as total_events,
  ROUND(COUNT(DISTINCT user_id) * 100.0 / (SELECT COUNT(*) FROM users WHERE is_active = true), 2) as adoption_rate
FROM feature_analytics
WHERE event_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY feature_name
ORDER BY adoption_rate DESC;
```

### **Plant Diagnosis Analytics**
```sql
-- Most common plant identifications
SELECT 
  identified_plant_name,
  COUNT(*) as identification_count,
  AVG(plant_probability) as avg_confidence,
  COUNT(CASE WHEN is_healthy = false THEN 1 END) as unhealthy_count
FROM plant_diagnoses
WHERE request_timestamp >= CURRENT_DATE - INTERVAL '30 days'
  AND identified_plant_name IS NOT NULL
GROUP BY identified_plant_name
ORDER BY identification_count DESC
LIMIT 20;

-- Diagnosis success rates
SELECT 
  DATE(request_timestamp) as date,
  COUNT(*) as total_diagnoses,
  COUNT(CASE WHEN is_plant = true THEN 1 END) as plant_identified,
  ROUND(COUNT(CASE WHEN is_plant = true THEN 1 END) * 100.0 / COUNT(*), 2) as success_rate
FROM plant_diagnoses
WHERE request_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(request_timestamp)
ORDER BY date DESC;
```

### **Chat Analytics**
```sql
-- Chat engagement metrics
SELECT 
  DATE(started_at) as date,
  COUNT(*) as total_sessions,
  AVG(total_messages) as avg_messages_per_session,
  AVG(EXTRACT(EPOCH FROM (ended_at - started_at))) as avg_session_duration_seconds,
  AVG(user_satisfaction_rating) as avg_satisfaction
FROM chat_sessions
WHERE started_at >= CURRENT_DATE - INTERVAL '30 days'
  AND ended_at IS NOT NULL
GROUP BY DATE(started_at)
ORDER BY date DESC;
```

---

## 🚨 **Monitoring & Alerts**

### **Health Check Queries**
```sql
-- Database health check
SELECT 
  'users' as table_name,
  COUNT(*) as row_count,
  pg_size_pretty(pg_total_relation_size('users')) as table_size
UNION ALL
SELECT 
  'plant_diagnoses',
  COUNT(*),
  pg_size_pretty(pg_total_relation_size('plant_diagnoses'))
UNION ALL
SELECT 
  'chat_messages',
  COUNT(*),
  pg_size_pretty(pg_total_relation_size('chat_messages'));

-- Recent error summary
SELECT 
  error_type,
  COUNT(*) as error_count,
  MAX(occurred_at) as last_occurrence
FROM error_logs
WHERE occurred_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
  AND is_resolved = false
GROUP BY error_type
ORDER BY error_count DESC;
```

### **Performance Monitoring**
```javascript
// src/middleware/dbMonitoring.js
const { pool } = require('../config/database');

const monitorDatabasePerformance = async (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', async () => {
    const duration = Date.now() - start;
    
    if (duration > 1000) { // Log slow requests
      console.warn(`Slow database operation: ${req.method} ${req.path} took ${duration}ms`);
      
      // Log to database
      await pool.query(`
        INSERT INTO error_logs (
          error_type, error_level, error_message, feature_name, 
          request_data, app_version
        ) VALUES ($1, $2, $3, $4, $5, $6)
      `, [
        'slow_query', 'warning', 
        `Slow operation: ${duration}ms`, 
        req.path,
        JSON.stringify({ method: req.method, duration }),
        req.headers['app-version']
      ]);
    }
  });
  
  next();
};

module.exports = { monitorDatabasePerformance };
```

---

## 🎯 **Production Deployment Checklist**

### **Pre-Deployment**
- [ ] Database created with proper encoding (UTF8)
- [ ] All required extensions installed
- [ ] Schema applied successfully
- [ ] Test suite passes completely
- [ ] Indexes created and verified
- [ ] Backup strategy implemented
- [ ] Monitoring setup configured

### **Security Checklist**
- [ ] Database user has minimal required permissions
- [ ] SSL/TLS encryption enabled
- [ ] Environment variables secured
- [ ] Database access restricted by IP
- [ ] Regular security updates scheduled

### **Performance Checklist**
- [ ] Connection pooling configured
- [ ] Index usage monitored
- [ ] Query performance baselines established
- [ ] Maintenance procedures scheduled
- [ ] Cleanup functions automated

