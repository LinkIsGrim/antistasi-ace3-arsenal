#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: applies the server's verdict on a pending FUNC(flushReconcile)
 * proposal. Run as GVAR(reconcilePromise)'s continuation (see that file) -
 * either fnc_resolveReconcilePromise.sqf (a real server reply) or
 * fnc_flushReconcile.sqf's own watchdog (a "timeout") resolves the promise,
 * and this runs exactly once either way with whatever value won that race.
 *
 * Arguments:
 * 0: "ok", "revert", "strip" or "timeout" <STRING>
 * 1: Refusal message ("revert") or magazine classnames to strip ("strip") <STRING or ARRAY>
 *
 * Return Value:
 * None
 */

params [["_mode", "", [""]], ["_arg", "", [[], ""]]];

private _unit = missionNamespace getVariable [QGVAR(snapUnit), objNull];
if (isNull _unit) exitWith {GVAR(busy) = false;};

switch (_mode) do {
    case "timeout": {
        // The reply was lost somewhere (network hiccup, whatever) - GVAR(busy)
        // would otherwise stay true forever, silently disabling reconciliation
        // for the rest of the session. Nothing to revert here (unlike "revert"
        // below) - the server may or may not have actually applied this batch,
        // there's no way to tell from a timeout alone, so the safest thing is
        // to just stop waiting and let the next real change surface whatever
        // the true state turns out to be.
        diag_log text "[skuaa3aa_arsenal] Reconcile reply never arrived; clearing busy state.";
        GVAR(busy) = false;
    };

    case "ok": {
        // Rebase to what was actually PROPOSED (fnc_reconcile.sqf, set right
        // before sending), not a fresh live read of the unit. This request
        // confirmed exactly that state got charged/returned - a live read
        // here would be indistinguishable from "whatever the player has done
        // since," so any change made during the round trip (e.g. swapping
        // back to the original item before this reply even landed) would get
        // silently folded into the new baseline as if it had already been
        // reconciled, instead of showing up as a diff for FUNC(reconcile)
        // below to catch. Confirmed exploitable (repeated fast swapping
        // produced free stock) with the live-read version of this fix - see
        // fnc_reconcile.sqf's header.
        //
        // CBA_fnc_getLoadout, not getUnitLoadout - the extended format round-trips
        // things the plain array doesn't (CBA disposable launcher state among
        // them), and CBA_fnc_setLoadout is what actually restores it in "revert"
        // below.
        GVAR(snapPool) = missionNamespace getVariable [QGVAR(snapPoolProposed), GVAR(snapPool)];
        GVAR(snapLoadout) = missionNamespace getVariable [QGVAR(snapLoadoutProposed), _unit call CBA_fnc_getLoadout];
        GVAR(stripDepth) = 0;
        GVAR(busy) = false;

        // Separate request, not piggybacked on this reply - see
        // fnc_serverReconcile.sqf's header for why. fnc_dataListResult.sqf
        // redecorates unconditionally once the fresh jna_dataList lands.
        [] call FUNC(requestDataListSync);

        // Always re-diff against the baseline just set, not just when a call
        // was known to be dropped - catches anything that happened during
        // the round trip, whether or not fnc_reconcile.sqf's busy-gate ever
        // actually fired for it. Cheap no-op if nothing changed.
        call FUNC(reconcile);
    };

    case "revert": {
        [_unit, (missionNamespace getVariable [QGVAR(snapLoadout), _unit call CBA_fnc_getLoadout])] call CBA_fnc_setLoadout;
        [_arg] call BIS_fnc_error;
        [true, false] call ace_arsenal_fnc_refresh;

        GVAR(snapPool) = [_unit] call FUNC(playerCargoToArray);
        GVAR(snapLoadout) = _unit call CBA_fnc_getLoadout;
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

        // No manual re-queue needed here (unlike the itemschanged-bridge
        // branch's equivalent) - stripMagazines mutates the unit's actual
        // cargo directly, and FUNC(reconcile) diffs live cargo against
        // GVAR(snapPool) regardless of what caused the difference, so it
        // naturally picks up both the strip correction and anything else
        // that happened during the round trip in one diff. That self-healing
        // property is the one genuine advantage of the diff-based approach
        // over the event-driven one, which has to know explicitly which of
        // its own actions bypass ACE's hooks.
        call FUNC(reconcile);
    };
};
