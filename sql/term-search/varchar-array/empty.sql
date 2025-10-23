CREATE TABLE memos (
  contents varchar[]
);

CREATE INDEX pgrn_index ON memos USING pgroonga (contents);

INSERT INTO memos VALUES (ARRAY['', E'\x0a']);

DROP TABLE memos;
