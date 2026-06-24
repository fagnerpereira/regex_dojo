CREATE TABLE `schema_migrations`(`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `users`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `session_id` varchar(255) NOT NULL UNIQUE,
  `xp` integer DEFAULT(0) NOT NULL,
  `belt` varchar(255) DEFAULT('white') NOT NULL,
  `streak` integer DEFAULT(0) NOT NULL,
  `last_active_at` timestamp DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL
);
CREATE TABLE `progress`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `user_id` integer NOT NULL REFERENCES `users` ON DELETE CASCADE,
  `kata_id` varchar(255) NOT NULL,
  `solved` boolean DEFAULT(0) NOT NULL,
  `xp_gained` integer DEFAULT(0) NOT NULL,
  `created_at` timestamp DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL
);
CREATE TABLE `blitz_scores`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `user_id` integer NOT NULL REFERENCES `users` ON DELETE CASCADE,
  `score` integer NOT NULL,
  `speed_multiplier` double precision NOT NULL,
  `created_at` timestamp DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL
);
CREATE TABLE `challenges`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `title` string NOT NULL,
  `difficulty` string NOT NULL,
  `description` text NOT NULL,
  `hint` text,
  `created_at` datetime DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL,
  `updated_at` datetime DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL,
  `concept` string,
  `lesson` text,
  `task` text
);
CREATE TABLE `test_cases`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `challenge_id` integer NOT NULL REFERENCES `challenges` ON DELETE CASCADE,
  `input` text NOT NULL,
  `expected_match` text,
  `created_at` datetime DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL,
  `updated_at` datetime DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL
);
CREATE TABLE `submissions`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `challenge_id` integer NOT NULL REFERENCES `challenges` ON DELETE CASCADE,
  `user_pattern` text NOT NULL,
  `is_passing` boolean DEFAULT(0) NOT NULL,
  `submitted_at` datetime DEFAULT(datetime(CURRENT_TIMESTAMP, 'localtime')) NOT NULL
);
INSERT INTO schema_migrations (filename) VALUES
('20260622184408_create_dojo_tables.rb'),
('20260622195442_create_challenges.rb'),
('20260622195449_create_test_cases.rb'),
('20260622195455_create_submissions.rb'),
('20260623090000_add_details_to_challenges.rb');
