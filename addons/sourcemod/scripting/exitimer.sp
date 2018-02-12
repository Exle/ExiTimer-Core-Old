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

#define DIR "data/exitimer"

bool ExiVar_Started, ExiVar_Enabled;

char ExiVar_ChatPrefix[64] = "\x03[\x04ExiTimer\x03]\x01";

Handle	ExiForward_OnStart,
		ExiForward_OnEnd,
		ExiForward_OnChangeState;

EngineVersion ExiVar_Engine;

#include "exitimer/chat.sp"
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
	version		= EXITIMER_VERSION ... "-beta",
	url			= EXITIMER_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ExiTimer_IsStarted",	Native_Started);
	CreateNative("ExiTimer_IsEnabled",	Native_Enabled);
	CreateNative("ExiTimer_SetState",	Native_SetState);
	CreateNative("ExiTimer_GetPath",	Native_GetPath);

	ExiConfigs_AskPluginLoad2();
	ExiDB_AskPluginLoad2();
	ExiLog_AskPluginLoad2();
	ExiMap_AskPluginLoad2();
	ExiMenu_AskPluginLoad2();
	ExiPlayer_AskPluginLoad2();
	ExiChat_AskPluginLoad2();

	RegPluginLibrary("exitimer");

	ExiVar_Engine = GetEngineVersion();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("exitimer.phrases");
	CreateDirectories();

	ExiForward_OnStart	= CreateGlobalForward("ExiTimer_OnStart",	ET_Ignore);
	ExiForward_OnEnd	= CreateGlobalForward("ExiTimer_OnEnd",		ET_Ignore);

	ExiForward_OnChangeState	= CreateGlobalForward("ExiTimer_OnChangeState",	ET_Ignore, Param_Cell);

	ExiConfigs_OnPluginStart();
	ExiDB_OnPluginStart();
	ExiMap_OnPluginStart();
	ExiMenu_OnPluginStart();
	ExiPlayer_OnPluginStart();
	ExiChat_OnPluginStart();
}

public void OnPluginEnd()
{
	// Notify plugins about the end of the plug-in
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
	ExiFunctions_CreateDir("/configs");
	ExiFunctions_CreateDir("/logs");
}

public void OnMapEnd()
{
	ExiMap_OnMapEnd();
}

//-----------------------------------------------------------------------------
// Function for registration cmd
//-----------------------------------------------------------------------------
void OnConfigLoaded()
{
	{
		ArrayList cmd = new ArrayList(ByteCountToCells(64));
		char buffer[256];
		if (ExiConfigs_GetConfigParam("clientmenu_cmd", buffer, 256) && buffer[0])
		{
			for (int i, length = ExplodeStringArray(cmd, buffer, ';'); i < length; ++i)
			{
				cmd.GetString(i, buffer, 256);
				RegConsoleCmd(buffer, ConCmd_ClientTimer);
			}
		}

		if (ExiConfigs_GetConfigParam("adminmenu_flag", buffer, 256) && buffer[0])
		{
			int flags = ReadFlagString(buffer);
			ExiConfigs_GetConfigParam("adminmenu_cmd", buffer, 256);
			for (int i, length = ExplodeStringArray(cmd, buffer, ';'); i < length; ++i)
			{
				cmd.GetString(i, buffer, 256);
				RegAdminCmd(buffer, ConCmd_AdminTimer, flags);
			}
			
		}

		delete cmd;
	}

	Call_StartForward(ExiForward_OnConfigLoaded);
	Call_PushCell(ExiArray_Configs.Size);
	Call_Finish();
}

public int GetPath(const char[] path, char[] buffer, int maxlength)
{
	return BuildPath(Path_SM, buffer, maxlength, DIR ... "%s%s", path[0] == '/' ? "" : "/", path);
}

//-----------------------------------------------------------------------------
// Helper: Breaks a string into pieces and stores each piece into an arraylist
//-----------------------------------------------------------------------------
int ExplodeStringArray(ArrayList &array, char[] string, int c)
{
	array.Clear();

	int count = CountCharInString(string, c) + 1;
	char[][] part = new char[count][64];

	count = ExplodeString(string, ";", part, count, 64);
	for (int i; i < count; ++i)
	{
		array.PushString(part[i]);
	}

	return count;
}

//-----------------------------------------------------------------------------
// Helper: Counting char int string
//-----------------------------------------------------------------------------
int CountCharInString(const char[] string, int c)
{
	int count;
	for (int i; i < strlen(string); ++i)
	{
		if (string[i] == c)
		{
			count++;
		}
	}

    return count;
}


//-----------------------------------------------------------------------------
// NATIVES
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Native: bool ExiTimer_IsStarted();
//-----------------------------------------------------------------------------
public int Native_Started(Handle plugin, int numParams)
{
	return ExiVar_Started;
}

//-----------------------------------------------------------------------------
// Native: bool ExiTimer_IsEnabled();
//-----------------------------------------------------------------------------
public int Native_Enabled(Handle plugin, int numParams)
{
	return ExiVar_Enabled;
}

//-----------------------------------------------------------------------------
// Native: void ExiTimer_SetState(bool state);
//-----------------------------------------------------------------------------
public int Native_SetState(Handle plugin, int numParams)
{
	ExiFunctions_TimerState(view_as<bool>(GetNativeCell(1)));
}

//-----------------------------------------------------------------------------
// Native: int ExiTimer_GetPath(const char[] name, char[] buffer, int maxlength);
//-----------------------------------------------------------------------------
public int Native_GetPath(Handle plugin, int numParams)
{
	int length = GetNativeCell(3), cells;
	char[] buffer = new char[length];
	GetNativeString(1, buffer, length);
	cells = GetPath(buffer, buffer, length);
	SetNativeString(2, buffer, length);
	return cells;
}