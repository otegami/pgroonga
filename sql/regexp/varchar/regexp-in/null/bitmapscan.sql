CREATE TABLE memos (
  content varchar(256)
);

INSERT INTO memos VALUES ('PostgreSQL is a RDBMS');

CREATE INDEX pgrn_content_index ON memos
  USING pgroonga (content pgroonga_varchar_regexp_ops_v2);

SET enable_seqscan = off;
SET enable_indexscan = off;
SET enable_bitmapscan = on;

EXPLAIN (COSTS OFF)
SELECT *
  FROM memos
 WHERE content &~| NULL;

SELECT *
  FROM memos
 WHERE content &~| NULL;

DROP TABLE memos;