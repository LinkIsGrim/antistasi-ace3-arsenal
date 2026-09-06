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
 * Doesn't send anything itself - populates GVAR(pendingTaken)/
 * GVAR(pendingReturned) and hands off to FUNC(flushReconcile), same as
 * every other source of a pool change (fnc_buttonCargo.sqf etc., in ACE
 * proper, once ace_arsenal_itemsChanged ships - see the itemschanged-bridge
 * branch). This is the fallback for as long as that event doesn't exist yet:
 * re-derive the delta by diffing two loadout snapshots instead of being told
 * it directly. Slated for replacement once that event is available in a
 * build this addon can depend on - not deleted here, just isolated so this
 * branch stays usable against whatever ACE build is actually installed.
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

// Don't just drop this while a previous proposal is in flight - the change
// that triggered this call (e.g. swapping back to the original item before
// the first swap's round trip even resolves) needs to still get diffed
// against something once that request resolves. fnc_reconcileResult.sqf
// always re-runs this function after applying a reply, so it isn't lost -
// just deferred until the in-flight request clears.
if (missionNamespace getVariable [QGVAR(busy), false]) exitWith {};

private _unit = missionNamespace getVariable [QGVAR(snapUnit), objNull];
if (isNull _unit) exitWith {};

private _new = [_unit] call FUNC(playerCargoToArray);
private _old = missionNamespace getVariable [QGVAR(snapPool), []];

if (_old isEqualTo []) exitWith {
    GVAR(snapPool) = _new;
    GVAR(snapLoadout) = _unit call CBA_fnc_getLoadout;
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

            // Re-check after normalization, not just before - baseClass calls
            // ace_common_fnc_getConfigName, which returns "" if the classname
            // isn't found under any of its searched config categories
            // (CfgWeapons/CfgMagazines/CfgGlasses/CfgVehicles/CfgVoice/
            // CfgUnitInsignia). JNA's own cargoToArray returns a synthetic
            // "loose ammo" entry on JNA_TAB_CARGOMAGALL whose classname isn't
            // a real config class in any of those, so it got zeroed to "" here
            // and, uncaught, produced a "tab|" key. That key's trailing empty
            // segment then got silently dropped by splitString when rebuilding
            // the entry below, leaving a bare [tab] array with no class/amount
            // - constructing [tab, nil, amount] instead of erroring outright
            // (confirmed in an RPT as a literal "<null>" element sent to the
            // server as part of a real taken/returned batch). Server-side,
            // that phantom entry's failure on a magazine tab routes the WHOLE
            // batch into "strip" mode instead of a normal charge, and strip
            // mode never reaches the charge/removeItem loop at all - so
            // whatever real item was in the same batch (a weapon, ammo) never
            // got debited from the pool even though the client already had it
            // equipped. This was the actual mechanism behind the fast-swap
            // "duplication" exploit, not the busy-gate races fixed earlier.
            if (_class == "") then {continue};

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

// What fnc_reconcileResult.sqf should rebase the snapshot to once this
// request is confirmed - deliberately NOT a fresh live read of the unit at
// reply time (see that file's header for why: rebasing to "whatever's true
// right now" makes the state this request is about to confirm indistinguishable
// from any further change the player makes before the reply arrives, so a
// swap-back mid-round-trip would get silently absorbed into the new baseline
// instead of being caught by the always-on retry FUNC(reconcileResult) does).
GVAR(snapPoolProposed) = _new;
GVAR(snapLoadoutProposed) = _unit call CBA_fnc_getLoadout;

// Hand off to the shared send path (FUNC(flushReconcile)) via the same
// GVAR(pendingTaken)/GVAR(pendingReturned) shape every other source of a
// pool change uses - tab -> classname -> amount, not the "tab|class" string
// keys this file's own tally above uses internally (that encoding is exactly
// what caused the phantom-classname exploit documented above; not repeating
// it past this function's own scope).
{
    _x params ["_tab", "_class", "_amount"];
    (GVAR(pendingTaken) getOrDefaultCall [_tab, {createHashMap}, true]) set [_class, _amount];
} forEach _taken;

{
    _x params ["_tab", "_class", "_amount"];
    (GVAR(pendingReturned) getOrDefaultCall [_tab, {createHashMap}, true]) set [_class, _amount];
} forEach _returned;

call FUNC(flushReconcile);
