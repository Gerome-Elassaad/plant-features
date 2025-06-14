-- =========================================================
-- 🌱 ASPARGO PLANT CARE APP - PRODUCTION DATABASE SCHEMA
-- =========================================================
-- Version: 1.0
-- Database: PostgreSQL 14+
-- Purpose: Plant Diagnosis & Virtual Cultivation Assistant
-- Features: Plant.id API integration + Google Gemini AI chat
-- =========================================================

-- Enable UUID extension for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================================
-- 1. USER MANAGEMENT TABLES
-- =========================================================

-- Users table - supports both anonymous and registered users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    username VARCHAR(100),
    password_hash VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_anonymous BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    profile_image_url TEXT,
    timezone VARCHAR(50) DEFAULT 'UTC',
    language_code VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    gdpr_consent BOOLEAN DEFAULT false,
    gdpr_consent_date TIMESTAMP WITH TIME ZONE,
    data_retention_days INTEGER DEFAULT 730, -- 2 years default
    -- Account status tracking
    account_status VARCHAR(20) DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'deleted')),
    deletion_requested_at TIMESTAMP WITH TIME ZONE,
    deletion_scheduled_at TIMESTAMP WITH TIME ZONE
);

-- User sessions for tracking app usage
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_id VARCHAR(255),
    device_type VARCHAR(50), -- 'ios', 'android', 'web'
    device_model VARCHAR(100),
    app_version VARCHAR(20),
    os_version VARCHAR(20),
    ip_address INET,
    user_agent TEXT,
    location_country VARCHAR(2), -- ISO country code
    location_city VARCHAR(100),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    session_duration_seconds INTEGER,
    is_active BOOLEAN DEFAULT true
);

-- User preferences and settings
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    theme_preference VARCHAR(20) DEFAULT 'system' CHECK (theme_preference IN ('light', 'dark', 'system')),
    notification_enabled BOOLEAN DEFAULT true,
    auto_save_photos BOOLEAN DEFAULT true,
    photo_quality VARCHAR(20) DEFAULT 'high' CHECK (photo_quality IN ('low', 'medium', 'high')),
    default_plant_language VARCHAR(10) DEFAULT 'en',
    measurement_unit VARCHAR(10) DEFAULT 'metric' CHECK (measurement_unit IN ('metric', 'imperial')),
    analytics_consent BOOLEAN DEFAULT true,
    marketing_consent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 2. PLANT DIAGNOSIS TABLES
-- =========================================================

-- Plant photos uploaded by users
CREATE TABLE plant_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES user_sessions(id),
    original_filename VARCHAR(255),
    file_path TEXT NOT NULL, -- Cloud storage path
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    image_width INTEGER,
    image_height INTEGER,
    compressed_file_path TEXT, -- Compressed version path
    compressed_size_bytes BIGINT,
    upload_source VARCHAR(20) CHECK (upload_source IN ('camera', 'gallery', 'web')),
    -- GPS and location data
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_accuracy_meters DECIMAL(8, 2),
    altitude_meters DECIMAL(8, 2),
    location_country VARCHAR(2),
    location_region VARCHAR(100),
    -- Metadata
    capture_timestamp TIMESTAMP WITH TIME ZONE,
    upload_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processing_status VARCHAR(20) DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed', 'deleted')),
    -- Privacy and retention
    is_public BOOLEAN DEFAULT false,
    auto_delete_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Plant diagnosis results from Plant.id API
CREATE TABLE plant_diagnoses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    photo_id UUID REFERENCES plant_photos(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Plant.id API request details
    plant_id_request_id VARCHAR(255), -- Plant.id's custom_id
    api_version VARCHAR(20),
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_timestamp TIMESTAMP WITH TIME ZONE,
    processing_time_ms INTEGER,
    
    -- Plant identification results
    is_plant BOOLEAN,
    is_plant_probability DECIMAL(5, 4), -- 0.0000 to 1.0000
    
    -- Primary plant identification
    identified_plant_name VARCHAR(255),
    scientific_name VARCHAR(255),
    common_names TEXT[], -- Array of common names
    plant_probability DECIMAL(5, 4),
    plant_id_confidence VARCHAR(20) CHECK (plant_id_confidence IN ('very_low', 'low', 'medium', 'high', 'very_high')),
    
    -- Health assessment
    is_healthy BOOLEAN,
    health_probability DECIMAL(5, 4),
    
    -- Disease detection
    diseases_detected TEXT[], -- Array of disease names
    primary_disease VARCHAR(255),
    disease_probability DECIMAL(5, 4),
    disease_severity VARCHAR(20) CHECK (disease_severity IN ('none', 'low', 'medium', 'high', 'critical')),
    
    -- Care recommendations
    care_instructions TEXT,
    treatment_suggestions TEXT,
    prevention_tips TEXT,
    
    -- Full API response (for debugging and future enhancements)
    raw_plant_id_response JSONB,
    
    -- Processing status
    diagnosis_status VARCHAR(20) DEFAULT 'completed' CHECK (diagnosis_status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Plant.id API suggestions (multiple results per diagnosis)
CREATE TABLE plant_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    diagnosis_id UUID REFERENCES plant_diagnoses(id) ON DELETE CASCADE,
    plant_id_suggestion_id INTEGER, -- Plant.id's internal ID
    
    plant_name VARCHAR(255) NOT NULL,
    scientific_name VARCHAR(255),
    common_names TEXT[],
    probability DECIMAL(5, 4),
    confidence_score DECIMAL(5, 4),
    
    -- Plant details from Plant.id
    plant_description TEXT,
    plant_family VARCHAR(100),
    plant_genus VARCHAR(100),
    plant_species VARCHAR(100),
    
    -- Additional metadata
    plant_url TEXT, -- Link to Plant.id plant page
    image_url TEXT, -- Reference image from Plant.id
    synonyms TEXT[],
    
    -- Plant care information
    care_difficulty VARCHAR(20) CHECK (care_difficulty IN ('very_easy', 'easy', 'medium', 'hard', 'very_hard')),
    light_requirements VARCHAR(50),
    water_requirements VARCHAR(50),
    soil_requirements VARCHAR(100),
    temperature_range VARCHAR(50),
    humidity_requirements VARCHAR(50),
    
    suggestion_rank INTEGER, -- Order of suggestion (1 = highest probability)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Disease suggestions (multiple diseases per diagnosis)
CREATE TABLE disease_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    diagnosis_id UUID REFERENCES plant_diagnoses(id) ON DELETE CASCADE,
    
    disease_name VARCHAR(255) NOT NULL,
    disease_type VARCHAR(100), -- 'fungal', 'bacterial', 'viral', 'pest', 'nutritional', etc.
    probability DECIMAL(5, 4),
    severity VARCHAR(20) CHECK (severity IN ('none', 'low', 'medium', 'high', 'critical')),
    
    -- Treatment information
    treatment_urgency VARCHAR(20) CHECK (treatment_urgency IN ('none', 'low', 'medium', 'high', 'immediate')),
    treatment_description TEXT,
    prevention_methods TEXT,
    
    -- Additional metadata
    disease_description TEXT,
    symptoms TEXT,
    causes TEXT,
    affected_plant_parts TEXT[],
    
    suggestion_rank INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 3. VIRTUAL ASSISTANT CHAT TABLES
-- =========================================================

-- Chat conversations/sessions
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    user_session_id UUID REFERENCES user_sessions(id),
    
    session_title VARCHAR(255), -- Auto-generated or user-defined
    session_language VARCHAR(10) DEFAULT 'en',
    
    -- Session metadata
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    session_duration_seconds INTEGER,
    
    -- Statistics
    total_messages INTEGER DEFAULT 0,
    user_messages_count INTEGER DEFAULT 0,
    assistant_messages_count INTEGER DEFAULT 0,
    
    -- Session context
    context_plant_names TEXT[], -- Plants discussed in this session
    context_topics TEXT[], -- Topics/keywords from conversation
    session_mood VARCHAR(20), -- 'helpful', 'frustrated', 'satisfied', etc.
    
    -- Quality metrics
    user_satisfaction_rating INTEGER CHECK (user_satisfaction_rating BETWEEN 1 AND 5),
    feedback_text TEXT,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Individual chat messages
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Message content
    message_content TEXT NOT NULL,
    message_role VARCHAR(20) NOT NULL CHECK (message_role IN ('user', 'assistant', 'system')),
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'error', 'suggestion')),
    
    -- Timing
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    response_time_ms INTEGER,
    
    -- AI processing details (for assistant messages)
    gemini_request_id VARCHAR(255),
    gemini_model_version VARCHAR(50),
    tokens_used INTEGER,
    processing_cost_usd DECIMAL(10, 6),
    
    -- Message context
    context_messages_count INTEGER, -- How many previous messages included as context
    conversation_context JSONB, -- Previous messages sent to Gemini
    
    -- Content analysis
    detected_intent VARCHAR(100), -- 'plant_care', 'disease_diagnosis', 'general_info', etc.
    mentioned_plants TEXT[],
    mentioned_topics TEXT[],
    confidence_score DECIMAL(5, 4),
    
    -- Quality and feedback
    is_helpful BOOLEAN,
    user_reaction VARCHAR(20), -- 'like', 'dislike', 'love', 'neutral'
    
    -- Full API response for debugging
    raw_gemini_response JSONB,
    
    -- Error handling
    is_error BOOLEAN DEFAULT false,
    error_type VARCHAR(50),
    error_message TEXT,
    
    -- Message ordering
    message_sequence INTEGER, -- Order within session
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Suggested conversation starters and responses
CREATE TABLE chat_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    language_code VARCHAR(10) DEFAULT 'en',
    category VARCHAR(50), -- 'starter', 'follow_up', 'plant_care', 'disease', etc.
    suggestion_text TEXT NOT NULL,
    display_order INTEGER,
    usage_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 4. ANALYTICS AND LOGGING TABLES
-- =========================================================

-- API usage tracking for external services
CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    
    -- API details
    api_service VARCHAR(50) NOT NULL, -- 'plant_id', 'gemini', 'internal'
    api_endpoint VARCHAR(255),
    api_method VARCHAR(10),
    api_version VARCHAR(20),
    
    -- Request details
    request_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    response_timestamp TIMESTAMP WITH TIME ZONE,
    response_time_ms INTEGER,
    
    -- Status and results
    http_status_code INTEGER,
    success BOOLEAN,
    error_type VARCHAR(100),
    error_message TEXT,
    
    -- Usage metrics
    tokens_used INTEGER,
    data_transferred_bytes BIGINT,
    cost_usd DECIMAL(10, 6),
    
    -- Request metadata
    request_size_bytes INTEGER,
    response_size_bytes INTEGER,
    user_agent TEXT,
    ip_address INET,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Feature usage analytics
CREATE TABLE feature_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    
    -- Feature tracking
    feature_name VARCHAR(100) NOT NULL, -- 'plant_diagnosis', 'chat_assistant', 'photo_upload', etc.
    action_type VARCHAR(100) NOT NULL, -- 'view', 'click', 'upload', 'submit', 'share', etc.
    feature_screen VARCHAR(100), -- 'diagnosis_screen', 'chat_screen', 'home_screen', etc.
    
    -- Event details
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    event_duration_ms INTEGER,
    
    -- Context
    event_context JSONB, -- Additional metadata about the event
    previous_screen VARCHAR(100),
    next_screen VARCHAR(100),
    
    -- Device context
    device_type VARCHAR(50),
    app_version VARCHAR(20),
    os_version VARCHAR(20),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Error tracking and monitoring
CREATE TABLE error_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    
    -- Error details
    error_type VARCHAR(100) NOT NULL, -- 'api_error', 'validation_error', 'system_error', etc.
    error_level VARCHAR(20) DEFAULT 'error' CHECK (error_level IN ('debug', 'info', 'warning', 'error', 'critical')),
    error_message TEXT NOT NULL,
    error_code VARCHAR(50),
    
    -- Context
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    feature_name VARCHAR(100),
    screen_name VARCHAR(100),
    user_action VARCHAR(100),
    
    -- Technical details
    stack_trace TEXT,
    request_data JSONB,
    response_data JSONB,
    
    -- Environment
    app_version VARCHAR(20),
    device_type VARCHAR(50),
    os_version VARCHAR(20),
    
    -- Resolution
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User feedback and ratings
CREATE TABLE user_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES user_sessions(id),
    
    -- Feedback details
    feedback_type VARCHAR(50) NOT NULL, -- 'bug_report', 'feature_request', 'general', 'rating'
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    feedback_title VARCHAR(255),
    feedback_content TEXT,
    
    -- Context
    feature_name VARCHAR(100), -- Which feature the feedback is about
    screen_name VARCHAR(100),
    
    -- Submission details
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    contact_email VARCHAR(255),
    allow_contact BOOLEAN DEFAULT false,
    
    -- Internal tracking
    status VARCHAR(50) DEFAULT 'new' CHECK (status IN ('new', 'reviewing', 'in_progress', 'resolved', 'closed')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    assigned_to VARCHAR(100),
    
    -- Resolution
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 5. INDEXES FOR PERFORMANCE OPTIMIZATION
-- =========================================================

-- User-related indexes
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_login ON users(last_login_at);
CREATE INDEX idx_users_is_anonymous ON users(is_anonymous);
CREATE INDEX idx_users_active_status ON users(is_active, account_status);

-- Session indexes
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active, last_activity_at);
CREATE INDEX idx_user_sessions_device ON user_sessions(device_type, device_id);
CREATE INDEX idx_user_sessions_timerange ON user_sessions(started_at, ended_at);

-- Plant photo indexes
CREATE INDEX idx_plant_photos_user_id ON plant_photos(user_id);
CREATE INDEX idx_plant_photos_upload_timestamp ON plant_photos(upload_timestamp);
CREATE INDEX idx_plant_photos_processing_status ON plant_photos(processing_status);
CREATE INDEX idx_plant_photos_location ON plant_photos(latitude, longitude) WHERE latitude IS NOT NULL;
CREATE INDEX idx_plant_photos_auto_delete ON plant_photos(auto_delete_at) WHERE auto_delete_at IS NOT NULL;

-- Diagnosis indexes
CREATE INDEX idx_plant_diagnoses_photo_id ON plant_diagnoses(photo_id);
CREATE INDEX idx_plant_diagnoses_user_id ON plant_diagnoses(user_id);
CREATE INDEX idx_plant_diagnoses_timestamp ON plant_diagnoses(request_timestamp);
CREATE INDEX idx_plant_diagnoses_plant_name ON plant_diagnoses(identified_plant_name);
CREATE INDEX idx_plant_diagnoses_confidence ON plant_diagnoses(plant_probability);
CREATE INDEX idx_plant_diagnoses_health ON plant_diagnoses(is_healthy, health_probability);

-- Plant suggestion indexes
CREATE INDEX idx_plant_suggestions_diagnosis_id ON plant_suggestions(diagnosis_id);
CREATE INDEX idx_plant_suggestions_probability ON plant_suggestions(probability DESC);
CREATE INDEX idx_plant_suggestions_rank ON plant_suggestions(diagnosis_id, suggestion_rank);

-- Chat session indexes
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_active ON chat_sessions(is_active, last_message_at);
CREATE INDEX idx_chat_sessions_language ON chat_sessions(session_language);
CREATE INDEX idx_chat_sessions_timerange ON chat_sessions(started_at, ended_at);

-- Chat message indexes
CREATE INDEX idx_chat_messages_session_id ON chat_messages(chat_session_id);
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_timestamp ON chat_messages(sent_at);
CREATE INDEX idx_chat_messages_role ON chat_messages(message_role);
CREATE INDEX idx_chat_messages_sequence ON chat_messages(chat_session_id, message_sequence);
CREATE INDEX idx_chat_messages_intent ON chat_messages(detected_intent);

-- Analytics indexes
CREATE INDEX idx_api_usage_logs_timestamp ON api_usage_logs(request_timestamp);
CREATE INDEX idx_api_usage_logs_service ON api_usage_logs(api_service, api_endpoint);
CREATE INDEX idx_api_usage_logs_user_id ON api_usage_logs(user_id);
CREATE INDEX idx_api_usage_logs_success ON api_usage_logs(success, http_status_code);

CREATE INDEX idx_feature_analytics_timestamp ON feature_analytics(event_timestamp);
CREATE INDEX idx_feature_analytics_feature ON feature_analytics(feature_name, action_type);
CREATE INDEX idx_feature_analytics_user_id ON feature_analytics(user_id);

CREATE INDEX idx_error_logs_timestamp ON error_logs(occurred_at);
CREATE INDEX idx_error_logs_type ON error_logs(error_type, error_level);
CREATE INDEX idx_error_logs_resolved ON error_logs(is_resolved, resolved_at);

-- =========================================================
-- 6. TRIGGERS FOR AUTOMATIC UPDATES
-- =========================================================

-- Function to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_sessions_updated_at BEFORE UPDATE ON chat_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_feedback_updated_at BEFORE UPDATE ON user_feedback
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update session activity
CREATE OR REPLACE FUNCTION update_session_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE user_sessions 
    SET last_activity_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.user_session_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Update session activity when new records are created
CREATE TRIGGER update_session_on_photo_upload
    AFTER INSERT ON plant_photos
    FOR EACH ROW EXECUTE FUNCTION update_session_activity();

CREATE TRIGGER update_session_on_chat_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_session_activity();

-- Function to update chat session statistics
CREATE OR REPLACE FUNCTION update_chat_session_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chat_sessions SET
        total_messages = (
            SELECT COUNT(*) FROM chat_messages 
            WHERE chat_session_id = NEW.chat_session_id
        ),
        user_messages_count = (
            SELECT COUNT(*) FROM chat_messages 
            WHERE chat_session_id = NEW.chat_session_id AND message_role = 'user'
        ),
        assistant_messages_count = (
            SELECT COUNT(*) FROM chat_messages 
            WHERE chat_session_id = NEW.chat_session_id AND message_role = 'assistant'
        ),
        last_message_at = NEW.sent_at
    WHERE id = NEW.chat_session_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_chat_session_stats_trigger
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_session_stats();

-- =========================================================
-- 7. DATA RETENTION AND CLEANUP PROCEDURES
-- =========================================================

-- Function to clean up expired data based on retention policies
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- Delete expired photos
    DELETE FROM plant_photos 
    WHERE auto_delete_at IS NOT NULL AND auto_delete_at < CURRENT_TIMESTAMP;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Delete old anonymous user sessions (older than 30 days)
    DELETE FROM user_sessions 
    WHERE started_at < CURRENT_TIMESTAMP - INTERVAL '30 days'
    AND user_id IN (SELECT id FROM users WHERE is_anonymous = true);
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Delete old API logs (older than 90 days)
    DELETE FROM api_usage_logs 
    WHERE request_timestamp < CURRENT_TIMESTAMP - INTERVAL '90 days';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Delete old analytics data (older than 1 year)
    DELETE FROM feature_analytics 
    WHERE event_timestamp < CURRENT_TIMESTAMP - INTERVAL '1 year';
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- Delete resolved error logs (older than 6 months)
    DELETE FROM error_logs 
    WHERE occurred_at < CURRENT_TIMESTAMP - INTERVAL '6 months'
    AND is_resolved = true;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- 8. VIEWS FOR COMMON QUERIES
-- =========================================================

-- User analytics summary view
CREATE VIEW user_analytics_summary AS
SELECT 
    u.id as user_id,
    u.is_anonymous,
    u.created_at as user_created_at,
    u.last_login_at,
    COUNT(DISTINCT pp.id) as total_photos_uploaded,
    COUNT(DISTINCT pd.id) as total_diagnoses_completed,
    COUNT(DISTINCT cs.id) as total_chat_sessions,
    COUNT(DISTINCT cm.id) as total_chat_messages,
    COUNT(DISTINCT us.id) as total_sessions,
    MAX(us.last_activity_at) as last_activity,
    AVG(cs.user_satisfaction_rating) as avg_chat_satisfaction,
    SUM(COALESCE(us.session_duration_seconds, 0)) as total_time_spent_seconds
FROM users u
LEFT JOIN plant_photos pp ON u.id = pp.user_id
LEFT JOIN plant_diagnoses pd ON u.id = pd.user_id
LEFT JOIN chat_sessions cs ON u.id = cs.user_id
LEFT JOIN chat_messages cm ON u.id = cm.user_id
LEFT JOIN user_sessions us ON u.id = us.user_id
GROUP BY u.id, u.is_anonymous, u.created_at, u.last_login_at;

-- Daily application metrics view
CREATE VIEW daily_app_metrics AS
SELECT 
    DATE(created_at) as metric_date,
    COUNT(DISTINCT CASE WHEN is_anonymous = false THEN id END) as new_registered_users,
    COUNT(DISTINCT CASE WHEN is_anonymous = true THEN id END) as new_anonymous_users,
    COUNT(DISTINCT id) as total_new_users
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY metric_date DESC;

-- Feature usage summary view
CREATE VIEW feature_usage_summary AS
SELECT 
    DATE(event_timestamp) as usage_date,
    feature_name,
    action_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT session_id) as unique_sessions
FROM feature_analytics
WHERE event_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(event_timestamp), feature_name, action_type
ORDER BY usage_date DESC, event_count DESC;

-- =========================================================
-- 9. INITIAL DATA SEEDING
-- =========================================================

-- Insert default chat suggestions
INSERT INTO chat_suggestions (language_code, category, suggestion_text, display_order) VALUES
('en', 'starter', 'How do I care for succulents?', 1),
('en', 'starter', 'Why are my plant leaves turning yellow?', 2),
('en', 'starter', 'What plants work well in low light?', 3),
('en', 'starter', 'How often should I water my houseplants?', 4),
('en', 'starter', 'What are the signs of overwatering?', 5),
('en', 'plant_care', 'Tell me about fertilizing schedules', 6),
('en', 'plant_care', 'How do I repot my plant?', 7),
('en', 'plant_care', 'What soil is best for indoor plants?', 8),
('en', 'disease', 'My plant has brown spots on leaves', 9),
('en', 'disease', 'How do I treat fungal infections?', 10);

-- Insert Spanish suggestions
INSERT INTO chat_suggestions (language_code, category, suggestion_text, display_order) VALUES
('es', 'starter', '¿Cómo cuido las suculentas?', 1),
('es', 'starter', '¿Por qué las hojas de mi planta se vuelven amarillas?', 2),
('es', 'starter', '¿Qué plantas funcionan bien con poca luz?', 3),
('es', 'starter', '¿Con qué frecuencia debo regar mis plantas de interior?', 4),
('es', 'plant_care', '¿Cómo trasplanto mi planta?', 5),
('es', 'disease', 'Mi planta tiene manchas marrones en las hojas', 6);

-- =========================================================
-- 10. SECURITY AND PERMISSIONS
-- =========================================================

-- Create application roles
CREATE ROLE aspargo_app_read;
CREATE ROLE aspargo_app_write;
CREATE ROLE aspargo_analytics_read;

-- Grant read permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO aspargo_app_read;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO aspargo_analytics_read;

-- Grant write permissions for app operations
GRANT SELECT, INSERT, UPDATE ON users, user_sessions, user_preferences TO aspargo_app_write;
GRANT SELECT, INSERT, UPDATE ON plant_photos, plant_diagnoses, plant_suggestions, disease_suggestions TO aspargo_app_write;
GRANT SELECT, INSERT, UPDATE ON chat_sessions, chat_messages TO aspargo_app_write;
GRANT SELECT, INSERT ON api_usage_logs, feature_analytics, error_logs, user_feedback TO aspargo_app_write;
GRANT SELECT ON chat_suggestions TO aspargo_app_write;

-- Grant sequence usage
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO aspargo_app_write;

-- =========================================================
-- 11. COMMENTS FOR DOCUMENTATION
-- =========================================================

COMMENT ON TABLE users IS 'Central user management supporting both anonymous and registered users with GDPR compliance';
COMMENT ON TABLE user_sessions IS 'Track user app sessions for analytics and activity monitoring';
COMMENT ON TABLE user_preferences IS 'User-specific app settings and preferences';

COMMENT ON TABLE plant_photos IS 'Store metadata and references to uploaded plant images';
COMMENT ON TABLE plant_diagnoses IS 'Results from Plant.id API analysis of plant photos';
COMMENT ON TABLE plant_suggestions IS 'Multiple plant identification suggestions from Plant.id API';
COMMENT ON TABLE disease_suggestions IS 'Disease detection results and treatment recommendations';

COMMENT ON TABLE chat_sessions IS 'Group related chat messages into conversation sessions';
COMMENT ON TABLE chat_messages IS 'Individual messages between users and the AI assistant';
COMMENT ON TABLE chat_suggestions IS 'Predefined conversation starters and suggestions';

COMMENT ON TABLE api_usage_logs IS 'Track external API usage for monitoring and cost analysis';
COMMENT ON TABLE feature_analytics IS 'Detailed user interaction analytics for product insights';
COMMENT ON TABLE error_logs IS 'Centralized error tracking and monitoring';
COMMENT ON TABLE user_feedback IS 'User feedback, ratings, and feature requests';

-- =========================================================
-- END OF SCHEMA CREATION
-- =========================================================

-- Display creation summary
DO $$
DECLARE
    table_count INTEGER;
    index_count INTEGER;
    trigger_count INTEGER;
    view_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    SELECT COUNT(*) INTO index_count FROM pg_indexes WHERE schemaname = 'public';
    SELECT COUNT(*) INTO trigger_count FROM information_schema.triggers WHERE trigger_schema = 'public';
    SELECT COUNT(*) INTO view_count FROM information_schema.views WHERE table_schema = 'public';
    
    RAISE NOTICE '🌱 Aspargo Database Schema Created Successfully!';
    RAISE NOTICE '📊 Statistics:';
    RAISE NOTICE '   Tables: %', table_count;
    RAISE NOTICE '   Indexes: %', index_count;
    RAISE NOTICE '   Triggers: %', trigger_count;
    RAISE NOTICE '   Views: %', view_count;
    RAISE NOTICE '🚀 Database is ready for production use!';
END $$;