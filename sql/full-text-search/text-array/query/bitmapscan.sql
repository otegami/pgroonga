CREATE TABLE memos (
  title text,
  contents text[]
);

INSERT INTO memos
     VALUES ('PostgreSQL',
             ARRAY['PostgreSQL is an OSS RDBMS',
                   'PostgreSQL has partial full-text search support']);
INSERT INTO memos
     VALUES ('Groonga', ARRAY['Groonga is an OSS full-text search engine',
                              'Groonga has full full-text search support']);
INSERT INTO memos
    VALUES ('PGroonga',
            ARRAY['PGroonga is an OSS PostgreSQL extension',
                  'PGroonga adds full full-text search support based on Groonga to PostgreSQL']);

CREATE INDEX pgroonga_memos_index ON memos
  USING pgroonga (contents pgroonga_text_array_full_text_search_ops);

SET enable_seqscan = off;
SET enable_indexscan = off;
SET enable_bitmapscan = on;

SELECT title, contents
  FROM memos
 WHERE contents @@ 'rdbms OR engine';

DROP TABLE memos;
