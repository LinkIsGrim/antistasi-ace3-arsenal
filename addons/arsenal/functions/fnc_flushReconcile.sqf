#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: sends whatever's accumulated in GVAR(pendingTaken)/
 * GVAR(pendingReturned) (populated by fnc_reconcile.sqf's snapshot diff) to
 * the server for authoritative accept/refuse (fnc_serverReconcile.sqf).
 *
 * A call that arrives while a previous proposal is still in flight doesn't
 * need special handling beyond just exiting - fnc_reconcile.sqf's own
 * busy-gate means nothing populates GVAR(pendingTaken)/GVAR(pendingReturned)
 * while busy in the first place, and fnc_reconcileResult.sqf always calls
 * back into FUNC(reconcile) once busy clears, so nothing gets lost, just
 * deferred.
 *
 * Doesn't commit anything itself - the actual pool mutation and any
 * correction (strip/revert) happen once the server's reconcileResult event
 * comes back, see XEH_postInit.sqf.
 *
 * Uses an Arma 2.22+ promise handle (an "empty" spawn handle, resolved via
 * terminate) instead of a hand-rolled request id + CBA_fnc_waitAndExecute
 * watchdog to tell a real reply apart from a timed-out one. Only one is ever
 * outstanding at a time (see the busy-gate above) so there's no need to
 * disambiguate BETWEEN multiple in-flight requests the way a request id
 * would - a handle resolves exactly once by construction, whichever of
 * fnc_resolveReconcilePromise.sqf (a real reply) or the watchdog below
 * (timeout) gets there first; guarded (isNull check) against calling
 * terminate a second time regardless, since that behavior isn't something
 * this addon has actually been able to verify at runtime yet - 2.22 is very
 * recent and nothing in this repo has run against it.
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

private _promise = spawn "skuaa3aa_arsenal_reconcile";
GVAR(reconcilePromise) = _promise;

// The continuation IS the reply handling from here - fnc_resolveReconcilePromise.sqf
// (registered against QGVAR(reconcileResult) in XEH_postInit.sqf) or the watchdog
// below terminates this with the result, whichever happens first; this runs
// exactly once either way. A real reply's result is ["ok"/"revert"/"strip", _arg];
// the watchdog's is ["timeout"] - fnc_reconcileResult.sqf's switch handles both.
_promise continueWith {_this call FUNC(reconcileResult)};

[QGVAR(reconcileRequest), [_unit, _taken, _returned]] call CBA_fnc_serverEvent;

// Watchdog: if the reply is ever lost (network hiccup, whatever), the promise
// would otherwise never resolve and GVAR(busy) would stay true forever,
// silently disabling reconciliation for the rest of the session - nothing
// further would ever get checked or charged against the pool.
[{
    params ["_promise"];
    if !(isNull _promise) then {_promise terminate ["timeout"]};
}, [_promise], 5] call CBA_fnc_waitAndExecute;
