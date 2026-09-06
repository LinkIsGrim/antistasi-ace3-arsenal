#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * ACEAX (ACE3 Arsenal Extended) compat - installed only if ACEAX's arsenal
 * component is actually loaded (isNil guards below), same capture-then-
 * reassign wrap pattern as the JNA hooks in XEH_postInit.sqf. Two fixes:
 *
 * 1. Suppress "weak"/partial variant matches. ACEAX's own
 * aceax_arsenal_fnc_changeCurrentConfig, on toggling one option (grip/camo/
 * etc.) of a multi-option weapon variant, first tries an EXACT match across
 * every currently-selected option (aceax_gearinfo_fnc_findConfig) and, if
 * that fails - the combination the player is trying to reach isn't itself a
 * real, fully-defined variant - silently falls back to
 * aceax_gearinfo_fnc_findConfigByValue, which the ACEAX source itself calls
 * a "weak match" (GVAR(weakMatchesCache)): the FIRST variant that merely
 * has the one just-toggled value, ignoring every other currently-selected
 * option. Confirmed via source read, not assumed - this is not a UI bug in
 * ACEAX so much as a deliberate "closest match" fallback that this addon's
 * own reconcile then can't cleanly represent (the resulting classname can
 * silently jump to a variant with attributes the player never chose),
 * producing the field-reported stuck/duplicate left-panel row. Not a
 * cosmetic issue to paper over: some variants change real stats/slots (add
 * a GL, etc.), so which combinations are valid has to stay exactly what
 * upstream's own XtdGearModels config defines - this only rejects the
 * SILENT weak-match fallback, it never invents or loosens validity itself.
 *
 * 2. Show stock counts on variant option buttons. ACEAX's own UI has no
 * concept of this addon's pool at all, so a variant's own button only ever
 * shows its label/image - only the baseline row in the main left panel gets
 * a count. Wraps aceax_arsenal_fnc_generateOptionsUI (call through first,
 * then decorate the buttons it just built) rather than
 * aceax_gearinfo_fnc_getModelOptions - that function has other, non-arsenal
 * callers (fnc_aceSelfActions.sqf's self-interaction menu, fnc_refreshCheckboxes.sqf)
 * where aceax_arsenal_currentModel/currentConfig aren't necessarily the
 * right context to resolve stock against; generateOptionsUI is exclusively
 * the arsenal display's own option-button builder.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

if (!isNil "aceax_arsenal_fnc_changeCurrentConfig") then {
    GVAR(originalAceaxChangeCurrentConfig) = aceax_arsenal_fnc_changeCurrentConfig;
    aceax_arsenal_fnc_changeCurrentConfig = {
        params ["", "_data"];
        _data params ["_optionIndex", "", "", "_valueName", ["_type", ""]];

        if (_type != "textureoptions" && {(aceax_arsenal_currentModelOptions select _optionIndex) != _valueName}) then {
            private _options = +aceax_arsenal_currentModelOptions;
            _options set [_optionIndex, _valueName];

            private _exactMatch = [aceax_arsenal_currentConfig, aceax_arsenal_currentModel, _options] call aceax_gearinfo_fnc_findConfig;
            if (isNull _exactMatch) exitWith {
                ["That combination isn't a valid variant on its own - some options can't be mixed."] call BIS_fnc_error;
            };
        };

        _this call GVAR(originalAceaxChangeCurrentConfig);
    };
};

if (!isNil "aceax_arsenal_fnc_generateOptionsUI") then {
    GVAR(originalAceaxGenerateOptionsUI) = aceax_arsenal_fnc_generateOptionsUI;
    aceax_arsenal_fnc_generateOptionsUI = {
        params ["_display"];

        _this call GVAR(originalAceaxGenerateOptionsUI);

        if (!isNil "jna_dataList") then {
            {
                private _idc = _x;
                private _data = aceax_arsenal_idcToConfig getOrDefault [_idc, []];
                if (_data isEqualTo []) then {continue};

                _data params ["_optionIndex", "", "", "_valueName", "_kind"];
                if (_kind == "textureoptions") then {continue};

                private _button = _display displayCtrl (_idc + 2);
                if (isNull _button) then {continue};

                private _options = +aceax_arsenal_currentModelOptions;
                _options set [_optionIndex, _valueName];

                private _match = [aceax_arsenal_currentConfig, aceax_arsenal_currentModel, _options] call aceax_gearinfo_fnc_findConfig;
                if (isNull _match) then {continue};

                private _stock = ((configName _match) call FUNC(poolFind)) select 1;
                private _label = ctrlText _button;
                private _tooltip = ctrlTooltip _button;

                _button ctrlSetText format ["%1 (%2)", _label, _stock];
                _button ctrlSetTooltip ([format ["%1 in stock", _stock], format ["%1\n%2 in stock", _tooltip, _stock]] select (_tooltip != ""));
            } forEach aceax_arsenal_valuesIdc;
        };
    };
};
