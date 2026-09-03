#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: diffs GVAR(snapUnit)'s current cargo against the last-known-good
 * snapshot (GVAR(snapPool)) and proposes the deltas to the server for
 * authoritative accept/refuse (fnc_serverReconcile.sqf) - jna_dataList isn't
 * synced to clients outside JNA's own BIS-skin flow (see design-outline.md,
 * "Hook mechanism"/pool reconciliation notes), so stock/forbidden/limit
 * decisions can't be made locally.
 *
 * Simplification: doesn't special-case CBA disposable launchers the way
 * antistasi-ace-arsenal's equivalent does (splitting a launcher's embedded
 * magazine out as its own pool entry) - suspected to be part of why disposable
 * launcher ammo only shows up once the launcher is actually equipped (see
 * design-outline.md section 8). Left as a known gap, not silently dropped.
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
 * call FUNC(reconcile)
 */

if (missionNamespace getVariable [QGVAR(busy), false]) exitWith {};

private _unit = missionNamespace getVariable [QGVAR(snapUnit), objNull];
if (isNull _unit) exitWith {};

private _new = [_unit, true] call jn_fnc_arsenal_cargoToArray;
private _old = missionNamespace getVariable [QGVAR(snapPool), []];

if (_old isEqualTo []) exitWith {
    GVAR(snapPool) = _new;
    GVAR(snapLoadout) = getUnitLoadout _unit;
};

private _fnc_tally = {
    params ["_cargo"];
    private _map = createHashMap;

    {
        private _tab = _forEachIndex;
        if (_tab == JNA_TAB_CARGOMAG) then {_tab = JNA_TAB_CARGOMAGALL};

        {
            _x params [["_class", "", [""]], ["_amount", 0, [0]]];
            if (_class == "" || {_amount == 0}) then {continue};

            // Normalize camo/color variants to whatever the pool actually
            // tracks (ace_arsenal_uniqueBase) - see fnc_baseClass.sqf's header.
            // Without this, a picked uniform/vest/backpack/etc. reads back as
            // a different exact classname than what's in the pool, poolFind
            // can't find it, and the whole take gets refused.
            _class = _class call FUNC(baseClass);

            private _key = format ["%1|%2", _tab, _class];
            _map set [_key, (_map getOrDefault [_key, 0]) + _amount];
        } forEach _x;
    } forEach _cargo;

    _map
};

private _mapNew = [_new] call _fnc_tally;
private _mapOld = [_old] call _fnc_tally;

private _taken = [];
private _returned = [];

{
    private _key = _x;
    private _delta = _y - (_mapOld getOrDefault [_key, 0]);
    if (_delta == 0) then {continue};

    private _parts = _key splitString "|";
    private _entry = [parseNumber (_parts select 0), _parts select 1, abs _delta];
    if (_delta > 0) then {_taken pushBack _entry} else {_returned pushBack _entry};
} forEach _mapNew;

{
    private _key = _x;
    if (_key in _mapNew) then {continue};

    private _parts = _key splitString "|";
    _returned pushBack [parseNumber (_parts select 0), _parts select 1, _y];
} forEach _mapOld;

if (_taken isEqualTo [] && {_returned isEqualTo []}) exitWith {};

GVAR(busy) = true;
[QGVAR(reconcileRequest), [_unit, _taken, _returned]] call CBA_fnc_serverEvent;
