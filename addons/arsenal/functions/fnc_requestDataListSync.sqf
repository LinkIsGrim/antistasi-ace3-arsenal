#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: requests a fresh jna_dataList from the server and runs the
 * given callback once it arrives (fnc_dataListResult.sqf). Every path that
 * needs a current jna_dataList client-side goes through this rather than
 * assuming it's already populated.
 *
 * Queues rather than overwrites - GVAR(pendingSyncCallbacks) is an array,
 * not a single slot. A previous version used one overwritable variable,
 * where a second concurrent call could silently drop the first caller's
 * callback with no trace. Every reply refreshes the same real jna_dataList
 * regardless of which request it's "for", so it's always correct to drain
 * and run every queued callback on whichever reply arrives first - no need
 * to match a callback to its own specific request.
 *
 * TEH's Quick resupply/Equip last loadout/Mag Service used to route through
 * here (sync first, then call the real function) - repeatedly proved
 * fragile in the field (this file's own single-slot gap among the causes)
 * for something these simple one-off actions had no business waiting on.
 * They call straight through now (XEH_postInit.sqf) and just notify other
 * clients afterward instead - see that file's header.
 *
 * Every call site MUST pass an explicit argument array, never a bare
 * `call FUNC(requestDataListSync)` - unary call does not reset _this to [],
 * it inherits whatever _this was already live in the calling scope. Two call
 * sites (fnc_reconcileResult.sqf's "ok" case, fnc_onPoolChanged.sqf) used to
 * do this and, depending on the caller's own _this at that point, could pass
 * through a stray STRING (e.g. "ok" from the reconcile promise's own _this),
 * failing the params type check below with "Error Params: Type String,
 * expected code" - confirmed via a field RPT and fixed at both call sites
 * (now `[] call FUNC(requestDataListSync)`).
 *
 * Arguments:
 * 0: Callback to run once jna_dataList is fresh <CODE> (default: {})
 *
 * Return Value:
 * None
 *
 * Example:
 * [{hint "synced"}] call FUNC(requestDataListSync)
 */

params [["_callback", {}, [{}]]];

private _pending = missionNamespace getVariable [QGVAR(pendingSyncCallbacks), []];
_pending pushBack _callback;
GVAR(pendingSyncCallbacks) = _pending;

[QGVAR(dataListRequest), [player]] call CBA_fnc_serverEvent;
