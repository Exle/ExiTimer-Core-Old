/**
 * =============================================================================
 * [ExiTimer] Core
 * Timer for source engine games.
 *
 * File: exitimer/db.sp
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

#define TABLE_MAP_MYSQL		"CREATE TABLE IF NOT EXISTS %smaps (id int(8) NOT NULL AUTO_INCREMENT, name varchar(64) NOT NULL UNIQUE, state bit NOT NULL DEFAULT 1, PRIMARY KEY (id), UNIQUE KEY (name)) ENGINE=MyISAM DEFAULT CHARSET=utf8;"
#define TABLE_MAP_SQLITE	"CREATE TABLE IF NOT EXISTS %smaps (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name VARCHAR NOT NULL UNIQUE, state BIT NOT NULL DEFAULT 1);"

Database ExiDB;
ExiTimerDB_Type ExiDB_Type;
char ExiVar_DBPrefix[16] = "et_";

Handle	ExiForward_OnDBReConnect;

void ExiDB_AskPluginLoad2()
{
	CreateNative("ExiTimer_GetDatabase",		NativeDB_GetDatabase);
	CreateNative("ExiTimer_GetDatabaseType",	NativeDB_GetDatabaseType);
	CreateNative("ExiTimer_GetDatabasePrefix",	NativeDB_GetDatabasePrefix);
}

void ExiDB_OnPluginStart()
{
	ExiForward_OnDBReConnect = CreateGlobalForward("ExiTimer_OnDBReConnect", ET_Ignore);
	ExiDB_PreConnect();
}

void ExiDB_OnPluginEnd()
{
	delete ExiForward_OnDBReConnect;
}

void ExiDB_PreConnect()
{
	if (ExiDB != null)
	{
		return;
	}

	if (SQL_CheckConfig("exitimer"))
	{
		Database.Connect(ExiDB_Connect, "exitimer", 40613);
	}
	else
	{
		char error[256];
		ExiDB_Connect((ExiDB = SQLite_UseDatabase("exitimer", error, 256)), error, 40613);
	}
}

public void ExiDB_Connect(Database db, const char[] error, any data)
{
	ExiDB = db;

	if (ExiDB == null || error[0])
	{
		ExiDB_PreReconnectTimer(data, error[0] ? error : "Database INVALID HANDLE");
		return;
	}

	ExiDB_GetType();
	ExiDB.SetCharset("utf8");
	ExiDB_CreateTables(ExiDB);
}

void ExiDB_PreReconnectTimer(any data, const char[] error)
{
	ExiFunctions_State(false);
	CreateTimer(10.0, ExiDB_ReconnectTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	LogError("[DB] Error [data %d]: %s", data, error);
	ExiLog_Write(true, "[DB] Error [data %d]: %s", data, error);
}

public Action ExiDB_ReconnectTimer(Handle timer)
{
	if (ExiDB == null)
	{
		Call_StartForward(ExiForward_OnDBReConnect);
		Call_Finish();

		ExiDB_PreConnect();
	}

	return Plugin_Stop;
}

void ExiDB_GetType()
{
	char ident[16];
	ExiDB.Driver.GetIdentifier(ident, 16);

	switch (ident[0])
	{
		case 'm': ExiDB_Type = ExiTimerDB_MySQL;
		case 's': ExiDB_Type = ExiTimerDB_SQLite;
		default: SetFailState("[DB] Error: Driver \'%s\' is not supported", ident);
	}
}

void ExiDB_CreateTables(Database db)
{
	char query[256];
	FormatEx(query, 256, ExiDB_Type == ExiTimerDB_MySQL ? TABLE_MAP_MYSQL : TABLE_MAP_SQLITE, ExiVar_DBPrefix);
	db.Query(ExiDB_CreateTablesCallback, query, 1, DBPrio_High);
}

public void ExiDB_CreateTablesCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (ExiDB == null || error[0])
	{
		ExiDB_PreReconnectTimer(data, error[0] ? error : "Database INVALID HANDLE");
		return;
	}

	Handle ExiVar_MyHandle = GetMyHandle();
	Handle ExiVar_Iterator = GetPluginIterator();
	Handle ExiVar_Plugin;
	Function ExiVar_Function;

	while (MorePlugins(ExiVar_Iterator))
	{
		if ((ExiVar_Plugin = ReadPlugin(ExiVar_Iterator)) != null && ExiVar_Plugin != ExiVar_MyHandle && GetPluginStatus(ExiVar_Plugin) == Plugin_Running && (ExiVar_Function = GetFunctionByName(ExiVar_Plugin, "ExiTimer_OnDBConnected")) != INVALID_FUNCTION)
		{
			Call_StartFunction(ExiVar_Plugin, ExiVar_Function);
			Call_PushCell(CloneHandle(ExiDB, ExiVar_Plugin));
			Call_PushCell(ExiDB_Type);
			Call_Finish();
		}
	}

	delete ExiVar_Iterator;

	ExiFunctions_State();
}

void ExiDB_OnMapStart()
{
	if (ExiDB == null)
	{
		ExiDB_PreReconnectTimer(0, "Database INVALID HANDLE");
		return;
	}

	int tmp = 2 * strlen(ExiVar_MapName) + 1;
	char[] smap = new char[tmp];
	ExiDB.Escape(ExiVar_MapName, smap, tmp);

	char query[256];
	FormatEx(query, 256, "SELECT id, state FROM %smaps WHERE name = '%s';", ExiVar_DBPrefix, smap);

	ExiDB.Query(ExiDB_OnMapStartCallback, query);
}

public void ExiDB_OnMapStartCallback(Database db, DBResultSet results, const char[] error, any param)
{
	if (results.HasResults && results.FetchRow())
	{
		ExiVar_MapId = results.FetchInt(0);
		ExiFunctions_TimerState(view_as<bool>(results.FetchInt(1)));
		ExiFunctions_MapState();
	}
	else
	{
		char query[256];

		FormatEx(query, 256, "INSERT INTO %smaps (name) VALUES ('%s');", ExiVar_DBPrefix, ExiVar_MapName);
		db.Query(ExiDB_OnMapStartInsertCallback, query);
	}
}

public void ExiDB_OnMapStartInsertCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || error[0])
	{
		if (db == null)
		{
			ExiDB_PreReconnectTimer(0, "Database INVALID HANDLE");
			return;
		}

		LogError("[DB] Error [data %d]: %s", data, error);
		ExiLog_Write(true, "[DB] Error [data %d]: %s", data, error);
		return;
	}

	ExiDB_OnMapStart();
}

void ExiDB_ChangeState(bool state)
{
	char query[256];
	FormatEx(query, 256, "UPDATE %smaps SET state = %d WHERE id = %d;", ExiVar_DBPrefix, state, ExiVar_MapId);
	ExiDB_TQueryEx(query);
}

stock void ExiDB_TQueryEx(const char[] query, DBPriority prio = DBPrio_Normal, any data = 0)
{
	if (ExiDB == null)
	{
		ExiDB_PreReconnectTimer(data, "Database INVALID HANDLE");
		return;
	}

	ExiDB.Query(ExiDB_ErrorCheck, query, data, prio);
}

public void ExiDB_ErrorCheck(Database db, DBResultSet results, const char[] error, any data)
{
	if (ExiDB == null || error[0])
	{
		ExiDB_PreReconnectTimer(data, error[0] ? error : "Database INVALID HANDLE");
	}
}

// NATIVES
public int NativeDB_GetDatabase(Handle plugin, int numParams)
{
	return view_as<int>(CloneHandle(ExiDB, plugin));
}

public int NativeDB_GetDatabaseType(Handle plugin, int numParams)
{
	return view_as<int>(ExiDB_Type);
}

public int NativeDB_GetDatabasePrefix(Handle plugin, int numParams)
{
	SetNativeString(1, ExiVar_DBPrefix, GetNativeCell(2));
	return strlen(ExiVar_DBPrefix);
}