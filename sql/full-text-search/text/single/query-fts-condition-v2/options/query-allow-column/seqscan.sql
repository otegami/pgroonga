CREATE TABLE memos (
  id integer,
  content text
);

INSERT INTO memos VALUES (1, 'id:1 PostgreSQL is a RDBMS.');
INSERT INTO memos VALUES (2, 'id:2 Groonga is (fast) full text search engine.');
INSERT INTO memos VALUES (3, 'id:3 PGroonga is a PostgreSQL extension that uses Groonga.');

CREATE INDEX pgrn_index ON memos
 USING pgroonga (id, content pgroonga_text_full_text_search_ops_v2)
  WITH (query_allow_column = true);

SET enable_seqscan = on;
SET enable_indexscan = off;
SET enable_bitmapscan = off;

\pset format unaligned
EXPLAIN (COSTS OFF)
SELECT id, content
  FROM memos
 WHERE content &@~ ('id:1 PostgreSQL',
                    NULL,
                    'pgrn_index')::pgroonga_full_text_search_condition
\g |sed -r -e "s/('.+'|ROW.+)::pgroonga/pgroonga/g"
\pset format aligned

SELECT id, content
  FROM memos
 WHERE content &@~ ('id:1 PostgreSQL',
                    NULL,
                    'pgrn_index')::pgroonga_full_text_search_condition;

DROP TABLE memos;
