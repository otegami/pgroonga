CREATE TABLE fruits (
  id int,
  items jsonb
);

CREATE INDEX pgroonga_index ON fruits USING pgroonga (id, items);

DROP TABLE fruits;
