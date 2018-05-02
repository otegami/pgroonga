#include "pgroonga.h"

#include "pgrn-compatible.h"

#include "pgrn-global.h"
#include "pgrn-groonga.h"
#include "pgrn-options.h"
#include "pgrn-pg.h"
#include "pgrn-sequential-search.h"

#include <xxhash.h>

static grn_ctx *ctx = &PGrnContext;
static struct PGrnBuffers *buffers = &PGrnBuffers;

void
PGrnSequentialSearchDataInitialize(PGrnSequentialSearchData *data)
{
	data->table = grn_table_create(ctx,
								   NULL, 0,
								   NULL,
								   GRN_OBJ_TABLE_NO_KEY,
								   NULL, NULL);
	data->textColumn = grn_column_create(ctx,
										 data->table,
										 "text", strlen("text"),
										 NULL,
										 GRN_OBJ_COLUMN_SCALAR,
										 grn_ctx_at(ctx, GRN_DB_TEXT));
	data->recordID = grn_table_add(ctx,
								   data->table,
								   NULL, 0,
								   NULL);
	data->indexOID = InvalidOid;
	data->lexicon = NULL;
	data->indexColumn = NULL;
	data->matched =
		grn_table_create(ctx,
						 NULL, 0,
						 NULL,
						 GRN_OBJ_TABLE_HASH_KEY | GRN_OBJ_WITH_SUBREC,
						 data->table,
						 NULL);
	data->type = PGRN_SEQUENTIAL_SEARCH_UNKNOWN;
	data->expressionHash = 0;
	data->expression = NULL;
}

void
PGrnSequentialSearchDataFinalize(PGrnSequentialSearchData *data)
{
	if (data->expression)
		grn_obj_close(ctx, data->expression);
	grn_obj_close(ctx, data->matched);
	if (data->indexColumn)
		grn_obj_close(ctx, data->indexColumn);
	if (data->lexicon)
		grn_obj_close(ctx, data->lexicon);
	grn_obj_close(ctx, data->textColumn);
	grn_obj_close(ctx, data->table);
}

static void
PGrnSequentialSearchDataExecutePrepareIndex(PGrnSequentialSearchData *data,
											Oid indexOID)
{
	if (data->indexOID == indexOID)
		return;

	if (data->indexColumn)
	{
		grn_obj_close(ctx, data->indexColumn);
		data->indexColumn = NULL;
	}
	if (data->lexicon)
	{
		grn_obj_close(ctx, data->lexicon);
		data->lexicon = NULL;
	}
	data->indexOID = InvalidOid;

	data->type = PGRN_SEQUENTIAL_SEARCH_UNKNOWN;
	data->expressionHash = 0;
	if (data->expression)
	{
		grn_obj_close(ctx, data->expression);
		data->expression = NULL;
	}
}

static void
PGrnSequentialSearchDataExecuteSetIndex(PGrnSequentialSearchData *data,
										Oid indexOID)
{
	Relation index;
	grn_obj *tokenizer = NULL;
	grn_obj *normalizer = NULL;
	grn_obj *tokenFilters = &(buffers->tokenFilters);

	if (data->indexOID == indexOID)
		return;

	index = PGrnPGResolveIndexID(indexOID);
	GRN_BULK_REWIND(tokenFilters);
	PGrnApplyOptionValues(index,
						  PGRN_OPTION_USE_CASE_FULL_TEXT_SEARCH,
						  &tokenizer, PGRN_DEFAULT_TOKENIZER,
						  &normalizer, PGRN_DEFAULT_NORMALIZER,
						  tokenFilters);
	RelationClose(index);

	data->lexicon = PGrnCreateTable(InvalidRelation,
									NULL,
									GRN_OBJ_TABLE_PAT_KEY,
									grn_ctx_at(ctx, GRN_DB_SHORT_TEXT),
									tokenizer,
									normalizer,
									tokenFilters);
	data->indexColumn =
		PGrnCreateColumn(InvalidRelation,
						 data->lexicon,
						 "index",
						 GRN_OBJ_COLUMN_INDEX | GRN_OBJ_WITH_POSITION,
						 data->table);
	PGrnIndexColumnSetSource(InvalidRelation,
							 data->indexColumn,
							 data->textColumn);
	data->indexOID = indexOID;
}

void
PGrnSequentialSearchDataPrepare(PGrnSequentialSearchData *data,
								const char *target,
								unsigned int targetSize,
								const char *indexName,
								unsigned int indexNameSize)
{
	grn_obj *text = &(buffers->general);
	Oid indexOID = InvalidOid;

	grn_obj_reinit(ctx, text, GRN_DB_TEXT, 0);

	if (indexNameSize > 0)
	{
		GRN_TEXT_SET(ctx, text, indexName, indexNameSize);
		GRN_TEXT_PUTC(ctx, text, '\0');
		indexOID = PGrnPGIndexNameToID(GRN_TEXT_VALUE(text));
	}
	PGrnSequentialSearchDataExecutePrepareIndex(data, indexOID);

	GRN_TEXT_SET(ctx, text, target, targetSize);
	grn_obj_set_value(ctx,
					  data->textColumn,
					  data->recordID,
					  text,
					  GRN_OBJ_SET);

	PGrnSequentialSearchDataExecuteSetIndex(data, indexOID);
}

static bool
PGrnSequentialSearchDataPrepareExpression(PGrnSequentialSearchData *data,
										  const char *expressionData,
										  unsigned int expressionDataSize,
										  PGrnSequentialSearchType type)
{
	grn_obj *variable;
	uint64_t expressionHash;

	if (data->type != type)
	{
		data->expressionHash = 0;
		data->type = type;
	}

	expressionHash = XXH64(expressionData, expressionDataSize, 0);
	if (data->expressionHash == expressionHash)
		return true;

	if (data->expression)
	{
		grn_obj_close(ctx, data->expression);
		data->expression = NULL;
	}

	GRN_EXPR_CREATE_FOR_QUERY(ctx,
							  data->table,
							  data->expression,
							  variable);
	if (!data->expression)
	{
		ereport(ERROR,
				(errcode(ERRCODE_OUT_OF_MEMORY),
				 errmsg("pgroonga: failed to create expression: %s",
						ctx->errbuf)));
	}

	data->expressionHash = expressionHash;

	return false;
}

void
PGrnSequentialSearchDataSetQuery(PGrnSequentialSearchData *data,
								 const char *query,
								 unsigned int querySize)
{
	grn_expr_flags flags = PGRN_EXPR_QUERY_PARSE_FLAGS;
	grn_rc rc;

	if (PGrnSequentialSearchDataPrepareExpression(data,
												  query,
												  querySize,
												  PGRN_SEQUENTIAL_SEARCH_QUERY))
	{
		return;
	}

	rc = grn_expr_parse(ctx,
						data->expression,
						query, querySize,
						data->textColumn,
						GRN_OP_MATCH, GRN_OP_AND,
						flags);
	if (rc != GRN_SUCCESS)
	{
		char message[GRN_CTX_MSGSIZE];
		grn_strncpy(message, GRN_CTX_MSGSIZE,
					ctx->errbuf, GRN_CTX_MSGSIZE);

		data->expressionHash = 0;

		ereport(ERROR,
				(errcode(PGrnRCToPgErrorCode(rc)),
				 errmsg("pgroonga: failed to parse expression: %s",
						message)));
	}
}

void
PGrnSequentialSearchDataSetScript(PGrnSequentialSearchData *data,
								  const char *script,
								  unsigned int scriptSize)
{
	grn_expr_flags flags = GRN_EXPR_SYNTAX_SCRIPT;
	grn_rc rc;

	if (PGrnSequentialSearchDataPrepareExpression(data,
												  script,
												  scriptSize,
												  PGRN_SEQUENTIAL_SEARCH_SCRIPT))
	{
		return;
	}

	rc = grn_expr_parse(ctx,
						data->expression,
						script, scriptSize,
						data->textColumn,
						GRN_OP_MATCH, GRN_OP_AND,
						flags);
	if (rc != GRN_SUCCESS)
	{
		char message[GRN_CTX_MSGSIZE];
		grn_strncpy(message, GRN_CTX_MSGSIZE,
					ctx->errbuf, GRN_CTX_MSGSIZE);

		data->expressionHash = 0;

		ereport(ERROR,
				(errcode(PGrnRCToPgErrorCode(rc)),
				 errmsg("pgroonga: failed to parse expression: %s",
						message)));
	}
}

bool
PGrnSequentialSearchDataExecute(PGrnSequentialSearchData *data)
{
	bool matched = false;

	grn_table_select(ctx,
					 data->table,
					 data->expression,
					 data->matched,
					 GRN_OP_OR);

	if (grn_table_size(ctx, data->matched) == 1)
	{
		matched = true;
		grn_table_delete(ctx,
						 data->matched,
						 &(data->recordID),
						 sizeof(grn_id));
	}

	return matched;
}
