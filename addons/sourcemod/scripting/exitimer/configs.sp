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

void ExiConfigs_AskPluginLoad2()
{
	CreateNative("ExiTimer_GetConfigFile",	NativeConfigs_GetConfigFile);
}

void ExiConfigs_OnPluginStart()
{
	char buffer[PLATFORM_MAX_PATH];
	if (!ExiConfigs_GetConfigFile("core", buffer, PLATFORM_MAX_PATH) || !FileExists(buffer) || !ExiConfigs_LoadConfiguration(buffer))
	{
		ExiLog_Write(true, "[ExiConfigs] Error parse in \'%s\'", buffer);
		SetFailState("[ExiConfigs] Error parse in \'%s\'", buffer);
	}
}

int ExiConfigs_GetConfigFile(const char[] name, char[] buffer, int maxlength)
{
	return BuildPath(Path_SM, buffer, maxlength, "%sconfigs/%s.exitimer.cfg", DIR, name);
}

bool ExiConfigs_LoadConfiguration(const char[] buffer)
{
	SMCParser parser = new SMCParser();
	parser.OnKeyValue	= ExiConfigs_ParserOnKeyValue;
	parser.OnEnd		= ExiConfigs_ParserOnEnd;

	int line, column;
	SMCError results = parser.ParseFile(buffer, line, column);

	if (results != SMCError_Okay) 
	{
		char error[256];
		parser.GetErrorString(results, error, 256);
		ExiLog_Write(true, "[ExiConfigs] Error: %s on line %d, column %d in \'%s\'", error, line, column, buffer);
		LogError("[ExiConfigs] Error: %s on line %d, column %d in \'%s\'", error, line, column, buffer);
	}

	delete parser;
	return (results == SMCError_Okay);
}

public SMCResult ExiConfigs_ParserOnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (!strcmp(key, "db_prefix", false))
	{
		strcopy(ExiVar_DBPrefix, 16, value);
	}

	return SMCParse_Continue;
}

public void ExiConfigs_ParserOnEnd(SMCParser smc, bool halted, bool failed)
{
	if (failed)
	{
		ExiLog_Write(true, "[ExiConfigs] Error parse configuration file");
		SetFailState("[ExiConfigs] Error parse configuration file");
	}
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