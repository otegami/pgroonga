CREATE TABLE memos (
  id integer,
  text text
);

INSERT INTO memos VALUES (1, 'PostgreSQL is a RDBMS.');
INSERT INTO memos VALUES (2, 'Groonga is fast full text search engine.');
INSERT INTO memos VALUES (3, 'PGroonga is a PostgreSQL extension that uses Groonga.');

SET enable_seqscan = on;
SET enable_indexscan = off;
SET enable_bitmapscan = off;

SELECT id, text
  FROM memos
 WHERE text &` 'text @ "rdbms" || text @ "engine"';

DROP TABLE memos;
