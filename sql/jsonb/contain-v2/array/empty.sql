CREATE TABLE logs (
  id int,
  record jsonb
);

INSERT INTO logs VALUES (1, '[]');
INSERT INTO logs VALUES (2, '[100]');
INSERT INTO logs VALUES (3, '["hello"]');
INSERT INTO logs VALUES (4, '[true]');
INSERT INTO logs VALUES (5, '[{"object": "value"}]');
INSERT INTO logs VALUES (6, '{"object": []}');

CREATE INDEX pgroonga_index ON logs
  USING pgroonga (record pgroonga_jsonb_ops_v2);

SET enable_seqscan = off;
SET enable_indexscan = on;
SET enable_bitmapscan = off;

EXPLAIN (COSTS OFF)
SELECT id, record
  FROM logs
 WHERE record @> '[]'::jsonb
 ORDER BY id;

SELECT id, record
  FROM logs
 WHERE record @> '[]'::jsonb
 ORDER BY id;

DROP TABLE logs;
