#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: sends whatever's accumulated in GVAR(pendingTaken)/
 * GVAR(pendingReturned) (see FUNC(onItemsChanged)) to the server for
 * authoritative accept/refuse (fnc_serverReconcile.sqf), same as before.
 *
 * Unlike the old FUNC(reconcile), a call that arrives while a previous
 * proposal is still in flight doesn't need special handling beyond just
 * exiting - nothing is lost, because FUNC(onItemsChanged) already folded it
 * into GVAR(pendingTaken)/GVAR(pendingReturned) before calling here, and
 * fnc_reconcileResult.sqf always calls back in once busy clears.
 *
 * Doesn't commit anything itself - the actual pool mutation and any
 * correction (strip/revert) happen once the server's reconcileResult event
 * comes back, see XEH_postInit.sqf.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call FUNC(flushReconcile)
 */

if (missionNamespace getVariable [QGVAR(busy), false]) exitWith {};

private _unit = missionNamespace getVariable [QGVAR(snapUnit), objNull];
if (isNull _unit) exitWith {};

private _fnc_flatten = {
    params ["_bucket"];
    private _entries = [];
    {
        private _tab = _x;
        {
            _entries pushBack [_tab, _x, _y];
        } forEach _y;
    } forEach _bucket;
    _entries
};

private _taken = [GVAR(pendingTaken)] call _fnc_flatten;
private _returned = [GVAR(pendingReturned)] call _fnc_flatten;

if (_taken isEqualTo [] && {_returned isEqualTo []}) exitWith {};

GVAR(busy) = true;
GVAR(pendingTaken) = createHashMap;
GVAR(pendingReturned) = createHashMap;

// Remembered so fnc_reconcileResult.sqf's "strip" case can re-queue whatever
// in this batch wasn't the magazine that got stripped - stripMagazines mutates
// the unit directly (removeMagazine), not through any of ACE's own selection-
// change/cargo-button code, so it never fires ace_arsenal_itemsChanged for
// FUNC(onItemsChanged) to pick up on its own.
GVAR(lastSentTaken) = _taken;

[QGVAR(reconcileRequest), [_unit, _taken, _returned]] call CBA_fnc_serverEvent;

// Watchdog: if the reply is ever lost (network hiccup, whatever), GVAR(busy)
// would otherwise stay true forever and silently disable reconciliation for
// the rest of the session - nothing further would ever get checked or
// charged against the pool. Token-gated so a reply that arrives in time
// (clearing busy and bumping the token) doesn't get clobbered by a stale
// watchdog from an earlier request.
private _token = (missionNamespace getVariable [QGVAR(reconcileToken), 0]) + 1;
GVAR(reconcileToken) = _token;
[{
    params ["_token"];
    if (GVAR(busy) && {missionNamespace getVariable [QGVAR(reconcileToken), -1] == _token}) then {
        diag_log text "[skuaa3aa_arsenal] Reconcile reply never arrived; clearing busy state.";
        GVAR(busy) = false;
    };
}, [_token], 5] call CBA_fnc_waitAndExecute;
