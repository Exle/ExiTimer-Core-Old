/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/configs.sp
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

StringMap ExiArray_Configs;

Handle ExiForward_OnConfigLoaded;

void ExiConfigs_AskPluginLoad2()
{
	CreateNative("ExiTimer_GetConfigFile",	NativeConfigs_GetConfigFile);
	CreateNative("ExiTimer_GetConfigParam", NativeConfigs_GetConfigParam);
}

void ExiConfigs_OnPluginStart()
{
	ExiArray_Configs = new StringMap();
	ExiForward_OnConfigLoaded = CreateGlobalForward("ExiTimer_OnConfigLoaded",	ET_Ignore, Param_Cell);
	ExiConfigs_PreLoadConfiguration();
}

void ExiConfigs_PreLoadConfiguration()
{
	char buffer[PLATFORM_MAX_PATH];
	if (!ExiConfigs_GetConfigFile("core", buffer, PLATFORM_MAX_PATH) || !FileExists(buffer) || !ExiConfigs_LoadConfiguration(buffer))
	{
		ExiLog_Write(true, "[ExiConfigs] Error parse in \'%s\'", buffer);
		SetFailState("[ExiConfigs] Error parse in \'%s\'", buffer);
	}

	OnConfigLoaded();
}

int ExiConfigs_GetConfigFile(const char[] name, char[] buffer, int maxlength)
{
	return BuildPath(Path_SM, buffer, maxlength, "%sconfigs/%s.exitimer.cfg", DIR, name);
}

bool ExiConfigs_LoadConfiguration(const char[] path)
{
	SMCParser smc		= new SMCParser();
	smc.OnStart			= ExiSMC_OnStart;
	smc.OnKeyValue		= ExiSMC_OnKeyValue;

	int line, col;
	SMCError smc_error;
	if ((smc_error = smc.ParseFile(path, line, col)) != SMCError_Okay)
	{
		char error[256];
		smc.GetErrorString(smc_error, error, 256);
		ExiLog_Write(true, "[ExiConfigs] Error \'%s\' on line %d, col %d", error, line, col);
	}

	delete smc;
	return smc_error == SMCError_Okay;
}

public void ExiSMC_OnStart(SMCParser smc)
{
	ExiArray_Configs.Clear();
}

public SMCResult ExiSMC_OnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	ExiArray_Configs.SetString(key, value);
}

int ExiConfigs_GetConfigParam(const char[] key, char[] buffer, int maxlength)
{
	return ExiArray_Configs.GetString(key, buffer, maxlength);
}

// NATIVES
public int NativeConfigs_GetConfigFile(Handle plugin, int numParams)
{
	char buffer[PLATFORM_MAX_PATH];
	GetNativeString(1, buffer, PLATFORM_MAX_PATH);
	int cells = ExiConfigs_GetConfigFile(buffer, buffer, PLATFORM_MAX_PATH);
	SetNativeString(2, buffer, GetNativeCell(3));
	return cells;
}

public int NativeConfigs_GetConfigParam(Handle plugin, int numParams)
{
	char buffer[PLATFORM_MAX_PATH];
	GetNativeString(1, buffer, PLATFORM_MAX_PATH);
	int cells = ExiConfigs_GetConfigParam(buffer, buffer, PLATFORM_MAX_PATH);
	SetNativeString(2, buffer, GetNativeCell(3));
	return cells;
}