/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/player.sp
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

enum Player
{
	Float:Player_Time,
	Float:Player_Pause
};

any player[MAXPLAYERS + 1][Player];

Handle	ExiForward_OnClientStarted,
		ExiForward_OnClientPreFinished,
		ExiForward_OnClientFinished,
		ExiForward_OnClientPaused,
		ExiForward_OnClientUnPaused;

void ExiPlayer_AskPluginLoad2()
{
	CreateNative("ExiTimer_StartTimer",		NativePlayer_StartTimer);
	CreateNative("ExiTimer_StopTimer",		NativePlayer_StopTimer);
	CreateNative("ExiTimer_PauseTimer",		NativePlayer_PauseTimer);
	CreateNative("ExiTimer_UnPauseTimer",	NativePlayer_UnPauseTimer);
}

void ExiPlayer_OnPluginStart()
{
	ExiForward_OnClientStarted		= CreateGlobalForward("ExiTimer_OnClientStarted",		ET_Ignore,	Param_Cell, Param_Float);
	ExiForward_OnClientPreFinished	= CreateGlobalForward("ExiTimer_OnClientPreFinished",	ET_Event,	Param_Cell, Param_FloatByRef);
	ExiForward_OnClientFinished		= CreateGlobalForward("ExiTimer_OnClientFinished",		ET_Ignore,	Param_Cell, Param_Float);
	ExiForward_OnClientPaused		= CreateGlobalForward("ExiTimer_OnClientPaused",		ET_Ignore,	Param_Cell, Param_Float);
	ExiForward_OnClientUnPaused		= CreateGlobalForward("ExiTimer_OnClientUnPaused",		ET_Ignore,	Param_Cell, Param_Float, Param_Float);
}

void ExiPlayer_OnPluginEnd()
{
	delete ExiForward_OnClientStarted;
	delete ExiForward_OnClientPreFinished;
	delete ExiForward_OnClientFinished;
	delete ExiForward_OnClientPaused;
	delete ExiForward_OnClientUnPaused;
}

public void OnClientPutInServer(int client)
{
	player[client][Player_Time] = player[client][Player_Pause] = -1.0;
}

void ExiPlayer_StartTimer(int client)
{
	player[client][Player_Time] = GetEngineTime();

	Call_StartForward(ExiForward_OnClientStarted);
	Call_PushCell(client);
	Call_PushFloat(player[client][Player_Time]);
	Call_Finish();
}

float ExiPlayer_StopTimer(int client, bool finished = true)
{
	if (player[client][Player_Time] == -1.0 || player[client][Player_Pause] != -1.0)
	{
		return -1.0;
	}

	float time = GetEngineTime() - player[client][Player_Time], new_time = time;
	player[client][Player_Time] = -1.0;

	if (finished)
	{
		Action result;
		Call_StartForward(ExiForward_OnClientPreFinished);
		Call_PushCell(client);
		Call_PushFloatRef(new_time);
		int error = Call_Finish(result);

		if (error != SP_ERROR_NONE || result == Plugin_Stop || result == Plugin_Handled)
		{
			return -1.0;
		}
		else if (result == Plugin_Changed)
		{
			time = new_time;
		}

		Call_StartForward(ExiForward_OnClientFinished);
		Call_PushCell(client);
		Call_PushFloat(time);
		Call_Finish();
	}

	return time;
}

void ExiPlayer_PauseTimer(int client)
{
	if (player[client][Player_Pause] != -1.0)
	{
		ExiPlayer_UnPauseTimer(client);
	}

	player[client][Player_Pause] = GetEngineTime();

	Call_StartForward(ExiForward_OnClientPaused);
	Call_PushCell(client);
	Call_PushFloat(player[client][Player_Pause]);
	Call_Finish();
}

void ExiPlayer_UnPauseTimer(int client)
{
	if (player[client][Player_Time] == -1.0)
	{
		return;
	}

	float time = GetEngineTime();

	player[client][Player_Time] += time - player[client][Player_Pause];

	Call_StartForward(ExiForward_OnClientUnPaused);
	Call_PushCell(client);
	Call_PushFloat(time - player[client][Player_Pause]);
	Call_PushFloat(time);
	Call_Finish();

	player[client][Player_Pause] = -1.0;
}

// NATIVES
public int NativePlayer_StartTimer(Handle plugin, int numParams)
{
	ExiPlayer_StartTimer(GetNativeCell(1));
}

public int NativePlayer_StopTimer(Handle plugin, int numParams)
{
	return view_as<int>(ExiPlayer_StopTimer(GetNativeCell(1), view_as<bool>(GetNativeCell(2))));
}

public int NativePlayer_PauseTimer(Handle plugin, int numParams)
{
	ExiPlayer_PauseTimer(GetNativeCell(1));
}

public int NativePlayer_UnPauseTimer(Handle plugin, int numParams)
{
	ExiPlayer_UnPauseTimer(GetNativeCell(1));
}