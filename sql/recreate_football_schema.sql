-- Schemas
CREATE SCHEMA IF NOT EXISTS football.base;
CREATE SCHEMA IF NOT EXISTS football.event;
CREATE SCHEMA IF NOT EXISTS football.curated;

-- Base
CREATE TABLE IF NOT EXISTS football.base.matches (
  match_id VARCHAR,
  date DATE,
  season VARCHAR,
  league VARCHAR,
  home_team VARCHAR,
  away_team VARCHAR,
  home_goals INTEGER,
  away_goals INTEGER,
  result VARCHAR,
  referee VARCHAR,
  shots_home INTEGER,
  shots_away INTEGER,
  cards_home INTEGER,
  cards_away INTEGER
)
WITH (format='PARQUET', partitioning = ARRAY['day(date)']);

CREATE TABLE IF NOT EXISTS football.base.odds (
  match_id VARCHAR,
  book VARCHAR,
  match_date DATE,
  home_odds DOUBLE,
  draw_odds DOUBLE,
  away_odds DOUBLE,
  closing_home DOUBLE,
  closing_draw DOUBLE,
  closing_away DOUBLE
)
WITH (format='PARQUET', partitioning = ARRAY['day(match_date)']);

-- Event
CREATE TABLE IF NOT EXISTS football.event.competitions (
  competition_id INTEGER,
  competition VARCHAR,
  season_id INTEGER,
  season_name VARCHAR
) WITH (format='PARQUET');

CREATE TABLE IF NOT EXISTS football.event.teams (
  team_id INTEGER,
  team VARCHAR
) WITH (format='PARQUET');

CREATE TABLE IF NOT EXISTS football.event.players (
  player_id INTEGER,
  player VARCHAR,
  position VARCHAR
) WITH (format='PARQUET');

CREATE TABLE IF NOT EXISTS football.event.matches (
  match_id INTEGER,
  competition_id INTEGER,
  season_id INTEGER,
  kickoff_time TIMESTAMP,
  venue VARCHAR,
  home_team_id INTEGER,
  away_team_id INTEGER,
  referee VARCHAR
)
WITH (format='PARQUET', partitioning = ARRAY['day(kickoff_time)']);

CREATE TABLE IF NOT EXISTS football.event.events (
  match_id INTEGER,
  team_id INTEGER,
  player_id INTEGER,
  event_ts TIMESTAMP,
  minute INTEGER,
  second INTEGER,
  type VARCHAR,
  subtype VARCHAR,
  x DOUBLE,
  y DOUBLE,
  outcome VARCHAR,
  shot_xg DOUBLE,
  pass_length DOUBLE,
  pass_height VARCHAR,
  body_part VARCHAR
)
WITH (format='PARQUET', partitioning = ARRAY['day(event_ts)']);

-- Curated
CREATE TABLE IF NOT EXISTS football.curated.team_match_summary (
  match_id VARCHAR,
  team_id INTEGER,
  xg_for DOUBLE,
  xg_against DOUBLE,
  shots INTEGER,
  deep_completions INTEGER,
  ppda DOUBLE
) WITH (format='PARQUET');

CREATE TABLE IF NOT EXISTS football.curated.player_match_summary (
  match_id VARCHAR,
  player_id INTEGER,
  minutes INTEGER,
  goals INTEGER,
  xg DOUBLE,
  xa DOUBLE,
  shots INTEGER,
  carries INTEGER,
  pressures INTEGER
) WITH (format='PARQUET');

CREATE TABLE IF NOT EXISTS football.curated.odds_enriched (
  match_id VARCHAR,
  match_date DATE,
  home_team VARCHAR,
  away_team VARCHAR,
  home_odds DOUBLE,
  draw_odds DOUBLE,
  away_odds DOUBLE,
  imp_home DOUBLE,
  imp_draw DOUBLE,
  imp_away DOUBLE,
  edge_home DOUBLE,
  edge_draw DOUBLE,
  edge_away DOUBLE
) WITH (format='PARQUET');

-- Sanity probe
DROP TABLE IF EXISTS football.base._probe;
CREATE TABLE football.base._probe (id INT) WITH (format='PARQUET');
INSERT INTO football.base._probe VALUES (1);
