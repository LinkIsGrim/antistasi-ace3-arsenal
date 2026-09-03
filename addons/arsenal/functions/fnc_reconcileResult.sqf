#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: applies the server's verdict on a pending fnc_reconcile.sqf
 * proposal. Registered against QGVAR(reconcileResult) in XEH_postInit.sqf.
 *
 * Arguments:
 * 0: "ok", "revert" or "strip" <STRING>
 * 1: Refusal message ("revert") or magazine classnames to strip ("strip") <STRING or ARRAY>
 *
 * Return Value:
 * None
 */

params [["_mode", "", [""]], ["_arg", "", [[], ""]]];

diag_log text format ["[skuaa3aa_arsenal][DIAG] reconcileResult: mode=%1 arg=%2 (frame %3)", _mode, _arg, diag_frameNo];

private _unit = missionNamespace getVariable [QGVAR(snapUnit), objNull];
if (isNull _unit) exitWith {GVAR(busy) = false;};

switch (_mode) do {
    case "ok": {
        // Rebase to what was actually PROPOSED (fnc_reconcile.sqf, set right
        // before sending), not a fresh live read of the unit. This request
        // confirmed exactly that state got charged/returned - a live read
        // here would be indistinguishable from "whatever the player has done
        // since," so any change made during the round trip (e.g. swapping
        // back to the original item before this reply even landed, dropped
        // by the busy-gate) would get silently folded into the new baseline
        // as if it had already been reconciled, instead of showing up as a
        // diff for the retry below to catch. Confirmed exploitable (repeated
        // fast swapping produced free stock) with the live-read version of
        // this fix.
        GVAR(snapPool) = missionNamespace getVariable [QGVAR(snapPoolProposed), GVAR(snapPool)];
        GVAR(snapLoadout) = missionNamespace getVariable [QGVAR(snapLoadoutProposed), GVAR(snapLoadout)];
        GVAR(stripDepth) = 0;
        GVAR(busy) = false;

        // Separate request, not piggybacked on this reply - see
        // fnc_serverReconcile.sqf's header for why. Re-decorates once the
        // fresh jna_dataList actually lands, so counts don't go stale.
        [{
            private _display = findDisplay ARSENAL_IDD;
            if (!isNull _display) then {_display call FUNC(decorate)};
        }] call FUNC(requestDataListSync);

        // Always re-diff against the baseline just set, not just when a call
        // was known to be dropped - catches anything that happened during
        // the round trip, whether or not fnc_reconcile.sqf's busy-gate ever
        // actually fired for it. Cheap no-op if nothing changed.
        call FUNC(reconcile);
    };

    case "revert": {
        _unit setUnitLoadout (missionNamespace getVariable [QGVAR(snapLoadout), getUnitLoadout _unit]);
        [_arg] call BIS_fnc_error;
        [true, false] call ace_arsenal_fnc_refresh;

        GVAR(snapPool) = [_unit, true] call jn_fnc_arsenal_cargoToArray;
        GVAR(snapLoadout) = getUnitLoadout _unit;
        GVAR(stripDepth) = 0;
        GVAR(busy) = false;

        // Same reasoning as the "ok" case above - catch anything that
        // happened during the round trip.
        call FUNC(reconcile);
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
        call FUNC(reconcile);
    };
};
