CREATE TABLE tags (
  name text
);

INSERT INTO tags VALUES ('PostgreSQL');
INSERT INTO tags VALUES ('Groonga');
INSERT INTO tags VALUES ('PGroonga');
INSERT INTO tags VALUES ('pglogical');

SET enable_seqscan = on;
SET enable_indexscan = off;
SET enable_bitmapscan = off;

SELECT name
  FROM tags
 WHERE name &^| ARRAY['gro', 'pos'];

DROP TABLE tags;
