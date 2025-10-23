SET pgroonga.enable_wal = yes;

CREATE TABLE memos (
  content text
);

CREATE TABLE tags (
  name text
);

INSERT INTO memos VALUES ('Groonga is fast!');
INSERT INTO tags VALUES ('Groonga');

CREATE INDEX pgrn_memos_index ON memos USING PGroonga (content);
CREATE INDEX pgrn_tags_index ON tags USING PGroonga (name);

INSERT INTO memos VALUES ('PGroonga is also fast!');
INSERT INTO tags VALUES ('PGroonga');

SELECT pgroonga_wal_set_applied_position('pgrn_memos_index', 0, 0);
SELECT pgroonga_wal_set_applied_position('pgrn_tags_index', 0, 0);
SELECT pgroonga_command('table_remove',
                        ARRAY[
                          'name', 'Lexicon' ||
                                  'pgrn_memos_index'::regclass::oid ||
                                  '_0'
                        ])::jsonb->>1;
SELECT pgroonga_command('table_remove',
                        ARRAY[
                          'name', 'Lexicon' ||
                                  'pgrn_tags_index'::regclass::oid ||
                                  '_0'
                        ])::jsonb->>1;
SELECT pgroonga_command('table_remove',
                        ARRAY[
                          'name', pgroonga_table_name('pgrn_memos_index')
                        ])::jsonb->>1;
SELECT pgroonga_command('table_remove',
                        ARRAY[
                          'name', pgroonga_table_name('pgrn_tags_index')
                        ])::jsonb->>1;

SELECT pgroonga_wal_apply();

SELECT pgroonga_command('select',
                        ARRAY[
                          'table', pgroonga_table_name('pgrn_memos_index'),
                          'output_columns', '_id, content'
                        ])::jsonb->>1;
SELECT pgroonga_command('select',
                        ARRAY[
                          'table', pgroonga_table_name('pgrn_tags_index'),
                          'output_columns', '_id, name'
                        ])::jsonb->>1;

DROP TABLE memos;
DROP TABLE tags;

SET pgroonga.enable_wal = default;
