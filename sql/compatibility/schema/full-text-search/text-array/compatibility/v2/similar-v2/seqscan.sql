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

SET enable_seqscan = on;
SET enable_indexscan = off;
SET enable_bitmapscan = off;

SELECT title, contents
  FROM memos
 WHERE contents &~? 'Mroonga: A MySQL plugin that uses Groonga';

DROP TABLE memos;
