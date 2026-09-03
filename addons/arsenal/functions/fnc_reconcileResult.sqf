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

private _unit = missionNamespace getVariable [QGVAR(snapUnit), objNull];
if (isNull _unit) exitWith {GVAR(busy) = false;};

switch (_mode) do {
    case "ok": {
        GVAR(snapPool) = [_unit, true] call jn_fnc_arsenal_cargoToArray;
        GVAR(snapLoadout) = getUnitLoadout _unit;
        GVAR(stripDepth) = 0;
        GVAR(busy) = false;

        // Separate request, not piggybacked on this reply - see
        // fnc_serverReconcile.sqf's header for why. Re-decorates once the
        // fresh jna_dataList actually lands, so counts don't go stale.
        [{
            private _display = findDisplay ARSENAL_IDD;
            if (!isNull _display) then {_display call FUNC(decorate)};
        }] call FUNC(requestDataListSync);

        // A change that happened while this request was in flight (e.g.
        // swapping back to the original item before this reply even landed)
        // got dropped by fnc_reconcile.sqf's busy-gate rather than diffed -
        // see that file's header. Catch it now against the fresh snapshot
        // just above, or it's gone for good (an exploitable free take/phantom
        // return, confirmed in testing).
        if (missionNamespace getVariable [QGVAR(reconcilePending), false]) then {
            call FUNC(reconcile);
        };
    };

    case "revert": {
        _unit setUnitLoadout (missionNamespace getVariable [QGVAR(snapLoadout), getUnitLoadout _unit]);
        [_arg] call BIS_fnc_error;
        [true, false] call ace_arsenal_fnc_refresh;

        GVAR(snapPool) = [_unit, true] call jn_fnc_arsenal_cargoToArray;
        GVAR(snapLoadout) = getUnitLoadout _unit;
        GVAR(stripDepth) = 0;
        GVAR(busy) = false;

        // Same reasoning as the "ok" case above.
        if (missionNamespace getVariable [QGVAR(reconcilePending), false]) then {
            call FUNC(reconcile);
        };
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
