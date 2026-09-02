class Extended_PreStart_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_preStart));
    };
};

class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_FILE(XEH_preInit));
    };
};

class Extended_PostInit_EventHandlers {
    class ADDON {
        // Runs on server AND client - JN_fnc_arsenal_init is called from both
        // fn_initServer.sqf and fn_initClient.sqf, so our override needs to be
        // in place on both before Antistasi's own init scripts run.
        init = QUOTE(call COMPILE_FILE(XEH_postInit));
    };
};
