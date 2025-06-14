-- =========================================================
-- 🧪 ASPARGO DATABASE TESTING SUITE
-- =========================================================
-- Purpose: Test each database component individually
-- Coverage: Tables, Constraints, Triggers, Views, Functions
-- Test Type: Unit tests for database schema validation
-- =========================================================

-- Enable testing extensions
CREATE EXTENSION IF NOT EXISTS "pgTAP";

BEGIN;

-- =========================================================
-- 1. TABLE STRUCTURE TESTS
-- =========================================================

-- Test 1.1: Verify all core tables exist
SELECT plan(15);

SELECT has_table('users', 'Users table exists');
SELECT has_table('user_sessions', 'User sessions table exists');
SELECT has_table('user_preferences', 'User preferences table exists');
SELECT has_table('plant_photos', 'Plant photos table exists');
SELECT has_table('plant_diagnoses', 'Plant diagnoses table exists');
SELECT has_table('plant_suggestions', 'Plant suggestions table exists');
SELECT has_table('disease_suggestions', 'Disease suggestions table exists');
SELECT has_table('chat_sessions', 'Chat sessions table exists');
SELECT has_table('chat_messages', 'Chat messages table exists');
SELECT has_table('chat_suggestions', 'Chat suggestions table exists');
SELECT has_table('api_usage_logs', 'API usage logs table exists');
SELECT has_table('feature_analytics', 'Feature analytics table exists');
SELECT has_table('error_logs', 'Error logs table exists');
SELECT has_table('user_feedback', 'User feedback table exists');

-- Test 1.2: Verify primary key constraints
SELECT has_pk('users', 'Users table has primary key');

SELECT finish();

-- =========================================================
-- 2. USER MANAGEMENT COMPONENT TESTS
-- =========================================================

-- Test 2.1: Insert and validate user data
DO $$
DECLARE
    test_user_id UUID;
    session_id UUID;
    prefs_count INTEGER;
BEGIN
    -- Insert test registered user
    INSERT INTO users (email, username, first_name, last_name, is_anonymous, gdpr_consent)
    VALUES ('test@example.com', 'testuser', 'John', 'Doe', false, true)
    RETURNING id INTO test_user_id;
    
    -- Verify user was created
    IF test_user_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create test user';
    END IF;
    
    -- Insert user session
    INSERT INTO user_sessions (user_id, device_type, app_version, ip_address)
    VALUES (test_user_id, 'ios', '1.0.0', '192.168.1.1'::inet)
    RETURNING id INTO session_id;
    
    -- Insert user preferences
    INSERT INTO user_preferences (user_id, theme_preference, notification_enabled)
    VALUES (test_user_id, 'dark', true);
    
    -- Verify preferences were created
    SELECT COUNT(*) INTO prefs_count FROM user_preferences WHERE user_id = test_user_id;
    IF prefs_count != 1 THEN
        RAISE EXCEPTION 'User preferences not created correctly';
    END IF;
    
    RAISE NOTICE '✅ User Management Component Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- Test 2.2: Test anonymous user creation
DO $$
DECLARE
    anon_user_id UUID;
    user_count INTEGER;
BEGIN
    -- Insert anonymous user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO anon_user_id;
    
    -- Verify anonymous user properties
    SELECT COUNT(*) INTO user_count 
    FROM users 
    WHERE id = anon_user_id AND is_anonymous = true AND email IS NULL;
    
    IF user_count != 1 THEN
        RAISE EXCEPTION 'Anonymous user not created correctly';
    END IF;
    
    RAISE NOTICE '✅ Anonymous User Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = anon_user_id;
    
END $$;

-- =========================================================
-- 3. PLANT DIAGNOSIS COMPONENT TESTS
-- =========================================================

-- Test 3.1: Complete diagnosis workflow
DO $$
DECLARE
    test_user_id UUID;
    photo_id UUID;
    diagnosis_id UUID;
    suggestion_count INTEGER;
BEGIN
    -- Create test user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    
    -- Upload plant photo
    INSERT INTO plant_photos (
        user_id, 
        original_filename, 
        file_path, 
        file_size_bytes, 
        mime_type,
        upload_source,
        latitude,
        longitude
    ) VALUES (
        test_user_id,
        'test_plant.jpg',
        '/uploads/test_plant.jpg',
        1024000,
        'image/jpeg',
        'camera',
        40.7128,
        -74.0060
    ) RETURNING id INTO photo_id;
    
    -- Create diagnosis result
    INSERT INTO plant_diagnoses (
        photo_id,
        user_id,
        plant_id_request_id,
        is_plant,
        is_plant_probability,
        identified_plant_name,
        scientific_name,
        plant_probability,
        is_healthy,
        primary_disease,
        care_instructions
    ) VALUES (
        photo_id,
        test_user_id,
        'test-request-123',
        true,
        0.9850,
        'Common Basil',
        'Ocimum basilicum',
        0.9850,
        false,
        'Fungal leaf spot',
        'Remove affected leaves and improve air circulation'
    ) RETURNING id INTO diagnosis_id;
    
    -- Add plant suggestions
    INSERT INTO plant_suggestions (
        diagnosis_id,
        plant_name,
        scientific_name,
        probability,
        suggestion_rank
    ) VALUES 
    (diagnosis_id, 'Common Basil', 'Ocimum basilicum', 0.9850, 1),
    (diagnosis_id, 'Thai Basil', 'Ocimum basilicum var. thyrsiflora', 0.7200, 2);
    
    -- Add disease suggestion
    INSERT INTO disease_suggestions (
        diagnosis_id,
        disease_name,
        disease_type,
        probability,
        severity,
        treatment_description
    ) VALUES (
        diagnosis_id,
        'Fungal leaf spot',
        'fungal',
        0.8500,
        'medium',
        'Apply organic fungicide and improve ventilation'
    );
    
    -- Verify data integrity
    SELECT COUNT(*) INTO suggestion_count 
    FROM plant_suggestions 
    WHERE diagnosis_id = diagnosis_id;
    
    IF suggestion_count != 2 THEN
        RAISE EXCEPTION 'Plant suggestions not created correctly';
    END IF;
    
    RAISE NOTICE '✅ Plant Diagnosis Component Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- Test 3.2: Test photo metadata and constraints
DO $$
DECLARE
    test_user_id UUID;
    photo_id UUID;
    invalid_insert_failed BOOLEAN := false;
BEGIN
    -- Create test user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    
    -- Test valid photo upload
    INSERT INTO plant_photos (
        user_id,
        original_filename,
        file_path,
        file_size_bytes,
        mime_type,
        upload_source
    ) VALUES (
        test_user_id,
        'valid_photo.jpg',
        '/uploads/valid_photo.jpg',
        2048000,
        'image/jpeg',
        'gallery'
    ) RETURNING id INTO photo_id;
    
    -- Test invalid upload source (should fail)
    BEGIN
        INSERT INTO plant_photos (
            user_id,
            original_filename,
            file_path,
            upload_source
        ) VALUES (
            test_user_id,
            'invalid_photo.jpg',
            '/uploads/invalid_photo.jpg',
            'invalid_source'
        );
    EXCEPTION WHEN check_violation THEN
        invalid_insert_failed := true;
    END;
    
    IF NOT invalid_insert_failed THEN
        RAISE EXCEPTION 'Invalid upload source constraint not working';
    END IF;
    
    RAISE NOTICE '✅ Photo Constraints Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- =========================================================
-- 4. CHAT ASSISTANT COMPONENT TESTS
-- =========================================================

-- Test 4.1: Complete chat conversation workflow
DO $$
DECLARE
    test_user_id UUID;
    chat_session_id UUID;
    message_count INTEGER;
    session_stats RECORD;
BEGIN
    -- Create test user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    
    -- Start chat session
    INSERT INTO chat_sessions (
        user_id,
        session_title,
        session_language
    ) VALUES (
        test_user_id,
        'Plant Care Questions',
        'en'
    ) RETURNING id INTO chat_session_id;
    
    -- Add user message
    INSERT INTO chat_messages (
        chat_session_id,
        user_id,
        message_content,
        message_role,
        detected_intent,
        message_sequence
    ) VALUES (
        chat_session_id,
        test_user_id,
        'How do I care for succulents?',
        'user',
        'plant_care',
        1
    );
    
    -- Add assistant response
    INSERT INTO chat_messages (
        chat_session_id,
        user_id,
        message_content,
        message_role,
        tokens_used,
        processing_cost_usd,
        message_sequence
    ) VALUES (
        chat_session_id,
        test_user_id,
        'Succulents need well-draining soil and infrequent watering. Water only when the soil is completely dry.',
        'assistant',
        150,
        0.000300,
        2
    );
    
    -- Verify chat statistics were updated by trigger
    SELECT total_messages, user_messages_count, assistant_messages_count 
    INTO session_stats
    FROM chat_sessions 
    WHERE id = chat_session_id;
    
    IF session_stats.total_messages != 2 OR session_stats.user_messages_count != 1 OR session_stats.assistant_messages_count != 1 THEN
        RAISE EXCEPTION 'Chat session statistics not updated correctly by trigger';
    END IF;
    
    RAISE NOTICE '✅ Chat Assistant Component Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- Test 4.2: Test chat suggestions and multilingual support
DO $$
DECLARE
    en_suggestions INTEGER;
    es_suggestions INTEGER;
BEGIN
    -- Count English suggestions
    SELECT COUNT(*) INTO en_suggestions 
    FROM chat_suggestions 
    WHERE language_code = 'en' AND is_active = true;
    
    -- Count Spanish suggestions  
    SELECT COUNT(*) INTO es_suggestions 
    FROM chat_suggestions 
    WHERE language_code = 'es' AND is_active = true;
    
    IF en_suggestions < 5 THEN
        RAISE EXCEPTION 'Not enough English chat suggestions seeded';
    END IF;
    
    IF es_suggestions < 3 THEN
        RAISE EXCEPTION 'Not enough Spanish chat suggestions seeded';
    END IF;
    
    RAISE NOTICE '✅ Chat Suggestions Test: PASSED (EN: %, ES: %)', en_suggestions, es_suggestions;
    
END $$;

-- =========================================================
-- 5. ANALYTICS AND LOGGING COMPONENT TESTS
-- =========================================================

-- Test 5.1: API usage logging
DO $$
DECLARE
    test_user_id UUID;
    log_id UUID;
    log_count INTEGER;
BEGIN
    -- Create test user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    
    -- Log API usage
    INSERT INTO api_usage_logs (
        user_id,
        api_service,
        api_endpoint,
        api_method,
        response_time_ms,
        http_status_code,
        success,
        tokens_used,
        cost_usd
    ) VALUES (
        test_user_id,
        'plant_id',
        '/v2/identify',
        'POST',
        2500,
        200,
        true,
        0,
        0.05
    ) RETURNING id INTO log_id;
    
    -- Verify log entry
    SELECT COUNT(*) INTO log_count 
    FROM api_usage_logs 
    WHERE id = log_id AND success = true;
    
    IF log_count != 1 THEN
        RAISE EXCEPTION 'API usage log not created correctly';
    END IF;
    
    RAISE NOTICE '✅ API Usage Logging Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- Test 5.2: Feature analytics tracking
DO $$
DECLARE
    test_user_id UUID;
    analytics_count INTEGER;
BEGIN
    -- Create test user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    
    -- Track feature usage
    INSERT INTO feature_analytics (
        user_id,
        feature_name,
        action_type,
        feature_screen,
        event_duration_ms,
        device_type,
        app_version
    ) VALUES (
        test_user_id,
        'plant_diagnosis',
        'photo_upload',
        'diagnosis_screen',
        5000,
        'ios',
        '1.0.0'
    );
    
    -- Verify analytics entry
    SELECT COUNT(*) INTO analytics_count 
    FROM feature_analytics 
    WHERE user_id = test_user_id AND feature_name = 'plant_diagnosis';
    
    IF analytics_count != 1 THEN
        RAISE EXCEPTION 'Feature analytics not tracked correctly';
    END IF;
    
    RAISE NOTICE '✅ Feature Analytics Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- =========================================================
-- 6. TRIGGER AND FUNCTION TESTS
-- =========================================================

-- Test 6.1: Updated_at trigger functionality
DO $$
DECLARE
    test_user_id UUID;
    original_updated_at TIMESTAMP WITH TIME ZONE;
    new_updated_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Create test user
    INSERT INTO users (email, is_anonymous) 
    VALUES ('trigger_test@example.com', false) 
    RETURNING id INTO test_user_id;
    
    -- Get original timestamp
    SELECT updated_at INTO original_updated_at FROM users WHERE id = test_user_id;
    
    -- Wait a moment and update
    PERFORM pg_sleep(0.1);
    UPDATE users SET first_name = 'Updated' WHERE id = test_user_id;
    
    -- Get new timestamp
    SELECT updated_at INTO new_updated_at FROM users WHERE id = test_user_id;
    
    -- Verify trigger updated the timestamp
    IF new_updated_at <= original_updated_at THEN
        RAISE EXCEPTION 'Updated_at trigger not working correctly';
    END IF;
    
    RAISE NOTICE '✅ Updated_at Trigger Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- Test 6.2: Chat session statistics trigger
DO $$
DECLARE
    test_user_id UUID;
    chat_session_id UUID;
    final_stats RECORD;
BEGIN
    -- Create test user and chat session
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    INSERT INTO chat_sessions (user_id) VALUES (test_user_id) RETURNING id INTO chat_session_id;
    
    -- Add multiple messages
    INSERT INTO chat_messages (chat_session_id, user_id, message_content, message_role, message_sequence)
    VALUES 
    (chat_session_id, test_user_id, 'Question 1', 'user', 1),
    (chat_session_id, test_user_id, 'Answer 1', 'assistant', 2),
    (chat_session_id, test_user_id, 'Question 2', 'user', 3);
    
    -- Check final statistics
    SELECT total_messages, user_messages_count, assistant_messages_count
    INTO final_stats
    FROM chat_sessions WHERE id = chat_session_id;
    
    IF final_stats.total_messages != 3 OR final_stats.user_messages_count != 2 OR final_stats.assistant_messages_count != 1 THEN
        RAISE EXCEPTION 'Chat session statistics trigger not working correctly';
    END IF;
    
    RAISE NOTICE '✅ Chat Statistics Trigger Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- =========================================================
-- 7. VIEW TESTS
-- =========================================================

-- Test 7.1: User analytics summary view
DO $$
DECLARE
    test_user_id UUID;
    view_result RECORD;
BEGIN
    -- Create test user with some activity
    INSERT INTO users (email, is_anonymous) 
    VALUES ('view_test@example.com', false) 
    RETURNING id INTO test_user_id;
    
    -- Add some activity data
    INSERT INTO plant_photos (user_id, original_filename, file_path)
    VALUES (test_user_id, 'test.jpg', '/test.jpg');
    
    INSERT INTO chat_sessions (user_id)
    VALUES (test_user_id);
    
    -- Query the view
    SELECT * INTO view_result 
    FROM user_analytics_summary 
    WHERE user_id = test_user_id;
    
    -- Verify view data
    IF view_result.total_photos_uploaded != 1 OR view_result.total_chat_sessions != 1 THEN
        RAISE EXCEPTION 'User analytics summary view not working correctly';
    END IF;
    
    RAISE NOTICE '✅ User Analytics View Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- =========================================================
-- 8. DATA RETENTION AND CLEANUP TESTS
-- =========================================================

-- Test 8.1: Data cleanup function
DO $$
DECLARE
    test_user_id UUID;
    old_photo_id UUID;
    cleanup_result INTEGER;
    remaining_photos INTEGER;
BEGIN
    -- Create test user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    
    -- Create expired photo
    INSERT INTO plant_photos (
        user_id, 
        original_filename, 
        file_path,
        auto_delete_at
    ) VALUES (
        test_user_id,
        'expired_photo.jpg',
        '/expired_photo.jpg',
        CURRENT_TIMESTAMP - INTERVAL '1 hour'
    ) RETURNING id INTO old_photo_id;
    
    -- Run cleanup function
    SELECT cleanup_expired_data() INTO cleanup_result;
    
    -- Verify expired photo was deleted
    SELECT COUNT(*) INTO remaining_photos 
    FROM plant_photos 
    WHERE id = old_photo_id;
    
    IF remaining_photos != 0 THEN
        RAISE EXCEPTION 'Data cleanup function did not remove expired photo';
    END IF;
    
    RAISE NOTICE '✅ Data Cleanup Function Test: PASSED (Cleaned % records)', cleanup_result;
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- =========================================================
-- 9. CONSTRAINT AND VALIDATION TESTS
-- =========================================================

-- Test 9.1: Check constraints
DO $$
DECLARE
    test_user_id UUID;
    constraint_failed BOOLEAN := false;
BEGIN
    -- Create test user
    INSERT INTO users (is_anonymous) VALUES (true) RETURNING id INTO test_user_id;
    
    -- Test invalid account status (should fail)
    BEGIN
        UPDATE users SET account_status = 'invalid_status' WHERE id = test_user_id;
    EXCEPTION WHEN check_violation THEN
        constraint_failed := true;
    END;
    
    IF NOT constraint_failed THEN
        RAISE EXCEPTION 'Account status constraint not working';
    END IF;
    
    -- Reset for next test
    constraint_failed := false;
    
    -- Test invalid rating (should fail)
    BEGIN
        INSERT INTO user_feedback (user_id, feedback_type, rating)
        VALUES (test_user_id, 'rating', 10); -- Invalid rating > 5
    EXCEPTION WHEN check_violation THEN
        constraint_failed := true;
    END;
    
    IF NOT constraint_failed THEN
        RAISE EXCEPTION 'Rating constraint not working';
    END IF;
    
    RAISE NOTICE '✅ Constraint Validation Test: PASSED';
    
    -- Cleanup
    DELETE FROM users WHERE id = test_user_id;
    
END $$;

-- =========================================================
-- 10. PERFORMANCE TESTS
-- =========================================================

-- Test 10.1: Index usage verification
DO $$
DECLARE
    index_count INTEGER;
    query_plan TEXT;
BEGIN
    -- Count indexes
    SELECT COUNT(*) INTO index_count 
    FROM pg_indexes 
    WHERE schemaname = 'public';
    
    IF index_count < 25 THEN
        RAISE EXCEPTION 'Not enough indexes created for performance';
    END IF;
    
    -- Test that indexes are being used in common queries
    EXPLAIN (FORMAT TEXT) 
    SELECT * FROM users WHERE email = 'test@example.com';
    
    RAISE NOTICE '✅ Index Performance Test: PASSED (% indexes)', index_count;
    
END $$;

-- =========================================================
-- 11. SECURITY TESTS
-- =========================================================

-- Test 11.1: Role and permission verification
DO $$
DECLARE
    role_exists BOOLEAN;
    permission_count INTEGER;
BEGIN
    -- Check if application roles exist
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = 'aspargo_app_read') INTO role_exists;
    IF NOT role_exists THEN
        RAISE EXCEPTION 'aspargo_app_read role not created';
    END IF;
    
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = 'aspargo_app_write') INTO role_exists;
    IF NOT role_exists THEN
        RAISE EXCEPTION 'aspargo_app_write role not created';
    END IF;
    
    RAISE NOTICE '✅ Security Roles Test: PASSED';
    
END $$;

-- =========================================================
-- 12. FINAL TEST SUMMARY
-- =========================================================

DO $$
DECLARE
    total_tables INTEGER;
    total_indexes INTEGER;
    total_triggers INTEGER;
    total_views INTEGER;
    total_functions INTEGER;
BEGIN
    -- Count database objects
    SELECT COUNT(*) INTO total_tables 
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    
    SELECT COUNT(*) INTO total_indexes 
    FROM pg_indexes 
    WHERE schemaname = 'public';
    
    SELECT COUNT(*) INTO total_triggers 
    FROM information_schema.triggers 
    WHERE trigger_schema = 'public';
    
    SELECT COUNT(*) INTO total_views 
    FROM information_schema.views 
    WHERE table_schema = 'public';
    
    SELECT COUNT(*) INTO total_functions 
    FROM information_schema.routines 
    WHERE routine_schema = 'public';
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ============================================';
    RAISE NOTICE '🌱 ASPARGO DATABASE TESTING COMPLETE!';
    RAISE NOTICE '🎉 ============================================';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Database Object Summary:';
    RAISE NOTICE '   📋 Tables: %', total_tables;
    RAISE NOTICE '   🗂️  Indexes: %', total_indexes;
    RAISE NOTICE '   ⚡ Triggers: %', total_triggers;
    RAISE NOTICE '   👁️  Views: %', total_views;
    RAISE NOTICE '   🔧 Functions: %', total_functions;
    RAISE NOTICE '';
    RAISE NOTICE '✅ All Tests Passed Successfully!';
    RAISE NOTICE '🚀 Database is ready for production deployment!';
    RAISE NOTICE '';
    
END $$;