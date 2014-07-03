package swag.core.instances {

	/**
	 * 
	 * Used to create and manage a single SQLite database instance within an AIR application. Typically the database will be stored on disk in
	 * a file but a memory-based database is also supported directly.
	 * 
	 * Each SQLiteDatabase instance is intended to handle one query at a time. To provide multiple concurrent access to the same database a "useStatic"
	 * property is provided in the constructor and <code>openDatabaseFile</code> methods. If TRUE, a static (or shared) connection is established for any SQLiteDatabase
	 * instances using the same file name. For example, to use a single file named "myDatabase.sqlite" with three concurent queries, use:
	 * 
	 * 	var db1:SQLiteDatabase=new SQLiteDatabase("myDatabase.sqlite", true);
	 * 	var db2:SQLiteDatabase=new SQLiteDatabase("myDatabase.sqlite", true);
	 * 	var db3:SQLiteDatabase=new SQLiteDatabase("myDatabase.sqlite", true);
	 * 
	 * Because the "useStatic" parameter is true, and the database file name is the same for all three instances, they will all use a single shared connection.
	 * Although the order of instantiation isn't important, in this example db1 will actually create or open the database file while db2 and db3 will us the established
	 * connection.
	 * 
	 * By using non-static connections, each SQLiteDatabase instance establishes its own file connection, potentially slowing down access.
	 * 
	 * Alternately, connections may be shared between SQLiteDatabase instances by assigning the "instance" property like this: 
	 * 
	 *	var db1:SQLiteDatabase=new SQLiteDatabase("myDatabase.sqlite", false); //Non-static
	 * 	var db2:SQLiteDatabase=new SQLiteDatabase(); //Don't establish a connection, instead assign it below
	 * 	db2.connection=db1.connection;
	 * 	var db3:SQLiteDatabase=new SQLiteDatabase(); //Use connection from db2 or db1
	 * 	db3.connection=db2.connection;
	 * 
	 * Most database interactions will broadcast one of two standard SwAG events:
	 * 
	 * 	SQLiteDatabaseEvent -- When a query is successfully executed on the database (may also return a result if applicable).
	 * 	SwagErrorEvent -- When an error is received from any standard or prepared query.	 
	 * 
	 * Because there is currently no similar functionality in the web player, this class can only be used in AIR within the AIR runtime.
	 *
	 * @author Patrick Bay
	 * 
	 * The MIT License (MIT)
	 * 
	 * Copyright (c) 2014 Patrick Bay
	 * 
	 * Permission is hereby granted, free of charge, to any person obtaining a copy
	 * of this software and associated documentation files (the "Software"), to deal
	 * in the Software without restriction, including without limitation the rights
	 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	 * copies of the Software, and to permit persons to whom the Software is
	 * furnished to do so, subject to the following conditions:
	 * 
	 * The above copyright notice and this permission notice shall be included in
	 * all copies or substantial portions of the Software.
	 * 
	 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	 * THE SOFTWARE.
	 */	
	
	import flash.data.*;
	import flash.errors.SQLError;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.*;
	
	import swag.core.SwagDispatcher;
	import swag.events.SQLiteDatabaseEvent;
	import swag.events.SwagErrorEvent;

	public dynamic class SQLiteDatabase {		
				
		private static var _staticConnections:Array=new Array();
						
		private var _dbFileName:String = new String();
		private var _dbFile:File = null;
		private var _useStatic:Boolean=new Boolean(false);
		private var _dbConnection:SQLConnection = null;
		private var _query:SQLStatement=null;
		private var _lastResult:SQLResult=null;
		
			
		/**
		 * 
		 * The constructor method for the class.
		 * 
		 * @param file The file to use for the database (either existing or new). If this is a <code>File</code> reference, it will
		 * 			be used as is. If this is a <code>String</code>, it will be resolved to the application storage directory.
		 * @param useStatic If TRUE, only one database connection is established for all instances or SQLiteDatabase per file name.
		 * 			This is useful if multiple queries need to be executed simultaneously on a single database. Static connections are shared between
		 * 			SQLiteDatabase instances via a named array (using the file name), so only one instance is ever created if the file name supplied
		 * 			is the same (and useStatic is TRUE). If no such connection yet exists, one will be created. If static connections are not used, 
		 * 			individual connections to database files are created per instance, even if the file name is the same.
		 * 
		 * @return A reference to the newly created class instance.		 
		 */
		public function SQLiteDatabase(file:*=null, useStatic:Boolean=false) {
			if (file is File) {
				this._dbFile=file;
			} else if (file is String) {
				this._dbFile=File.applicationStorageDirectory.resolvePath(file);
			} else {
				this._dbFile=null;
			}//else
			this._useStatic=useStatic;
			if (this._dbFile!=null) {
				this.openDatabaseFile(this._dbFile, this._useStatic);
			}//if
		}//constructor
		
		/**
		 * 		
		 * Opens or creates a SQLLite database file (if none exists) in the application storage directory. If a connection isn't extablished,
		 * it may alternately be assigned from another existing one using the SQLiteDatabase.connection property.
		 * 
		 * @param file The file to use for the database (either existing or new). If this is a <code>File</code> reference, it will
		 * 			be used as is. If this is a <code>String</code>, it will be resolved to the application storage directory.
		 * @param useStatic If TRUE, only one database connection is established for all instances or SQLiteDatabase per file name.
		 * 			This is useful if multiple queries need to be executed simultaneously on a single database. Static connections are shared between
		 * 			SQLiteDatabase instances via a named array (using the file name), so only one instance is ever created if the file name supplied
		 * 			is the same (and useStatic is TRUE). If no such connection yet exists, one will be created. If static connections are not used, 
		 * 			individual connections to database files are created per instance, even if the file name is the same. 
		 * 
		 * @return TRUE if the database file was successfully created or opened, FALSE otherwise.		 
		 */
		public function openDatabaseFile(file:* = null, useStatic:Boolean=false):Boolean {
			if (file==null) {
				return (false);
			}//if		
			if (file is File) {
				this._dbFile=file;
			} else if (file is String) {
				this._dbFile=File.applicationStorageDirectory.resolvePath(file);
			} else {
				return (false);
			}//else			
			//Note that we use the this._dbConnection property for simpler access in all methods
			if (useStatic) {
				if ((_staticConnections[this._dbFile.nativePath]==null) || (_staticConnections[this._dbFile.nativePath]==undefined))  {
					_staticConnections[this._dbFile.nativePath]=new SQLConnection();
				}//if
				this._dbConnection = _staticConnections[this._dbFile.nativePath] as SQLConnection;
			} else {
				this._dbConnection = new SQLConnection();
			}//else			
			this._dbConnection.open(this._dbFile);
			return (true);
		}//openDatabaseFile
		
		/**	
		 * 	 
		 * Returns TRUE if the specified database file exists (it may not necessarily contain any data).
		 * 
		 * @param fileName The database file name (stored in the application directory) to verify.
		 * 		 
		 * @return TRUE if the file exists (may be empty!), FALSE otherwise.
		 * 		 
		 */
		public static function databaseExists(fileName:String=null):Boolean {
			var fileObject:File = File.applicationStorageDirectory.resolvePath(fileName);
			if (fileObject.exists) {
				return (true);
			} else {
				return (false);
			}//else
			return (false);
		}//databaseExists
		
		/**
		 * 		 
		 * Creates a table on the open database (database must be open first). This is a simple way to create a table
		 * with an optional auto-incrementing primary key. For more complex table structures a custom query must be
		 * called via <executeQuery>.
		 * The query used for this command includes the "IF NOT EXISTS" clause so that if the table already exists in
		 * the database, it is not created.
		 * 		 
		 * @param tableName The name of the table to create. This is case-sensitive.
		 * @param fields A named array of name/value pairs to create the table fields with.
		 * 	The format for the array is tableParams[field_name]="field_type"; 
		 * 	For example, to create a table with fields "field1" and "field2", with types VARCHAR
		 * 	and BLOB respectively: 
		 * 		fields["field1"]="VARCHAR"; 
		 * 		fields["field2"]="BLOB";
		 * 	Field defaults are assigned through extended array elements:
		 * 		fields["field1"]="CHAR(50) DEFAULT \"test\"";
		 * @param primaryKey If an auto-incrementing primary key field is desired in the table, include the name
		 * 	of the field here. The primary key field will be created before any other fields and typed
		 * 	as a non-null INT. An alternate way to include the primary key is to include it in the fields array:
		 * 		fields["primaryKeyField"]="INTEGER AUTOINCREMENT PRIMARY KEY NOT NULL ASC";
		 * 		 
		 * @param The result of the operation in a <code>SQLResult</code> object, or <em>null</em> if there was a problem
		 * with the parameters of te operation.
		 * 		 
		 */
		public function createTable(tableName:String=null, fields:Array=null, primaryKey:String=null):SQLResult {
			if ((tableName==null) || (tableName=="")) {
				var errorEvent:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.DATAEMPTYERROR);
				errorEvent.description="Table name cannot be empty or null";
				errorEvent.remedy="Provide a valid SQL table name to the method's first parameter";
				errorEvent.code=1;
				SwagDispatcher.dispatchEvent(errorEvent, this);
				return (null);
			}//if
			if (this._dbConnection==null) {
				errorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				errorEvent.description="Could not create table \""+tableName+"\" because database connection isn't available";
				errorEvent.remedy="Ensure that the database connection is established first (call SQLiteDatabase.openDatabaseFile, for example)";
				errorEvent.code=1;
				SwagDispatcher.dispatchEvent(errorEvent, this);
				return (null);
			}//if
			var query:String  = new String ();
			query = "CREATE TABLE IF NOT EXISTS '"+tableName+"' (";
			if ((primaryKey!=null) && (primaryKey!="")) {
				query+=primaryKey+" INTEGER AUTOINCREMENT PRIMARY KEY NOT NULL ASC,"; //Ascending, not-null primary key, auto-incrementing integer
			}//if
			for (var item:String in fields) {
				query+=item+" "+(fields[item] as String)+",";
			}//for
			query=query.substr(0,query.length-1);
			query+=");";			
			return (this.executeQuery(query));			
		}//createTable
		
		/**
		 * 		
		 * Simplified method to insert data into a specified table. Certain default behaviours are assumed for this operation and are automatically
		 * inserted into the SQL statement. If more complex behaviours are required, the <code>executeQuery</code> method should be called instead.
		 * If there is a problem executing this update, the "ROLLBACK" mechanism is invoked so that no data is lost in the transaction.
		 * 		 
		 * @param tableName The name of the table to update.
		 * @param fieldData A named array of field names/data to insert into the table. To update the field "myField", for example:
		 * 		fielData["myField"]="Some data";
		 * 	Note that SQLite supports very loose data-typing similar to older versions of Flash. That means that although a field may
		 * 	be typed as an INTEGER, a string may also be assigned to it if it can be converted. Similarly, return values should never be
		 * 	assumed to be correctly typed.
		 * 	Any fields in the table not included in the fieldData array will either be NULL or whatever default value is set for the fields
		 * 	at the time of table creation.
		 * 
		 * @param The result of the operation in a <code>SQLResult</code> object, or <em>null</em> if there was a problem
		 * with the parameters of te operation.
		 * 		 
		 */
		public function insertToTable(tableName:String=null, fieldData:Array=null):SQLResult {
			if ((tableName==null) || (tableName=="")) {
				var errorEvent:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.DATAEMPTYERROR);
				errorEvent.description="Table name cannot be empty or null";
				errorEvent.remedy="Provide a valid SQL table name to the method's first parameter";
				errorEvent.code=1;
				SwagDispatcher.dispatchEvent(errorEvent, this);
				return (null);
			}//if
			if (fieldData==null) {
				if (fieldData.length==0) {
					errorEvent=new SwagErrorEvent(SwagErrorEvent.DATAEMPTYERROR);
					errorEvent.description="Field data to insert cannot be empty or null";
					errorEvent.remedy="Provide a valid named array for the \"fieldData\" paramater";
					errorEvent.code=1;
					SwagDispatcher.dispatchEvent(errorEvent, this);					
					return (null);
				}//if
			}//if			
			//Start "UPDATE" clause
			var query:String  = new String ();
			query = "INSERT INTO '"+tableName+"' (";			
			for (var item:String in fieldData) {
				query+=item+",";
			}//for
			query=query.substr(0,query.length-1);
			query+=") VALUES (";
			for (item in fieldData) {
				query+="'"+String(fieldData[item])+"',";
			}//for
			query=query.substr(0,query.length-1);
			query+=");";			
			return (this.executeQuery(query));		
		}//insertToTable
		
		/**
		 * 
		 * Simplified method to update data on a specified table. Certain default behaviours are assumed for this operation and autmatically
		 * inserted into the SQL statement. If more complex behaviours are required, the <executeQuery> method should be called instead.
		 * If there is a problem executing this update, the "ROLLBACK" mechanism is invoked so that no data is lost in the transaction.
		 * 		 
		 * @param tableName The name of the table to update.
		 * @param fieldData A named array of field names/data to pass to the table. To update the field "myField", for example:
		 * 		fielData["myField"]="Some data";
		 * 	Note that SQLite supports very loose data-typing similar to older versions of Flash. That means that although a field may
		 * 	be typed as an INTEGER, a string may also be assigned to it if it can be converted. Similarly, return values should never be
		 * 	assumed to be correctly typed.
		 * @param selectors  A named array of sub-selection parameters to use with the update query. For example, to update only
		 *	rows where the "LAST_NAME" field is "Smith":
		 *	selectors["LAST_NAME"]="Smith"; 			
		 *		If this value omitted, all rows in the specified table will be affected. 
		 * @param useLike If TRUE, the "LIKE" operator is used in the selectors array instead of the "=" comparator. This allows the use
		 *	of pattern-matching substitutions: "%" for 0 or more characters, "_" for a single character, and lower-case characters match upper-case characters within
		 *	the standard ASCII set. For example:
		 *		fields["FIRST_NAME"]="Harry";
		 *		selectors["LAST_NAME"]="_mith"; //Matches any text ending with "mith", including "Smith".
		 *		sqliteDBInstance.updateTable("myTable", fields, selectors, true);
		 *	Default is FALSE.
		 * 
		 * @param The result of the operation in a <code>SQLResult</code> object, or <em>null</em> if there was a problem
		 * with the parameters of te operation.
		 * 		 
		 */
		public function updateTable(tableName:String=null, fieldData:Array=null, selectors:Array=null, useLike:Boolean=false):SQLResult {
			if ((tableName==null) || (tableName=="")) {
				var errorEvent:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.DATAEMPTYERROR);
				errorEvent.description="Table name cannot be empty or null";
				errorEvent.remedy="Provide a valid SQL table name to the method's first parameter";
				errorEvent.code=1;
				SwagDispatcher.dispatchEvent(errorEvent, this);
				return (null);
			}//if
			if (fieldData==null) {
				if (fieldData.length==0) {
					errorEvent=new SwagErrorEvent(SwagErrorEvent.DATAEMPTYERROR);
					errorEvent.description="Field data to update cannot be empty or null";
					errorEvent.remedy="Provide a valid named array for the \"fieldData\" paramater";
					errorEvent.code=1;
					SwagDispatcher.dispatchEvent(errorEvent, this);
					return (null);
				}//if
			}//if			
			//Start "UPDATE" clause
			var query:String  = new String ();
			query = "UPDATE '"+tableName+"' SET ";			
			for (var item:String in fieldData) {
				query+=item+"='"+(String(fieldData[item]))+"',";
			}//for
			query=query.substr(0,query.length-1);
			//Add "WHERE" clause			
			if (selectors!=null) {
				if (selectors.length>0) {
					query+=" WHERE ";
					for (item in selectors) {
						if (useLike) {
							query+=item+" LIKE '"+(String(selectors[item]))+"',";
						} else {
							query+=item+"='"+(String(selectors[item]))+"',";
						}//else
					}//for
					query=query.substr(0,query.length-1);
				}//if
			}//if
			query+=";";			
			return (this.executeQuery(query));		
		}//updateTable
		
		/**
		 * 		
		 * Executes a single arbitrary SQL query on the open database.
		 * 		 
		 * @param query The SQL query to execute
		 * 		 
		 * @param queryString The result of the query in a <code>SQLResult</code> object, or if the query was made
		 * 		asynchronously, or <em>null</em> if there was a problem with the query.
		 * @param parms Additional query parameters used to insert complex / large / binary data. This is a named/value object corresponding
		 * 		to parameters in the query string. Be sure to prepend both the query string and the named index values with "@".
		 * 		For example, using the query "INSERT INTO myTable (`myField`) VALUES (@myParam);", the parameter object would contain
		 * 		parameters["@myParam"]=myComplexData;	 
		 * @param async If <em>true</em>, the query will be executed asynchronously and will therefore cause the method to return
		 * 		<em>null</em>. If using asynchronous execution, add a SwAG event listener for the "SQLiteDatabaseEvent.ONRESULT" event.
		 * 
		 * @see	Adobe AIR SQLite implementation -> http://help.adobe.com/en_US/AS3LCR/Flash_10.0/localDatabaseSQLSupport.html
		 */
		public function executeQuery(queryString:String=null, parms:Object=null, async:Boolean=false):SQLResult {
			if ((queryString==null) || (queryString=="")) {
				var errorEvent:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.DATAEMPTYERROR);
				errorEvent.description="SQL query name cannot be empty or null";
				errorEvent.remedy="Provide a valid SQL query name to the method's first parameter";
				errorEvent.code=1;
				SwagDispatcher.dispatchEvent(errorEvent, this);				
				return (null);
			}//if
			if (this._dbConnection==null) {
				errorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				errorEvent.description="Could not execute SQL query because database connection isn't available";
				errorEvent.remedy="Ensure that the database connection is established first (call SQLiteDatabase.openDatabaseFile, for example)";
				errorEvent.code=1;
				SwagDispatcher.dispatchEvent(errorEvent, this);				
				return (null);
			}//if
			if (this._query!=null) {
				if (this._query.sqlConnection!=null) {
					if (this._query.executing) {
						errorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
						errorEvent.description="Could not execute SQL query because another one is currently executing";
						errorEvent.remedy="Wait for the current query to complete via event listeners, or create a new SQLiteDatabase ";
						errorEvent.remedy+="instance and assign the existing \"connection\" property to it, ";
						errorEvent.remedy+="or create the SQLiteDatabase instance using the static option";
						errorEvent.code=1;
						SwagDispatcher.dispatchEvent(errorEvent, this);								
						return (null);
					}//if
				}//if
			}//if
			this._query  = new SQLStatement();
			if (async) {
				//Even if the database is opened synchronously, adding listeners will case the result to be returned asynchronously!
				this._query.addEventListener(SQLEvent.RESULT, this.onResult);
				this._query.addEventListener(SQLErrorEvent.ERROR, this.onError);
			}//if
			this._query.text = queryString;					
			this._query.sqlConnection = this._dbConnection;
			if (parms!=null) {
				for (var item in parms) {					
					this._query.parameters[item]=parms[item];
				}//for
			}//if
			try {
				this._query.execute();
			} catch (error:SQLError) {
				errorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
				errorEvent.description=error.message+" - "+error.details;				
				errorEvent.code=1;
				SwagDispatcher.dispatchEvent(errorEvent, this);					
				return (null);
			}//catch			
			var returnResult:SQLResult=this._query.getResult();			
			return (returnResult);			
		}//executeQuery
		
		/**
		 * 		 
		 * Result handler for the last executed asynchronous SQL query. Results for synchronous calls are returned immediately.
		 * 		 
		 * @param eventObj A standard SQLEvent object.
		 * 		 
		 */
		public function onResult(eventObj:SQLEvent):void {			
			this._query.removeEventListener(SQLEvent.RESULT, this.onResult);
			this._query.removeEventListener(SQLErrorEvent.ERROR, this.onError);
			var event:SQLiteDatabaseEvent=new SQLiteDatabaseEvent(SQLiteDatabaseEvent.ONRESULT);
			event.result=this._query.getResult();			
			event.resultRows=event.result.data;			
			event.numRows=0;
			event.numRowsChanged=0;
			try {
				event.numRows=event.resultRows.length;				
			} catch (e:*) {				
			}//catch
			try {
				event.numRowsChanged=event.result.rowsAffected;
			} catch (e:*) {				
			}//catch
			SwagDispatcher.dispatchEvent(event, this);
		}//onResult
		
		/**		
		 * 
		 * Error handler for the last asyncrhonous executed SQL query.
		 * 		 
		 * @param eventObj A standard SQLErrorEvent object.
		 * 		 
		 */
		public function onError(eventObj:SQLErrorEvent):void {
			this._query.removeEventListener(SQLEvent.RESULT, this.onResult);
			this._query.removeEventListener(SQLErrorEvent.ERROR, this.onError);
			var event:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.FAILEDOPERATIONERROR);
			event.description="Error on SQL query: \""+eventObj.error.operation+"\"; ";
			event.description=eventObj.error.message+"; ";
			event.description+=eventObj.error.details;
			event.remedy="Check the SQL query for valid formatting and verify that it matches the database schema being accessed";
			event.code=eventObj.error.detailID;
			SwagDispatcher.dispatchEvent(event, this);
		}//onError
		
		/**
		 *  
		 * @param connectionSet The SQLLite database connection to be used with the class instance
		 * 
		 */
		public function set connection(connectionSet:SQLConnection):void {
			this._dbConnection=connectionSet;
		}//set connection
		
		/**		 
		 * @private 		 
		 */
		public function get connection():SQLConnection {
			return (this._dbConnection);
		}//get connection
		
		/**
		 * @return The native file path of the database file, or <em>null</em> if this is an in-memory database.		 
		 */
		public function get filePath():String {
			if (this._dbFile!=null) {
				return (this._dbFile.nativePath);	
			}//if
			return (null);
		}//get filePath
				
		/**
		 * 
		 * @param staticSet If TRUE, the databse is static (linked to existing SQLLiteDatabase instances). Use this setting to
		 * call multiple queries on a single database instance. If FALSE, this instance is a standalone instance.
		 * 
		 */
		public function set isStatic(staticSet:Boolean):void {
			var event:SwagErrorEvent=new SwagErrorEvent(SwagErrorEvent.UNSUPPORTEDOPERATIONERROR);
			event.description="SQLiteDatabase.connection property cannot be set";			
			event.remedy="This is a read-only property and is established when the instance is created (see constructor method)";		
			SwagDispatcher.dispatchEvent(event, this);
		}//set isStatic
		
		/**		 
		 * @private 		 
		 */
		public function get isStatic():Boolean {
			return (this._useStatic);
		}//get isStatic
		
		/**
		 * Closes the SQLLite database file, if open. Further queries will throw errors.		 
		 */
		public function closeDatabaseFile():void {
			this._dbConnection.close();			
		}//closeDatabaseFile
		
	}//SQLiteDatabase class
	
}//package