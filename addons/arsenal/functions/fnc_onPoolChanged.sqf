#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: registered against QGVAR(poolChanged) in XEH_postInit.sqf,
 * broadcast by fnc_serverReconcile.sqf/fnc_serverTransfer.sqf whenever the
 * pool actually changes for anyone, not just the player who caused it -
 * otherwise a second player with an arsenal open concurrently would sit on
 * stale stock/counts until their own next interaction happened to trigger a
 * resync.
 *
 * Cheap no-op for anyone without an arsenal session of their own open right
 * now. For everyone else, reuses the same resync/redecorate path
 * fnc_reconcileResult.sqf's "ok" case already uses - no new sync mechanism,
 * just a new trigger for the existing one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

if (missionNamespace getVariable [QGVAR(snapUnit), objNull] isEqualTo objNull) exitWith {};

[{
    private _display = findDisplay ARSENAL_IDD;
    if (!isNull _display) then {_display call FUNC(decorate)};
}] call FUNC(requestDataListSync);
