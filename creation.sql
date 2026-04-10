-- =====================================================================
-- SECTION 1: USERS
-- =====================================================================
 
CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) UNIQUE NOT NULL,
    phone               VARCHAR(20),            -- decide format
    profile_picture_url VARCHAR(50),
    city                VARCHAR(255),
    state               VARCHAR(255),
    date_of_birth       DATE,
    created_at          TIMESTAMP DEFAULT NOW()
);
 
 
-- =====================================================================
-- SECTION 2: MATCHES
-- =====================================================================
 
CREATE TABLE matches (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id        UUID,                      -- FK added later when sessions table exists
    host_id           UUID REFERENCES users(id),
    venue_id          UUID,                      -- FK added later when courts table exists
    match_number      INT DEFAULT 1,
    match_type        VARCHAR(50) DEFAULT 'singles', -- 'singles' | 'doubles'
    status            VARCHAR(20) DEFAULT 'pending', -- 'pending', 'active', 'completed'
 
    -- Game configuration
    play_to           INT DEFAULT 11,            -- 11, 15, or 21
    win_by            INT DEFAULT 2,
    team1_name        VARCHAR(100),
    team2_name        VARCHAR(100),
 
    -- Result
    final_score_team1 INT,
    final_score_team2 INT,
    rallies           INT DEFAULT 0,
    duration          TIME,
 
    -- Flags
    has_monitor       BOOLEAN DEFAULT false,
    monitor_id        UUID REFERENCES users(id),
    score_edited      BOOLEAN DEFAULT false,
 
    started_at        TIMESTAMP,
    ended_at          TIMESTAMP,
    created_at        TIMESTAMP DEFAULT NOW()
);
 
CREATE TABLE match_players (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id  UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id   UUID REFERENCES users(id),
    team      INT NOT NULL CHECK (team IN (1, 2)),
    is_winner BOOLEAN,
    is_host   BOOLEAN
);
 
 
-- =====================================================================
-- SAVE FOR LATER
-- =====================================================================
 
 
-- CREATE TABLE match_health_metrics (             
--    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--    match_id        UUID REFERENCES matches(id) ON DELETE CASCADE,
--    user_id         UUID REFERENCES users(id),
--    avg_heart_rate  INT,
--    max_heart_rate  INT,
--    steps           INT,
--    active_minutes  INT,
--    calories_burned DECIMAL(6,2),
--    recorded_at     TIMESTAMP DEFAULT NOW()
--);
 
 

-- COURTS table (needed before adding FKs to matches.venue_id and sessions.court_id)
-- CREATE TABLE courts (
--     id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name                    VARCHAR(255) NOT NULL,
--     address                 TEXT NOT NULL,
--     latitude                DECIMAL(10,8),
--     longitude               DECIMAL(11,8),
--     total_courts            INT DEFAULT 0,
--     hours                   JSONB,
--     phone                   VARCHAR(20),
--     amenities               TEXT[],
--     availability_status     VARCHAR(20),     -- 'open', 'full', 'closed'
--     availability_updated_at TIMESTAMP,
--     rating                  DECIMAL(3,2) DEFAULT 0,
--     reviews_count           INT DEFAULT 0,
--     created_at              TIMESTAMP DEFAULT NOW()
-- );
 
-- FRIENDSHIPS
-- CREATE TABLE friendships (
--     id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
--     friend_id  UUID REFERENCES users(id) ON DELETE CASCADE,
--     status     VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
--                                               -- NOTE: could use INT to save space (0/1/2)
--     created_at TIMESTAMP DEFAULT NOW(),
--     UNIQUE(user_id, friend_id)
-- );
 
-- SESSIONS (requires courts table to exist first)
-- CREATE TABLE sessions (
--     id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     user_id       UUID REFERENCES users(id),
--     court_id      UUID REFERENCES courts(id),
--     location_text VARCHAR(255),              -- fallback for venues not in courts table
--     total_duration INT,                      -- planned duration in minutes
--     started_at    TIMESTAMP,
--     ended_at      TIMESTAMP,
--     created_at    TIMESTAMP DEFAULT NOW()
--     -- Removed for now: session_type, input_mode, ai_summary
-- );
 
-- SESSION PLAYERS (requires sessions table to exist first)
-- CREATE TABLE session_players (
--     session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
--     user_id    UUID REFERENCES users(id),
--     role       VARCHAR(20) DEFAULT 'participant', -- 'owner', 'participant', 'monitor'
--                                                   -- NOTE: could use INT to save space (0/1/2)
--     PRIMARY KEY (session_id, user_id)
-- );
 
-- AI ALERTS
-- CREATE TABLE ai_alerts (
--     id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     user_id             UUID REFERENCES users(id),
--     issue_type          VARCHAR(100),
--     severity            VARCHAR(20),         -- 'Warning', 'Info'
--     skill_snapshot      DECIMAL(3,2),
--     affability_snapshot DECIMAL(3,2),
--     trend_direction     VARCHAR(20),
--     ai_insight          TEXT,
--     is_dismissed        BOOLEAN DEFAULT false,
--     dismissed_at        TIMESTAMP,
--     created_at          TIMESTAMP DEFAULT NOW()
-- );
 
-- ACHIEVEMENTS
-- CREATE TABLE achievements (
--     id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     user_id   UUID REFERENCES users(id),
--     type      VARCHAR(50),
--     count     INT DEFAULT 1,
--     earned_at TIMESTAMP DEFAULT NOW()
-- );
 
-- POST-MATCH RATINGS
-- CREATE TABLE match_ratings (
--     id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     match_id        UUID REFERENCES matches(id) ON DELETE CASCADE,
--     rater_id        UUID REFERENCES users(id),
--     rated_user_id   UUID REFERENCES users(id),
--     skill_level     DECIMAL(3,1) CHECK (skill_level     BETWEEN 0 AND 5),
--     consistency     DECIMAL(3,1) CHECK (consistency     BETWEEN 0 AND 5),
--     mobility        DECIMAL(3,1) CHECK (mobility        BETWEEN 0 AND 5),
--     competitiveness DECIMAL(3,1) CHECK (competitiveness BETWEEN 0 AND 5),
--     affability      DECIMAL(3,1) CHECK (affability      BETWEEN 0 AND 5),
--     notes           TEXT,
--     created_at      TIMESTAMP DEFAULT NOW(),
--     UNIQUE(match_id, rater_id, rated_user_id)
-- );
 
-- PLAYER RATING PROFILES (requires match_ratings to exist and be populated first)
-- CREATE TABLE player_rating_profiles (
--     id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     user_id                UUID REFERENCES users(id) ON DELETE CASCADE,
--
--     -- Dimension ratings averaged from match_ratings (0.00 – 5.00)
--     skill_level_rating     DECIMAL(3,2) DEFAULT 0,
--     consistency_rating     DECIMAL(3,2) DEFAULT 0,
--     mobility_rating        DECIMAL(3,2) DEFAULT 0,
--     competitiveness_rating DECIMAL(3,2) DEFAULT 0,
--     affability_rating      DECIMAL(3,2) DEFAULT 0,
--
--     -- Weighted composite: skill 40% + mobility 25% + competitiveness 20% + consistency 10% + affability 5%
--     overall_rating DECIMAL(3,2) GENERATED ALWAYS AS (
--         (skill_level_rating     * 0.40) +
--         (consistency_rating     * 0.10) +
--         (mobility_rating        * 0.25) +
--         (competitiveness_rating * 0.20) +
--         (affability_rating      * 0.05)
--     ) STORED,
--
--     -- Onboarding & matchmaking
--     self_rated_skill       DECIMAL(3,1),
--     dupr_rating            DECIMAL(4,2),
--     years_playing          DECIMAL(4,1),
--     max_travel_miles       INT DEFAULT 15,
--     playing_style          VARCHAR(50),
--     preferred_days         TEXT[],
--     preferred_times        TEXT[],
--     injuries_limitations   TEXT,
--     paddle_preference      VARCHAR(100),
--     goals                  TEXT[],
--
--     -- Per-shot breakdown
--     serve_rating           DECIMAL(3,2) DEFAULT 0,
--     dink_rating            DECIMAL(3,2) DEFAULT 0,
--     drop_rating            DECIMAL(3,2) DEFAULT 0,
--     volley_rating          DECIMAL(3,2) DEFAULT 0,
--     drive_rating           DECIMAL(3,2) DEFAULT 0,
--     lob_rating             DECIMAL(3,2) DEFAULT 0,
--
--     updated_at             TIMESTAMP DEFAULT NOW()
-- );
 