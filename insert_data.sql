\c sampledb
CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO users (name) VALUES ('Alice'), ('Bob');
