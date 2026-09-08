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
//
// Captured before either reassignment - overrides/fnc_arsenal_init.sqf calls
// through to this, deliberately not vendoring/reimplementing Antistasi's own
// action-adding logic. See that file's header for why: as long as
// JN_fnc_arsenal_handleAction is reassigned before the real init actually
// runs (order between these two lines doesn't matter, only "before either
// is ever invoked" does, and invocation only happens later from Antistasi's
// own fn_initServer.sqf/fn_initClient.sqf), stock's own "Arsenal" addAction
// call captures this addon's override as its snapshot automatically.
GVAR(originalArsenalInit) = JN_fnc_arsenal_init;
// Same reasoning, same reason overrides/fnc_arsenal_handleAction.sqf needs
// it: CE's own driver-detected vehicle arsenal isn't in handleAction at all,
// it's in the arsenalOpened dispatch the (now wrapped, still-running)
// original init registers - deferring to this for that one case, rather
// than vendoring CE's own driver-check/vehicleArsenal-skinning logic.
GVAR(originalArsenalHandleAction) = JN_fnc_arsenal_handleAction;

JN_fnc_arsenal_init = compileFinal preprocessFileLineNumbers QPATHTOF(overrides\fnc_arsenal_init.sqf);
JN_fnc_arsenal_handleAction = compileFinal preprocessFileLineNumbers QPATHTOF(overrides\fnc_arsenal_handleAction.sqf);

// TEH-only: "Quick resupply"/"Equip last loadout"/"Mag Service" all read
// jna_dataList directly (stock/ammo lookups) - TEH's own fn_arsenal_init.sqf
// already adds all three as actions (called through to unmodified, above),
// but jna_dataList itself is only ever populated by the vanilla BIS-skinned
// arsenal display actually opening (fn_arsenal.sqf), which never happens
// once ACE Arsenal replaces it - confirmed via source, jna_dataList would
// otherwise sit at fn_arsenal_init.sqf's empty-array default forever.
// An earlier version of this addon fixed that by adding its OWN second copy
// of these three actions (wrapped in a sync-first call) in
// overrides/fnc_arsenal_init.sqf - but now that this file calls through to
// the real init instead of replacing it, that meant BOTH copies existed on
// the object at once, showing every one of these three actions twice
// (confirmed via a field report/RPT).
//
// Wrapping the three underlying globals instead, same capture-then-reassign
// pattern as JN_fnc_arsenal_init/handleAction above, fixes the duplication
// at the root: TEH's own action still gets added exactly once (by the real
// init), but by the time it's clicked, each global already points at this
// addon's sync-first wrapper - so there is nothing left to add or duplicate.
// Every code block that calls one of these three inside TEH's stock
// fn_arsenal_init.sqf does so via a late-bound global lookup by name at
// click time (e.g. `[vehicle player] call JN_fnc_arsenal_quickReload;`), not
// an eager capture the way the "Arsenal" action's own script argument is -
// confirmed by reading that file - so reassigning the global here is enough,
// with nothing upstream to keep in sync.
// Temporary diagnostics (strip once understood) - queuing
// fnc_requestDataListSync.sqf's pending callbacks (a77bd51) didn't fix
// Quick resupply/Equip last loadout/Mag Service per a field report on that
// exact build - logging every link in the chain (wrapper invoked -> sync
// requested -> original function actually called) instead of guessing a
// third time.
if (!isNil "JN_fnc_arsenal_quickReload") then {
    GVAR(originalArsenalQuickReload) = JN_fnc_arsenal_quickReload;
    JN_fnc_arsenal_quickReload = {
        private _args = _this;
        diag_log text format ["[skuaa3aa_arsenal][DIAG] quickReload wrapper invoked, args=%1", _args];
        [{
            diag_log text "[skuaa3aa_arsenal][DIAG] quickReload sync callback firing, calling original";
            _args call GVAR(originalArsenalQuickReload);
        }] call FUNC(requestDataListSync);
    };
};

if (!isNil "JN_fnc_arsenal_loadInventory") then {
    GVAR(originalArsenalLoadInventory) = JN_fnc_arsenal_loadInventory;
    JN_fnc_arsenal_loadInventory = {
        private _args = _this;
        diag_log text format ["[skuaa3aa_arsenal][DIAG] loadInventory wrapper invoked, args=%1", _args];
        [{
            diag_log text "[skuaa3aa_arsenal][DIAG] loadInventory sync callback firing, calling original";
            _args call GVAR(originalArsenalLoadInventory);
        }] call FUNC(requestDataListSync);
    };
};

if (!isNil "A3A_fnc_MagConvert_open") then {
    GVAR(originalMagConvertOpen) = A3A_fnc_MagConvert_open;
    A3A_fnc_MagConvert_open = {
        private _args = _this;
        diag_log text format ["[skuaa3aa_arsenal][DIAG] MagConvert_open wrapper invoked, args=%1", _args];
        [{
            diag_log text "[skuaa3aa_arsenal][DIAG] MagConvert_open sync callback firing, calling original";
            _args call GVAR(originalMagConvertOpen);
        }] call FUNC(requestDataListSync);
    };
};

// ACEAX (ACE3 Arsenal Extended) compat - see fnc_installAceaxCompat.sqf's
// header. isNil-guarded there too; only actually installs anything if
// ACEAX's arsenal component is loaded.
call FUNC(installAceaxCompat);

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

// Same reasoning - see fnc_markPlayerInArsenal.sqf's header for why this
// can't just call jn_fnc_arsenal_requestOpen directly either.
[QGVAR(markInArsenal), {_this call FUNC(markPlayerInArsenal)}] call CBA_fnc_addEventHandler;

if (hasInterface) then {
    [QGVAR(reconcileResult), {_this call FUNC(resolveReconcilePromise)}] call CBA_fnc_addEventHandler;
    [QGVAR(dataListResult), {_this call FUNC(dataListResult)}] call CBA_fnc_addEventHandler;
    [QGVAR(transferResult), {_this call FUNC(transferResult)}] call CBA_fnc_addEventHandler;

    // Broadcast (not targeted) - see fnc_onPoolChanged.sqf's header for why.
    [QGVAR(poolChanged), {_this call FUNC(onPoolChanged)}] call CBA_fnc_addEventHandler;

    // Counts/colors/tooltips - ACE's panels have no native concept of any of
    // this, decorated on after the fact. See fnc_decorate.sqf's header.
    //
    // Also the broadest available signal for triggering a reconcile: neither
    // left-panel equip swaps (weapon/uniform/vest/backpack/etc, confirmed
    // from fnc_onSelChangedLeft.sqf) nor right-panel attachment/optic picks
    // (fires ace_arsenal_weaponItemChanged instead, confirmed from
    // fnc_onSelChangedRight.sqf) fire ace_arsenal_cargoChanged at all - only
    // actual cargo-container add/remove does. But a left-panel weapon swap
    // does trigger an internal right-panel refill as a side effect
    // (fnc_onSelChangedLeft.sqf calls FUNC(fillRightPanel) directly), which
    // reaches us here - broader coverage than chasing every specific event.
    ["ace_arsenal_leftPanelFilled", {
        (_this select 0) call FUNC(decorate);
        [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addEventHandler;
    ["ace_arsenal_rightPanelFilled", {
        (_this select 0) call FUNC(decorate);
        [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addEventHandler;

    // Belt and braces for the specific attachment-change case, since it's a
    // more direct signal than relying on the right-panel-refill side effect.
    ["ace_arsenal_weaponItemChanged", {
        [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addEventHandler;

    // Headgear/goggles/NVG/map/compass/watch/radio/GPS - none of these trigger
    // a right-panel refill (no attachments to show), so none of them reach
    // reconcile via any of the hooks above; confirmed via fnc_onSelChangedLeft.sqf,
    // every one of those cases (add AND remove) unconditionally runs the
    // TOGGLE_RIGHT_PANEL_HIDE macro, which is the one thing they all have in
    // common - and that macro itself fires this event (defines.hpp). Without
    // it, taking/returning any of these slots' items only actually reconciles
    // once something else happens to trigger it later (a tab switch, closing
    // the arsenal) - looks like nothing happened until then, not a display lag.
    ["ace_arsenal_rightPanelHide", {
        [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addEventHandler;

    // ACE Arsenal Extended's weapon variant (grip/camo/etc) picker
    // (fnc_generateOptionsUI.sqf/fnc_onValueButton.sqf/fnc_changeGear.sqf) sets
    // the new loadout directly via a raw setUnitLoadout, entirely bypassing
    // ace_arsenal_fnc_onSelChangedLeft/Right - none of the hooks above ever
    // see it, since none of them are things this specific action does. This
    // isn't ACE's own event; it's ACEAX's aceax_ingame_optionChanged, fired
    // once fnc_changeGear.sqf's callback actually finishes applying the swap
    // (after its own delay/progress bar, not mid-flight) - reacting to it
    // here instead of missing the change entirely (which read on the ACE
    // side as an immediate revert with a leftover phantom row, since the
    // panel never got the chance to refill against the item that's actually
    // equipped now). No-ops harmlessly if ACEAX isn't installed - CBA event
    // handlers for an event that never fires are inert, not an error.
    ["aceax_ingame_optionChanged", {
        [{call FUNC(reconcile)}, []] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addEventHandler;

    // Sort by pool stock rather than anything ACE natively tracks - applies
    // to every left/right tab per the framework doc's stat/sort tab numbering
    // (face/voice/insignia excluded, tabs 15-17 left - not pool-tracked items).
    [
        [[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14], [0,1,2,3,4,5,6,7]],
        QGVAR(sortStock), "Sort by stock",
        {_this call FUNC(sortStatementStock)}
    ] call ace_arsenal_fnc_addSort;

    // ACE's native alphabetical sort is fixed via a config-level statement
    // override instead (config.cpp: class ace_arsenal_sorts { class
    // ACE_alphabetically {...}; };), not a wrapper here. A wrapper around
    // ace_arsenal_fnc_sortPanel was tried first (strip the stock-label prefix
    // before the native sort runs, since both the native alphabetical sort
    // and every custom sort's tie-break read the row's literal rendered
    // text) - confirmed via RPT diag_log across two separate test sessions
    // that it was NEVER actually invoked, despite the config wiring being
    // verified correct (sortLeftTab: RscCombo { onLBSelChanged =
    // QUOTE(call FUNC(sortPanel)); }, inherited by sortLeftTabDirection/
    // sortRightTab/sortRightTabDirection). Root cause not identified -
    // reassigning a global normally intercepts config event handler calls
    // to it just fine (confirmed by this whole addon's core mechanism,
    // JN_fnc_arsenal_init/handleAction), so something about this specific
    // control's invocation path doesn't. Not chasing it further - the config
    // override sidesteps the question entirely for the case that mattered
    // (alphabetical had no real statement, so the corrupted text was its
    // *whole* sort key). "Sort by stock"'s own tie-break (only relevant
    // when two items have the exact same stock count) is left uncorrected -
    // minor, since the stock value itself still dominates the ordering.

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

        // Antistasi's own Tab/Y menu keybinds (core/keybinds/fn_keyActions.sqf)
        // already refuse to fire while the player is in the arsenal - but that
        // guard checks jna_playersInArsenal, a server list only vanilla JNA's own
        // open flow (fn_arsenal_requestOpen.sqf) maintains. This addon opens ACE
        // Arsenal directly and never goes through that flow, so a player using
        // this bridge was never actually on that list - Antistasi's own existing
        // protection silently didn't apply here. Piggybacking on the same
        // list/mechanism rather than inventing a separate guard - but NOT by
        // calling jn_fnc_arsenal_requestOpen directly, since that function also
        // remoteExecCalls "Open" on jn_fnc_arsenal to the client, opening the
        // real BIS-skinned arsenal display alongside ACE Arsenal (caught before
        // release - see fnc_markPlayerInArsenal.sqf's header). This event
        // replicates only the safe half of what that function does.
        [QGVAR(markInArsenal), [clientOwner]] call CBA_fnc_serverEvent;

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
        // Matches the requestOpen call in the displayOpened handler above -
        // removes this player from jna_playersInArsenal again so Antistasi's own
        // Tab/Y keybind guard (core/keybinds/fn_keyActions.sqf) stops refusing
        // them once the arsenal is actually closed.
        [clientOwner] remoteExecCall ["jn_fnc_arsenal_requestClose", 2];

        // Catches anything a debounced cargoChanged reconcile hasn't settled yet
        // (e.g. a change right before close) before the snapshot state is torn down.
        call FUNC(reconcile);

        ["RestoreTFAR"] call jn_fnc_arsenal;

        if (missionNamespace getVariable [QGVAR(loadoutMode), false]) then {
            // Capture what to save (if anything) BEFORE restoring the player's own
            // gear below, and restore that gear unconditionally right after -
            // regardless of whether the save itself goes on to succeed. SQF's
            // try/catch doesn't apply here (it only catches an explicit throw, not
            // an actual runtime error - https://community.bistudio.com/wiki/try),
            // so the real defense is just not letting anything risky sit between
            // "arsenal closed" and "player has their own gear back" - a bad
            // interaction with something else touching this same display
            // shouldn't be able to leave the player stuck in the rebel's gear on
            // top of whatever else it breaks.
            private _editedLoadout = getUnitLoadout player;
            private _roleToSave = currentRebelLoadout;

            private _own = GVAR(loadoutBackup);
            if (!isNil "_own") then {player setUnitLoadout _own};
            GVAR(loadoutBackup) = nil;
            GVAR(loadoutMode) = false;
            currentRebelLoadout = nil;

            // Plain getUnitLoadout, not CBA's extended format - A3A_fnc_equipRebel
            // indexes rebelLoadouts' stored array directly (_customLoadout select
            // 0/1/2/etc.), the same shape this already is. Type-checked rather
            // than assumed - a HashMap is expected here (matches
            // fn_initVarServer.sqf's own DECLARE_SERVER_VAR(rebelLoadouts,
            // createHashMap)), but this addon doesn't own that variable and isn't
            // the only thing that can touch it.
            if (!isNil "_roleToSave") then {
                private _rebelLoadouts = missionNamespace getVariable ["rebelLoadouts", createHashMap];
                if (_rebelLoadouts isEqualType createHashMap) then {
                    rebelLoadouts = _rebelLoadouts;
                    rebelLoadouts set [_roleToSave, _editedLoadout];
                    publicVariable "rebelLoadouts";
                } else {
                    diag_log text format ["[skuaa3aa_arsenal] rebelLoadouts was %1, not a HashMap - not saving rebel loadout edit for %2.", typeName _rebelLoadouts, _roleToSave];
                };
            };
        } else {
            // TEH's "Equip last loadout" action (fn_arsenal_init.sqf, called
            // through unmodified - this addon only wraps the underlying
            // JN_fnc_arsenal_loadInventory global, not the action itself)
            // reads player getVariable ["lastArsenalLoadout", ""] and looks
            // that name up via BIS_fnc_saveInventory's own profileNamespace
            // storage - both are normally only ever populated by JNA's own
            // vanilla "Save Template" button inside its BIS-skinned arsenal
            // display, which this addon's players never see, so the action
            // always fell through to its own "no saved loadout" message.
            // Replicating that exact save (same command, same storage)
            // automatically here - under a fixed internal template name, not
            // exposed to the player - keeps the action working exactly as
            // before, with no change needed to TEH's own action code.
            if (!isNil "JN_fnc_arsenal_loadInventory") then {
                [
                    player,
                    [profileNamespace, QGVAR(lastArsenalTemplate)],
                    [
                        player getVariable ["BIS_fnc_arsenal_face", face player],
                        speaker player,
                        player call BIS_fnc_getUnitInsignia
                    ]
                ] call BIS_fnc_saveInventory;
                player setVariable ["lastArsenalLoadout", QGVAR(lastArsenalTemplate)];
            };
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
