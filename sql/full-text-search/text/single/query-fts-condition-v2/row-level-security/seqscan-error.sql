CREATE TABLE memos (
  id integer,
  user_name text,
  content text
);

CREATE USER alice NOLOGIN;
GRANT ALL ON TABLE memos TO alice;

INSERT INTO memos VALUES
  (1, 'nonexistent', 'PostgreSQL is a RDBMS.');
INSERT INTO memos VALUES
  (2, 'alice', 'Groonga is fast full text search engine.');
INSERT INTO memos VALUES
  (3, 'alice', 'We need 6+ records.');
INSERT INTO memos VALUES
  (4, 'alice', 'Because ERRORDATA_STACK_SIZE is 5.');
INSERT INTO memos VALUES
  (5, 'alice', 'If more than ERRORDATA_STACK_SIZE errors are happen, ');
INSERT INTO memos VALUES
  (6, 'alice', 'PostgreSQL is PANIC-ed.');
INSERT INTO memos VALUES
  (7, 'alice', 'We need to call FlushErrorState() when we ignore an error for RLS.');

ALTER TABLE memos ENABLE ROW LEVEL SECURITY;
CREATE POLICY memos_myself ON memos USING (user_name = current_user);

SET enable_seqscan = on;
SET enable_indexscan = off;
SET enable_bitmapscan = off;

SET SESSION AUTHORIZATION alice;
\pset format unaligned
EXPLAIN (COSTS OFF)
SELECT id, content
  FROM memos
 WHERE content &@~
         ('rdbms OR engine',
          NULL,
          NULL,
          'nonexistent')::pgroonga_full_text_search_condition_with_scorers
\g |sed -r -e "s/('.+'|ROW.+)::pgroonga/pgroonga/g" -e "s/\(CURRENT_USER\)::text/CURRENT_USER/g"
\pset format aligned

SELECT id, content
  FROM memos
 WHERE content &@~
         ('rdbms OR engine',
          NULL,
          NULL,
          'nonexistent')::pgroonga_full_text_search_condition_with_scorers;
RESET SESSION AUTHORIZATION;

DROP TABLE memos;

DROP USER alice;
