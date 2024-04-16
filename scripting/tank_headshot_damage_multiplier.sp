#include <sourcemod>
#include <sdkhooks>

#define TEAM_SURVIVOR   2
#define TEAM_INFECTED   3

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/shareddefs.h#L334-L345
#define	HITGROUP_HEAD   1

enum ZombieClass
{
    Zombie_Common = 0,
    Zombie_Smoker,
    Zombie_Boomer,
    Zombie_Hunter,
    Zombie_Spitter,
    Zombie_Jockey,
    Zombie_Charger,
    Zombie_Witch,
    Zombie_Tank,
    Zombie_Survivor,
};

ConVar survivor_tank_headshot_damage_multiplier = null;

public void OnPluginStart()
{
    survivor_tank_headshot_damage_multiplier = CreateConVar( "survivor_tank_headshot_damage_multiplier", "1.0" );

    // In case plugin is loaded late
    for ( int iClient = 1; iClient <= MaxClients; ++iClient )
    {
        if ( IsClientInGame( iClient ) )
        {
            OnClientPutInServer( iClient );
        }
    }
}

public void OnClientPutInServer( int iClient )
{
    SDKHook( iClient, SDKHook_TraceAttack, CCSPlayer_TraceAttack );
}

public void OnClientDisconnect( int iClient )
{
    SDKUnhook( iClient, SDKHook_TraceAttack, CCSPlayer_TraceAttack );
}

public Action CCSPlayer_TraceAttack( int iVictim, int &iAttacker, int &iInflictor, float &flDamage, int &fDamagetype, int &nAmmotype, int nHitbox, int nHitgroup )
{
    if ( GetClientTeam( iVictim ) != TEAM_INFECTED )
    {
        return Plugin_Continue;
    }

    if ( view_as< ZombieClass >( GetEntProp( iVictim, Prop_Send, "m_zombieClass" ) ) != Zombie_Tank )
    {
        return Plugin_Continue;
    }

    bool bIsAttackerClient = ( iAttacker > 0 && iAttacker <= MaxClients );
    if ( bIsAttackerClient && GetClientTeam( iAttacker ) == TEAM_SURVIVOR )
    {
        int iActiveWeapon = GetEntPropEnt( iAttacker, Prop_Send, "m_hActiveWeapon" );
        if ( iActiveWeapon == INVALID_ENT_REFERENCE )
        {
            return Plugin_Continue;
        }

        char szWeaponName[64];
        GetEntityClassname( iActiveWeapon, szWeaponName, sizeof( szWeaponName ) );
        if ( StrEqual( szWeaponName, "weapon_melee", false ) )
        {
            // Melee weapons already inflict a lot of damage to player zombies in general
            return Plugin_Continue;
        }

        if ( nHitgroup == HITGROUP_HEAD )
        {
            flDamage *= survivor_tank_headshot_damage_multiplier.FloatValue;
            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

public Plugin myinfo =
{
    name = "[L4D/2] Tank Headshot Damage Multiplier",
    author = "Justin \"Sir Jay\" Chellah",
    description = "Allows survivor players to inflict bonus damage for tank headshots (excluding melee weapons)",
    version = "1.0.0",
    url = "https://www.justin-chellah.com"
};