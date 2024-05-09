#include "pgroonga.h"

#include "pgrn-compatible.h"

#include <access/heapam.h>
#include <funcapi.h>
#include <miscadmin.h>
#include <utils/acl.h>
#include <utils/builtins.h>

PGDLLEXPORT PG_FUNCTION_INFO_V1(pgroonga_list_broken_indexes);

typedef struct
{
	Relation indexes;
	TableScanDesc scan;
} PGrnListBrokenIndexData;

Datum
pgroonga_list_broken_indexes(PG_FUNCTION_ARGS)
{
	FuncCallContext *context;
	LOCKMODE lock = AccessShareLock;
	PGrnListBrokenIndexData *data;
	HeapTuple indexTuple;

	if (SRF_IS_FIRSTCALL())
	{
		MemoryContext oldContext;
		context = SRF_FIRSTCALL_INIT();
		oldContext = MemoryContextSwitchTo(context->multi_call_memory_ctx);

		data = palloc(sizeof(PGrnListBrokenIndexData));
		data->indexes = table_open(IndexRelationId, lock);
		data->scan = table_beginscan_catalog(data->indexes, 0, NULL);
		context->user_fctx = data;

		MemoryContextSwitchTo(oldContext);
	}

	context = SRF_PERCALL_SETUP();
	data = context->user_fctx;

	while ((indexTuple = heap_getnext(data->scan, ForwardScanDirection)))
	{
		Form_pg_index indexForm = (Form_pg_index) GETSTRUCT(indexTuple);
		Relation index;
		Datum name;

		if (!pgrn_pg_class_ownercheck(indexForm->indexrelid, GetUserId()))
			continue;

		index = RelationIdGetRelation(indexForm->indexrelid);
		if (!PGrnIndexIsPGroonga(index))
		{
			RelationClose(index);
			continue;
		}
		if (PGRN_RELKIND_HAS_PARTITIONS(index->rd_rel->relkind))
		{
			RelationClose(index);
			continue;
		}

		name = PointerGetDatum(cstring_to_text(RelationGetRelationName(index)));
		RelationClose(index);
		SRF_RETURN_NEXT(context, name);
	}

	// todo
	// Filtering broken indexes

	heap_endscan(data->scan);
	table_close(data->indexes, lock);
	SRF_RETURN_DONE(context);
}