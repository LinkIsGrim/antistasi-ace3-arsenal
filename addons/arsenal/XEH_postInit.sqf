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

if (hasInterface) then {
    ["ace_arsenal_cargoChanged", {_this call FUNC(reconcileCargoChanged)}] call CBA_fnc_addEventHandler;

    ["ace_arsenal_displayClosed", {
        if (missionNamespace getVariable [QGVAR(loadoutMode), false]) then {
            private _own = GVAR(loadoutBackup);
            if (!isNil "_own") then {player setUnitLoadout _own};
            GVAR(loadoutBackup) = nil;
            GVAR(loadoutMode) = false;
            currentRebelLoadout = nil;
        };

        GVAR(activeBox) = objNull;
    }] call CBA_fnc_addEventHandler;
};
