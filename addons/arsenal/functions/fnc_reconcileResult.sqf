#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: applies the server's verdict on a pending FUNC(flushReconcile)
 * proposal. Registered against QGVAR(reconcileResult) in XEH_postInit.sqf.
 *
 * Arguments:
 * 0: "ok", "revert" or "strip" <STRING>
 * 1: Refusal message ("revert") or magazine classnames to strip ("strip") <STRING or ARRAY>
 * 2: The request id this reply answers (see FUNC(flushReconcile)) <NUMBER>
 *
 * Return Value:
 * None
 */

params [["_mode", "", [""]], ["_arg", "", [[], ""]], ["_reqId", -1, [0]]];

// A reply that isn't for the request currently in flight is stale - either the
// watchdog already gave up on it and moved on (GVAR(busy) is false, nothing to
// clear), or, less likely but not impossible, it arrived out of order behind a
// newer request's reply. Applying it anyway would mean acting on a verdict
// about a batch that isn't (or is no longer) what's actually pending.
if (_reqId != (missionNamespace getVariable [QGVAR(reconcileToken), -1])) exitWith {};

private _unit = missionNamespace getVariable [QGVAR(snapUnit), objNull];
if (isNull _unit) exitWith {GVAR(busy) = false;};

switch (_mode) do {
    case "ok": {
        // A live read is fine here (unlike the old snapshot-diff FUNC(reconcile),
        // which had to rebase to what was actually proposed, not live state, to
        // avoid a self-cancelling diff on the next call) - this is only ever used
        // to know what to revert TO on a later refusal, not to derive future
        // deltas from, so there's no diff to accidentally cancel out.
        //
        // CBA_fnc_getLoadout, not getUnitLoadout - the extended format round-trips
        // things the plain array doesn't (CBA disposable launcher state among
        // them), and CBA_fnc_setLoadout is what actually restores it below.
        GVAR(snapLoadout) = _unit call CBA_fnc_getLoadout;
        GVAR(stripDepth) = 0;
        GVAR(busy) = false;

        // Separate request, not piggybacked on this reply - see
        // fnc_serverReconcile.sqf's header for why. Re-decorates once the
        // fresh jna_dataList actually lands, so counts don't go stale.
        [{
            private _display = findDisplay ARSENAL_IDD;
            if (!isNull _display) then {_display call FUNC(decorate)};
        }] call FUNC(requestDataListSync);

        // Catches anything ace_arsenal_itemsChanged reported while this request
        // was in flight - FUNC(onItemsChanged) already folded it into
        // GVAR(pendingTaken)/GVAR(pendingReturned), this just sends it.
        call FUNC(flushReconcile);
    };

    case "revert": {
        [_unit, (missionNamespace getVariable [QGVAR(snapLoadout), _unit call CBA_fnc_getLoadout])] call CBA_fnc_setLoadout;
        [_arg] call BIS_fnc_error;
        [true, false] call ace_arsenal_fnc_refresh;

        GVAR(snapLoadout) = _unit call CBA_fnc_getLoadout;
        GVAR(stripDepth) = 0;
        GVAR(busy) = false;

        // Whatever's sitting in GVAR(pendingTaken)/GVAR(pendingReturned) was
        // computed as a delta off the state this batch was proposing - now that
        // the unit's been forced all the way back to the last known-good
        // snapshot instead, that delta describes a transition that never
        // actually happened. Resending it would try to charge/credit for items
        // the unit doesn't hold. Drop it - anything the player does from here
        // fires its own fresh ace_arsenal_itemsChanged against the now-correct
        // baseline.
        GVAR(pendingTaken) = createHashMap;
        GVAR(pendingReturned) = createHashMap;
    };

    case "strip": {
        private _depth = missionNamespace getVariable [QGVAR(stripDepth), 0];

        if (_depth > 2) exitWith {
            diag_log text "[skuaa3aa_arsenal] Magazine strip did not converge; leaving the change alone.";
            GVAR(stripDepth) = 0;
            GVAR(busy) = false;
        };

        GVAR(stripDepth) = _depth + 1;
        [_unit, _arg] call FUNC(stripMagazines);
        ["Not enough ammo of that type in the arsenal."] call BIS_fnc_error;
        [true, false] call ace_arsenal_fnc_refresh;

        GVAR(busy) = false;

        // Nothing in the batch that led here was ever charged - strip mode
        // short-circuits fnc_serverReconcile.sqf before its charge loop - so
        // everything except the stripped magazine(s) still needs to go through.
        // stripMagazines mutates the unit directly, not through anything
        // ace_arsenal_itemsChanged covers, so it has to be re-queued by hand
        // rather than picked up automatically.
        {
            _x params ["_tab", "_class", "_amount"];
            if !(_class in _arg) then {
                private _tabMap = GVAR(pendingTaken) getOrDefaultCall [_tab, {createHashMap}, true];
                _tabMap set [_class, (_tabMap getOrDefault [_class, 0]) + _amount];
            };
        } forEach (missionNamespace getVariable [QGVAR(lastSentTaken), []]);

        call FUNC(flushReconcile);
    };
};
