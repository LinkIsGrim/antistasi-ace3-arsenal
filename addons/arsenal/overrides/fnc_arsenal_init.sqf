#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Replaces JN_fnc_arsenal_init (assigned in XEH_postInit.sqf). Antistasi
 * (CE/Ultimate/TEH) calls this from both fn_initServer.sqf and
 * fn_initClient.sqf with the arsenal box object.
 *
 * Doesn't touch jn_fnc_arsenal (JNA's own BIS-arsenal-skinned display) for
 * the personal "Arsenal" action - that one goes straight through
 * ace_arsenal_fnc_openBox instead.
 *
 * "Open Container" is different: ACE arsenal's per-person data model can't
 * represent a container's stackable cargo at all (confirmed twice over,
 * design-outline.md section 5 - a bespoke transfer dialog was built and
 * later dropped again, see below), so this defers to Ultimate/TEH's own
 * native container-arsenal action instead (jn_fnc_common_addActionSelect ->
 * jn_fnc_arsenal_requestOpen, opening JNA's own vanilla BIS-skinned arsenal
 * directly against the selected container) until ACE itself supports a
 * non-infantry arsenal center. CE has no such native action to defer to at
 * all (its own stock fn_arsenal_init.sqf only ever adds the "Arsenal"
 * action) - not added there, matching CE's own baseline rather than
 * regressing from it.
 *
 * That means jn_fnc_vehicleArsenal (the vanilla skin actually applied to a
 * container arsenal) needs JNA's own arsenalOpened/arsenalClosed scripted
 * event dispatch to run its CustomInit/Close - registered below, but
 * deliberately scoped to only the "containerArsenal" jn_type this file's
 * own action sets. Stock JNA's own handler also has a default branch that
 * skins ANY arsenal display with jn_type unset - which is every ACE-based
 * open this addon does (personal arsenal, rebel loadouts), none of which
 * set jn_type either. Restoring that branch verbatim would wrongly run
 * JNA's own vanilla-skin init against an ACE Arsenal display.
 *
 * Arguments:
 * 0: Arsenal box object <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_object", objNull, [objNull]]];

// Idempotent - matches JNA's own init, which guards the same way.
if (!isNull (missionNamespace getVariable ["jna_object", objNull])) exitWith {};
if (isNull _object) exitWith {
    ["Antistasi ACE3 Arsenal: init got a null object"] call BIS_fnc_error;
};

missionNamespace setVariable ["jna_object", _object];

// Kept for compatibility with other JNA code that still reads this (trader/guest
// limit coloring in JNA's own skin) even though our own flow doesn't use it.
private _limit = missionNamespace getVariable ["A3A_guestItemLimit", 0];
jna_minItemMember = [];
for "_i" from 0 to (JNA_TAB_COUNT_BASE - 1) do {jna_minItemMember pushBack _limit};
jna_minItemMember set [JNA_TAB_CARGOMAG, _limit * 3];
jna_minItemMember set [JNA_TAB_CARGOMAGALL, _limit * 3];

// Populates bis_fnc_arsenal_data, which jn_fnc_arsenal_itemType falls back to
// for classnames it can't classify by config type alone. Still needed even
// though we never open JNA's own skin.
["Preload"] call jn_fnc_arsenal;

if (isServer && {isNil "jna_dataList"}) then {
    jna_dataList = [];
    // TEH's own fn_initServer.sqf independently extends this to 28 tabs
    // (bullet-pile migration) after this runs, regardless of which
    // JN_fnc_arsenal_init implementation is active - safe to always start
    // at the CE/Ultimate baseline here.
    for "_i" from 0 to (JNA_TAB_COUNT_BASE - 1) do {jna_dataList pushBack []};
};

if (hasInterface) then {
    _object addAction [
        format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
            "\A3\ui_f\data\GUI\Rsc\RscDisplayArsenal\spaceArsenal_ca.paa",
            localize "STR_A3_Arsenal"],
        {[] call JN_fnc_arsenal_handleAction},
        [],
        6, true, false, "",
        "alive _target && {_target distance _this < 5} && {vehicle player == player}"
    ];

    // No CE equivalent to defer to - see this file's header.
    if !([] call FUNC(isCE)) then {
        _object addAction [
            format ["<img image='%1' size='1.6' shadow=2/><t size='1'> %2</t>",
                "\A3\ui_f\data\GUI\Rsc\RscDisplayArsenal\cargoMag_ca.paa",
                localize "STR_JNA_ACT_CONTAINER_OPEN"],
            {
                private _object = _this select 0;

                private _script = {
                    params ["_object"];

                    private _objectSelected = cursorObject;
                    if (isNull _objectSelected) exitWith {hint localize "STR_JNA_ACT_CONTAINER_SELECTERROR1";};

                    if (_object distance cursorObject > 50) exitWith {hint localize "STR_JNA_ACT_CONTAINER_SELECTERROR2";};

                    private _className = typeOf _objectSelected;
                    private _tb = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxbackpacks");
                    private _tm = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxmagazines");
                    private _tw = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxweapons");
                    if !(_tb > 0 || _tm > 0 || _tw > 0) exitWith {hint localize "STR_JNA_ACT_CONTAINER_SELECTERROR3";};

                    uiNamespace setVariable ["jn_type", "containerArsenal"];
                    uiNamespace setVariable ["jn_object", _object];
                    uiNamespace setVariable ["jn_object_selected", _objectSelected];

                    ["jn_fnc_arsenal", "Loading Nutz™ Arsenal"] call BIS_fnc_startLoadingScreen;
                    [] spawn {
                        uiSleep 5;
                        private _ids = missionNamespace getVariable ["BIS_fnc_startLoadingScreen_ids", []];
                        if ("jn_fnc_arsenal" in _ids) then {
                            private _display = uiNamespace getVariable ["arsenalDisplay", "No display"];
                            titleText ["ERROR DURING LOADING ARSENAL", "PLAIN"];
                            _display closeDisplay 2;
                            ["jn_fnc_arsenal"] call BIS_fnc_endLoadingScreen;
                        };
                    };

                    [clientOwner] remoteExecCall ["jn_fnc_arsenal_requestOpen", 2];
                };
                private _conditionActive = {
                    params ["_object"];
                    alive player;
                };
                private _conditionColor = {
                    params ["_object"];
                    !isNull cursorObject
                    && {_object distance cursorObject < 10}
                    && {
                        private _className = typeOf cursorObject;
                        private _tb = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxbackpacks");
                        private _tm = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxmagazines");
                        private _tw = getNumber (configFile >> "CfgVehicles" >> _className >> "transportmaxweapons");
                        _tb > 0 || _tm > 0 || _tw > 0
                    }
                };

                [localize "STR_A3AP_vehArsenal_header", localize "STR_A3AP_vehArsenal_desc"] call A3A_fnc_customHint;
                [_script, _conditionActive, _conditionColor, _object] call jn_fnc_common_addActionSelect;
            },
            [],
            6, true, false, "",
            "alive _target && {_target distance _this < 5} && {vehicle player == player}"
        ];

        // jn_fnc_vehicleArsenal (the vanilla skin the container action above
        // actually applies) needs these to run its CustomInit/Close - see this
        // file's header for why this is scoped to jn_type == "containerArsenal"
        // only, not restoring JNA's own default-case dispatch.
        [missionNamespace, "arsenalOpened", {
            disableSerialization;
            uiNamespace setVariable ["arsenalDisplay", (_this select 0)];

            [] spawn {
                disableSerialization;
                if ((uiNamespace getVariable ["jn_type", ""]) isEqualTo "containerArsenal") then {
                    ["CustomInit", [uiNamespace getVariable "arsenalDisplay"]] call jn_fnc_vehicleArsenal;
                };
            };
        }] call BIS_fnc_addScriptedEventHandler;

        [missionNamespace, "arsenalClosed", {
            if ((uiNamespace getVariable ["jn_type", ""]) isEqualTo "containerArsenal") then {
                ["Close"] call jn_fnc_vehicleArsenal;
                [clientOwner] remoteExecCall ["jn_fnc_arsenal_requestClose", 2];
                uiNamespace setVariable ["jn_type", ""];
            };
        }] call BIS_fnc_addScriptedEventHandler;
    };

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

arsenalInit = true;
