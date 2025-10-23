CREATE TABLE memos (
  id integer PRIMARY KEY,
  content text
);

INSERT INTO memos VALUES (1, 'PostgreSQL is a RDBMS.');
INSERT INTO memos VALUES (2, 'Groonga is fast full text search engine.');
INSERT INTO memos VALUES (3, 'PGroonga is a PostgreSQL extension that uses Groonga.');

CREATE INDEX grnindex ON memos USING pgroonga (id, content);

SET enable_seqscan = off;
SET enable_indexscan = on;
SET enable_bitmapscan = off;

SELECT id, content, pgroonga_score(memos)
  FROM memos
 WHERE content %% 'PGroonga' AND content %% 'Groonga';

DROP TABLE memos;
