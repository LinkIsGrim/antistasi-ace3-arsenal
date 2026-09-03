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

    // ACE's native "Sort alphabetically" has no real statement (ACE_Arsenal_Sorts.hpp:
    // statement = QUOTE({})) - it's a sentinel meaning "sort the control's own
    // rendered row text", which breaks once fnc_decorate.sqf prefixes that text
    // with a stock label. Not calling ace_arsenal_fnc_removeSort on it -
    // confirmed from its own source (fnc_removeSort.sqf) that it hardcodes a
    // refusal to delete anything with an "ace_alphabetically" id ("make
    // default sort not deletable"), so it would always be a no-op anyway.
    // (A first pass called it wrong regardless - unwrapped ID array instead
    // of ace_arsenal_fnc_removeSort's actual [_idList] calling convention -
    // which threw and silently aborted the rest of this script, including
    // everything registered below. Confirmed from the RPT: "Error foreach:
    // Type String, expected Array,HashMap", fnc_removeSort.sqf line 53.)
    // Just adding our own alongside it, same display name.
    [
        [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17], [0,1,2,3,4,5,6,7]],
        QGVAR(sortAlphabetical), "Sort alphabetically",
        {_this call FUNC(sortStatementAlphabetical)}
    ] call ace_arsenal_fnc_addSort;

    // Sort by pool stock rather than anything ACE natively tracks - applies
    // to every left/right tab per the framework doc's stat/sort tab numbering
    // (face/voice/insignia excluded, tabs 15-17 left - not pool-tracked items).
    [
        [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14], [0,1,2,3,4,5,6,7]],
        QGVAR(sortStock), "Sort by stock",
        {_this call FUNC(sortStatementStock)}
    ] call ace_arsenal_fnc_addSort;

    // Both the native alphabetical sort (no real statement, sorts on raw row
    // text) and our own custom sorts' tie-break (ACE concatenates the row's
    // rendered text after the statement's value for every sort, confirmed
    // from fnc_sortPanel.sqf) read the row's literal displayed text - which
    // fnc_decorate.sqf prefixes with a stock label. So anything sort-related
    // needs to see the clean name at the moment sorting actually happens:
    // strip the prefix right before the native sort runs, re-decorate after.
    private _origSortPanel = ace_arsenal_fnc_sortPanel;
    ace_arsenal_fnc_sortPanel = {
        params ["_control"];
        private _display = ctrlParent _control;
        private _ours = !isNull (missionNamespace getVariable [QGVAR(snapUnit), objNull]);

        // TEMP diagnostic - confirms whether this wrapper is actually being
        // invoked at all (there may be a direct internal call path during the
        // initial panel fill, separate from the onLBSelChanged event, that
        // captured the original function before this reassignment ran).
        diag_log text format ["[skuaa3aa_arsenal] sortPanel wrapper hit, ours=%1, ctrl=%2", _ours, ctrlIDC _control];

        if (_ours) then {
            {
                private _ctrl = _display displayCtrl _x;
                if (!isNull _ctrl) then {
                    for "_i" from 0 to (lbSize _ctrl) - 1 do {
                        _ctrl lbSetText [_i, [_ctrl lbText _i] call FUNC(cleanName)];
                    };
                };
            } forEach [ARSENAL_IDC_LEFTLIST, ARSENAL_IDC_RIGHTLIST];

            private _ctrlNb = _display displayCtrl ARSENAL_IDC_RIGHTLISTNB;
            if (!isNull _ctrlNb) then {
                private _rows = (lnbSize _ctrlNb) select 0;
                for "_i" from 0 to _rows - 1 do {
                    _ctrlNb lnbSetText [[_i, 1], [_ctrlNb lnbText [_i, 1]] call FUNC(cleanName)];
                };
            };
        };

        _this call _origSortPanel;

        if (_ours) then {_display call FUNC(decorate)};
    };

    // Deliberately not reordering "Sort by stock" to the front of the dropdown -
    // addSort always appends and there's no priority parameter, so doing that
    // would mean directly mutating GVAR(sortListLeftPanel)/RightPanel, ACE's own
    // undocumented internal globals. Same reach-into-internals risk we avoided
    // everywhere else this session (not hiding tabs via display controls, not
    // patching GVAR(center) to accept non-CAManBase) - not worth it just for
    // dropdown position. Both sorts are present and correct, just not first.

    // Debounced to let the cargo container actually settle before diffing -
    // matches the pattern antistasi-ace-arsenal uses for the same event.
    ["ace_arsenal_cargoChanged", {
        [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addEventHandler;

    // The "remove all"/"remove selected" buttons clear a container via bulk
    // clearXCargoGlobal commands, which never fire ace_arsenal_cargoChanged -
    // antistasi-ace-arsenal hit the same gap and fixed it the same way, control-level
    // event handlers rather than trying to wrap the underlying function.
    ["ace_arsenal_displayOpened", {
        params ["_display"];

        {
            private _ctrl = _display displayCtrl _x;
            if (!isNull _ctrl) then {
                _ctrl ctrlAddEventHandler ["ButtonClick", {
                    [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
                }];
            };
        } forEach [ARSENAL_IDC_BTN_REMOVEALL, ARSENAL_IDC_BTN_REMOVEALLSEL];
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
