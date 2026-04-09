-- ============================================
-- 1. IDENTITY & SOCIAL GRAPH
-- ============================================
CREATE TABLE users (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name        VARCHAR(100) NOT NULL,
    last_name         VARCHAR(100) NOT NULL,
    email             VARCHAR(255) UNIQUE NOT NULL,
    phone             VARCHAR(20),
    avatar_url        TEXT,
    city              VARCHAR(255),
    state             VARCHAR(255),
    date_of_birth     DATE,
    member_since      DATE DEFAULT CURRENT_DATE,
    created_at        TIMESTAMP DEFAULT NOW(),
);

CREATE TABLE friendships (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
    friend_id   UUID REFERENCES users(id) ON DELETE CASCADE,
    status      VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'blocked' <--THIS CAN BE AN INT TO SAVE SPACE!
    created_at  TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

-- ============================================
-- 2. PLAYER PROFILES & RATINGS
-- ============================================
CREATE TABLE player_profiles (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Multi-Dimensional Ratings (0–5)
    skill_level_rating      DECIMAL(3,2) DEFAULT 0,
    consistency_rating      DECIMAL(3,2) DEFAULT 0,
    mobility_rating         DECIMAL(3,2) DEFAULT 0,
    competitiveness_rating  DECIMAL(3,2) DEFAULT 0,
    affability_rating       DECIMAL(3,2) DEFAULT 0,

    -- Weighted composite displayed at top of profile
    overall_rating DECIMAL(3,2) GENERATED ALWAYS AS (
        (skill_level_rating    * 0.40) +
        (consistency_rating    * 0.10) +
        (mobility_rating       * 0.25) +
        (competitiveness_rating * 0.20) +
        (affability_rating     * 0.05)
    ) STORED,

    -- Onboarding & Matchmaking
    self_rated_skill        DECIMAL(3,1),
    dupr_rating             DECIMAL(4,2),
    years_playing           DECIMAL(4,1),
    max_travel_miles        INT DEFAULT 15,
    playing_style           VARCHAR(50),
    preferred_days          TEXT[],
    preferred_times         TEXT[],
    injuries_limitations    TEXT,
    paddle_preference       VARCHAR(100),
    goals                   TEXT[],

    -- Shot Breakdown
    serve_rating            DECIMAL(3,2) DEFAULT 0,
    dink_rating             DECIMAL(3,2) DEFAULT 0,
    drop_rating             DECIMAL(3,2) DEFAULT 0,
    volley_rating           DECIMAL(3,2) DEFAULT 0,
    drive_rating            DECIMAL(3,2) DEFAULT 0,
    lob_rating              DECIMAL(3,2) DEFAULT 0,

    updated_at              TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 3. SESSIONS & MATCHES (Live Tracking)
-- ============================================
CREATE TABLE sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID REFERENCES users(id),
    court_id      UUID REFERENCES courts(id),
    location_text VARCHAR(255),        -- fallback for unrecognized venues
    session_type  VARCHAR(50),         -- 'Practice', 'Tournament', 'Casual' <--Don't need right now
    input_mode    VARCHAR(20) DEFAULT 'manual', -- 'voice' | 'manual' <-- Dont need
    ai_summary    TEXT, --<--Don't need
    total_duration INT,                -- planned duration in minutes
    started_at    TIMESTAMP,
    ended_at      TIMESTAMP,
    created_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE session_players (
    session_id  UUID REFERENCES sessions(id) ON DELETE CASCADE,
    user_id     UUID REFERENCES users(id),
    role        VARCHAR(20) DEFAULT 'participant', -- 'owner', 'participant', 'monitor' <--int would work here too
    PRIMARY KEY (session_id, user_id)
);

CREATE TABLE matches (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id       UUID REFERENCES sessions(id) ON DELETE CASCADE,
    created_by       UUID REFERENCES users(id),
    venue_id         UUID REFERENCES courts(id),
    game_number      INT DEFAULT 1,
    match_type       VARCHAR(50) DEFAULT 'singles', -- 'singles' | 'doubles'
    status           VARCHAR(20) DEFAULT 'pending', -- 'pending', 'active', 'completed'

    -- Game Configuration
    play_to          INT DEFAULT 11,   -- 11 | 15 | 21
    win_by           INT DEFAULT 2,
    team1_name       VARCHAR(100),
    team2_name       VARCHAR(100),
    initial_server   INT CHECK (initial_server IN (1, 2)),
    serving_team     INT CHECK (serving_team IN (1, 2)),
    server_number    INT CHECK (server_number IN (1, 2)), -- doubles: server 1 or 2

    -- Result
    final_score_team1  INT,
    final_score_team2  INT,
    rallies            INT DEFAULT 0,
    duration_seconds   INT,

    -- Flags
    has_monitor      BOOLEAN DEFAULT false,
    monitor_id       UUID REFERENCES users(id),
    score_edited     BOOLEAN DEFAULT false,

    started_at       TIMESTAMP,
    ended_at         TIMESTAMP,
    created_at       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE match_players (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id    UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id     UUID REFERENCES users(id),
    team        INT NOT NULL CHECK (team IN (1, 2)),
    is_winner   BOOLEAN,
);

-- ============================================
-- 4. LIVE DATA (Scoring & Health)
-- ============================================
CREATE TABLE score_events (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id         UUID REFERENCES matches(id) ON DELETE CASCADE,
    team             INT CHECK (team IN (1, 2)),
    points           INT DEFAULT 1,
    source           VARCHAR(20), -- 'manual', 'voice', 'watch'
    raw_voice_input  TEXT,
    is_undone        BOOLEAN DEFAULT false,
    undone_at        TIMESTAMP,
    recorded_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE health_metrics (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id         UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id          UUID REFERENCES users(id),
    avg_heart_rate   INT,
    max_heart_rate   INT,
    steps            INT,
    active_minutes   INT,
    calories_burned  DECIMAL(6,2),
    recorded_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 5. AI ALERTS & ACHIEVEMENTS
-- ============================================
CREATE TABLE ai_alerts (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID REFERENCES users(id),
    issue_type           VARCHAR(100),
    severity             VARCHAR(20), -- 'Warning', 'Info'
    skill_snapshot       DECIMAL(3,2),
    affability_snapshot  DECIMAL(3,2),
    trend_direction      VARCHAR(20),
    ai_insight           TEXT,
    is_dismissed         BOOLEAN DEFAULT false,
    dismissed_at         TIMESTAMP,
    created_at           TIMESTAMP DEFAULT NOW()
);

CREATE TABLE achievements (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id),
    type        VARCHAR(50),
    count       INT DEFAULT 1,
    earned_at   TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- 6. POST-MATCH RATINGS
-- ============================================
CREATE TABLE match_ratings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id        UUID REFERENCES matches(id) ON DELETE CASCADE,
    rater_id        UUID REFERENCES users(id),
    rated_user_id   UUID REFERENCES users(id),

    -- All sliders go 0.0 → 5.0
    skill_level     DECIMAL(3,1) CHECK (skill_level     BETWEEN 0 AND 5),
    consistency     DECIMAL(3,1) CHECK (consistency     BETWEEN 0 AND 5),
    mobility        DECIMAL(3,1) CHECK (mobility        BETWEEN 0 AND 5),
    competitiveness DECIMAL(3,1) CHECK (competitiveness BETWEEN 0 AND 5),
    affability      DECIMAL(3,1) CHECK (affability      BETWEEN 0 AND 5),

    notes           TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(match_id, rater_id, rated_user_id)
);


