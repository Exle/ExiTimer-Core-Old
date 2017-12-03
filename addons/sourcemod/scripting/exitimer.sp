/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer.sp
 * Author: Exle / http://steamcommunity.com/profiles/76561198013509278/
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <exitimer/version>
#include <exitimer/db>
#include <exitimer/core>

#pragma semicolon 1
#pragma newdecls required

#define DIR "data/exitimer/"

bool ExiVar_Started, ExiVar_Enabled;

Handle	ExiForward_OnStart,
		ExiForward_OnEnd,
		ExiForward_OnChangeState;

#include "exitimer/map.sp"
#include "exitimer/db.sp"
#include "exitimer/configs.sp"
#include "exitimer/logging.sp"
#include "exitimer/player.sp"
#include "exitimer/functions.sp"
#include "exitimer/menu.sp"
#include "exitimer/commands.sp"

public Plugin myinfo =
{
	name		= EXITIMER_NAME ... " Core",
	author		= EXITIMER_AUTHOR,
	description	= EXITIMER_DESCRIPTION,
	version		= EXITIMER_VERSION,
	url			= EXITIMER_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ExiTimer_IsStarted",		Native_Started);
	CreateNative("ExiTimer_IsEnabled",		Native_Enabled);
	CreateNative("ExiTimer_SetState",		Native_SetState);
	CreateNative("ExiTimer_GetDirectory",	Native_GetDirectory);

	ExiConfigs_AskPluginLoad2();
	ExiDB_AskPluginLoad2();
	ExiLog_AskPluginLoad2();
	ExiMap_AskPluginLoad2();
	ExiMenu_AskPluginLoad2();
	ExiPlayer_AskPluginLoad2();

	RegPluginLibrary("exitimer");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("exitimer.phrases");
	CreateDirectories();

	RegConsoleCmd("sm_timer", ConCmd_ClientTimer);
	RegAdminCmd("sm_admintimer", ConCmd_AdminTimer, ADMFLAG_RCON);

	ExiForward_OnStart	= CreateGlobalForward("ExiTimer_OnStart",	ET_Ignore);
	ExiForward_OnEnd	= CreateGlobalForward("ExiTimer_OnEnd",		ET_Ignore);

	ExiForward_OnChangeState	= CreateGlobalForward("ExiTimer_OnChangeState",	ET_Ignore, Param_Cell);

	ExiConfigs_OnPluginStart();
	ExiDB_OnPluginStart();
	ExiMap_OnPluginStart();
	ExiMenu_OnPluginStart();
	ExiPlayer_OnPluginStart();
}

public void OnPluginEnd()
{
	delete ExiForward_OnStart;
	delete ExiForward_OnEnd;
	delete ExiForward_OnChangeState;

	ExiDB_OnPluginEnd();
	ExiMap_OnPluginEnd();
	ExiMenu_OnPluginEnd();
	ExiPlayer_OnPluginEnd();

	ExiFunctions_State(false);
}

public void OnMapStart()
{
	CreateDirectories();
	ExiMap_OnMapStart();
}

void CreateDirectories()
{
	ExiFunctions_CreateDir("");
	ExiFunctions_CreateDir("configs");
	ExiFunctions_CreateDir("logs");
}

public void OnMapEnd()
{
	ExiMap_OnMapEnd();
}

// NATIVES
public int Native_Started(Handle plugin, int numParams)
{
	return ExiVar_Started;
}

public int Native_Enabled(Handle plugin, int numParams)
{
	return ExiVar_Enabled;
}

public int Native_SetState(Handle plugin, int numParams)
{
	ExiFunctions_TimerState(view_as<bool>(GetNativeCell(1)));
}

public int Native_GetDirectory(Handle plugin, int numParams)
{
	char buffer[PLATFORM_MAX_PATH];
	GetNativeString(1, buffer, PLATFORM_MAX_PATH);
	int cells = BuildPath(Path_SM, buffer, PLATFORM_MAX_PATH, DIR ... "%s", buffer);
	SetNativeString(2, buffer, GetNativeCell(3));
	return cells;
}