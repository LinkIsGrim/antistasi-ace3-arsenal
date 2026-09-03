#include "script_component.hpp"

// jeroen_arsenal not actually loaded (shouldn't happen given
// skipWhenMissingDependencies, but this addon's config can't express
// requiredAddons as CE-or-Ultimate-or-TEH, and all three patch under the
// same A3A_jeroen_arsenal name anyway - this is the real runtime check).
if (isNil "JN_fnc_arsenal") exitWith {
    diag_log text "[skuaa3aa_arsenal] JNA not detected - not installing the ACE Arsenal bridge.";
};

// Direct reassignment, not a duplicate CfgFunctions class: compileFinal locks
// the compiled scope, not the global variable, so this is always legal, and
// CBA XEH postInit runs after every loaded addon's CfgFunctions have already
// been compiled - deterministic regardless of PBO scan order. See
// design-outline.md ("Hook mechanism") for why this beats fighting over
// duplicate CfgFunctions class load order.
JN_fnc_arsenal_init = compileFinal preprocessFileLineNumbers QPATHTOF(overrides\fnc_arsenal_init.sqf);
JN_fnc_arsenal_handleAction = compileFinal preprocessFileLineNumbers QPATHTOF(overrides\fnc_arsenal_handleAction.sqf);

// Server-authoritative accept/refuse for a client's proposed pool deltas -
// see fnc_reconcile.sqf's header for why this can't be decided client-side.
[QGVAR(reconcileRequest), {_this call FUNC(serverReconcile)}] call CBA_fnc_addEventHandler;

// Same reasoning applies to the transfer dialog - it needs an authoritative
// pool snapshot to display, and the transfer itself needs server checks.
[QGVAR(transferRequest), {_this call FUNC(serverTransfer)}] call CBA_fnc_addEventHandler;

// Stock JNA only ever populates a client's local jna_dataList as a side
// effect of jn_fnc_arsenal_requestOpen, which we never call (it also opens
// the real BIS arsenal). This is that side effect without the BIS-arsenal
// part - see fnc_serverSyncDataList.sqf's header.
[QGVAR(dataListRequest), {_this call FUNC(serverSyncDataList)}] call CBA_fnc_addEventHandler;

if (hasInterface) then {
    [QGVAR(reconcileResult), {_this call FUNC(reconcileResult)}] call CBA_fnc_addEventHandler;
    [QGVAR(dataListResult), {_this call FUNC(dataListResult)}] call CBA_fnc_addEventHandler;
    [QGVAR(transferResult), {_this call FUNC(transferResult)}] call CBA_fnc_addEventHandler;

    // Counts/colors/tooltips - ACE's panels have no native concept of any of
    // this, decorated on after the fact. See fnc_decorate.sqf's header.
    ["ace_arsenal_leftPanelFilled", {(_this select 0) call FUNC(decorate)}] call CBA_fnc_addEventHandler;
    ["ace_arsenal_rightPanelFilled", {(_this select 0) call FUNC(decorate)}] call CBA_fnc_addEventHandler;

    // Sort by pool stock rather than anything ACE natively tracks - applies
    // to every left/right tab per the framework doc's stat/sort tab numbering.
    [
        [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14], [0,1,2,3,4,5,6,7]],
        QGVAR(sortStock), "Antistasi Stock",
        {_this call FUNC(sortStatementStock)}
    ] call ace_arsenal_fnc_addSort;

    // Debounced to let the cargo container actually settle before diffing -
    // matches the pattern antistasi-ace-arsenal uses for the same event.
    ["ace_arsenal_cargoChanged", {
        [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addEventHandler;

    ["ace_arsenal_displayClosed", {
        // Catches anything a debounced cargoChanged reconcile hasn't settled yet
        // (e.g. a change right before close) before the snapshot state is torn down.
        call FUNC(reconcile);

        ["RestoreTFAR"] call jn_fnc_arsenal;

        if (missionNamespace getVariable [QGVAR(loadoutMode), false]) then {
            private _own = GVAR(loadoutBackup);
            if (!isNil "_own") then {player setUnitLoadout _own};
            GVAR(loadoutBackup) = nil;
            GVAR(loadoutMode) = false;
            currentRebelLoadout = nil;
        };

        // Deliberately not clearing GVAR(snapUnit)/snapPool/snapLoadout here - the
        // reconcile call just above is a server round-trip, and fnc_reconcileResult.sqf
        // needs them intact when the reply lands after this handler returns. They get
        // reset fresh at the start of the next fnc_openPlayer.sqf/fnc_openLoadout.sqf
        // anyway, so there's nothing to gain from nulling them early - only the risk of
        // dropping the in-flight reply (a "revert" verdict silently not applying).
        //
        // Known gap: closing and immediately reopening the arsenal within one network
        // round-trip could let the reopen's snapshot get clobbered by the previous
        // session's still-in-flight reply. Narrow window, not solved yet - would need
        // a request-id/session-token scheme to close properly.
    }] call CBA_fnc_addEventHandler;
};
