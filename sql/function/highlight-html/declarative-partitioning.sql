SET pgroonga.enable_wal = yes;

CREATE TABLE memos (
  id integer,
  content text
) PARTITION BY RANGE (id);

CREATE TABLE memos_0_10
  PARTITION OF memos
  FOR VALUES FROM (0) TO (10);
CREATE TABLE memos_10_20
  PARTITION OF memos
  FOR VALUES FROM (10) TO (20);
CREATE TABLE memos_20_30
  PARTITION OF memos
  FOR VALUES FROM (20) TO (30);

CREATE INDEX memos_fts ON memos
 USING pgroonga (content)
  WITH (tokenizer = 'TokenNgram("loose_symbol", true, "report_source_location", true)',
        normalizer = 'NormalizerNFKC100("unify_kana", true)');

SELECT pgroonga_highlight_html(
  'この八百屋のリンゴはおいしい。' ||
  '連絡先は０９０-12345678だそうだ。',
  ARRAY['りんご', '（090）1234５６７８'],
  'memos_fts');

DROP TABLE memos;

SET pgroonga.enable_wal = default;
