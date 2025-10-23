CREATE TABLE memos (
  id integer,
  title varchar(1023)
);

INSERT INTO memos VALUES (1, 'PostgreSQL');
INSERT INTO memos VALUES (2, 'Groonga');
INSERT INTO memos VALUES (3, 'PGroonga');

CREATE INDEX grnindex ON memos USING pgroonga (title);

SET enable_seqscan = off;
SET enable_indexscan = on;
SET enable_bitmapscan = off;

SELECT id, title
  FROM memos
 WHERE title = 'Groonga';

DROP TABLE memos;
