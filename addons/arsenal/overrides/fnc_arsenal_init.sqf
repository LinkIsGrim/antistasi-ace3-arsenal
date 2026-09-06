#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Wraps (not replaces) JN_fnc_arsenal_init - calls through to Antistasi's
 * own, completely unmodified implementation (captured in
 * GVAR(originalArsenalInit) before this was ever assigned, in
 * XEH_postInit.sqf), then adds this addon's own TEH-only convenience
 * extras on top. Antistasi (CE/Ultimate/TEH) calls this from both
 * fn_initServer.sqf and fn_initClient.sqf with the arsenal box object.
 *
 * Deliberately NOT vendoring/reimplementing anything about the "Arsenal"
 * action, "Open Container"/driver-detected vehicle arsenal, or JNA's own
 * arsenalOpened/arsenalClosed dispatch, the way an earlier version of this
 * file did. All of that just keeps working, automatically, exactly as
 * whichever variant's own stock code already does it - because
 * JN_fnc_arsenal_handleAction is reassigned to this addon's own override
 * before the original init below ever runs. SQF evaluates an addAction's
 * script argument eagerly, at the moment addAction itself is called, not
 * as a live reference to the global variable's name - so stock's own
 * `_object addAction ["Arsenal", JN_fnc_arsenal_handleAction, ...]` call
 * captures whatever JN_fnc_arsenal_handleAction already points to at that
 * instant. Since this addon's override is already in place by then,
 * "Arsenal" ends up calling it regardless of which variant's own init code
 * added the action - zero need to track upstream's action-adding code at
 * all, on any variant, ever. Confirmed from SQF's own eager-evaluation
 * semantics (the same reasoning fnc_installItemsChangedPolyfill.sqf's
 * capture-then-reassign wrapping already relies on elsewhere in this
 * addon), not a guess.
 *
 * "Open Container"/vehicle-arsenal access - whatever form each variant's
 * own stock code gives it (an addActionSelect on Ultimate/TEH, automatic
 * driver detection on CE, neither on CE for a plain nearby container since
 * it never had one) - keeps working exactly as upstream designed, through
 * JNA's own vanilla BIS-skinned display. Untouched by this addon: ACE
 * Arsenal's per-person data model still can't represent a container's
 * stackable cargo (design-outline.md section 5), so there's nothing for
 * this addon to redirect that action to even if it wanted to.
 *
 * Arguments:
 * 0: Arsenal box object <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_object", objNull, [objNull]]];

// Matches the original's own idempotent guard - without this, a second call
// (this file's own author, Antistasi, calls JN_fnc_arsenal_init from BOTH
// fn_initServer.sqf and fn_initClient.sqf) would exit early inside the
// wrapped original but still fall through to add a second, duplicate copy
// of this addon's own TEH-extras below.
if (!isNull (missionNamespace getVariable ["jna_object", objNull])) exitWith {};

_this call GVAR(originalArsenalInit);

if (hasInterface) then {
    // TEH-only extras. Called directly against TEH's own functions - none of
    // these open an arsenal display, so there's nothing for us to bridge, but
    // they all read jna_dataList directly (bullet-pile lookups, stock checks),
    // so each is wrapped in a sync request first - see fnc_requestDataListSync.sqf.
    if (!isNil "JN_fnc_arsenal_quickReload") then {
        _object addAction [
            format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
                "\A3\Ui_f\data\IGUI\Cfg\Actions\reload_ca.paa", "Quick resupply"],
            {[{[vehicle player] call JN_fnc_arsenal_quickReload}] call FUNC(requestDataListSync)},
            [], 15, true, false, "", "true"
        ];
    };

    if (!isNil "JN_fnc_arsenal_loadInventory") then {
        _object addAction [
            format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa", "Equip last loadout"],
            {
                [{
                    private _template = player getVariable ["lastArsenalLoadout", ""];
                    if (_template != "") then {
                        _template call JN_fnc_arsenal_loadInventory;
                    } else {
                        ["No saved loadout yet - save or load one from the arsenal first."] call BIS_fnc_error;
                    };
                }] call FUNC(requestDataListSync);
            },
            [], 6, true, false, "",
            "alive _target && {_target distance _this < 5} && {vehicle player == player}"
        ];
    };

    if (!isNil "A3A_fnc_MagConvert_open") then {
        _object addAction [
            format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
                "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\CargoMagAll_ca.paa", "Mag Service"],
            {[{[] call A3A_fnc_MagConvert_open}] call FUNC(requestDataListSync)},
            [], 6, true, false, "",
            "alive _target && {_target distance _this < 5} && {vehicle player == player}"
        ];
    };
};
