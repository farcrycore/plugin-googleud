<cfcomponent displayname="GUD User" hint="User model for the Google User Directory." extends="farcry.core.packages.types.types" output="false" description="">
	
	<cfproperty ftLabel="UserID" 
				name="userid" type="string" default="" hint="The userid to use in FarCry" 
				ftType="string" />
				
	<cfproperty ftLabel="Refresh Token"
				name="refreshToken" type="string" default="" />
				
	<cfproperty ftLabel="Provider Domain" ftType="string"
				name="providerDomain" type="string" default="" 
				hint="The stripped email domain" />
				
	<cfproperty ftLabel="Provider Email" ftType="string"
				name="providerEmail" type="string" default="" 
				hint="The email" />

	<cfproperty ftLabel="Groups" 
				name="aGroups" type="array" default="" 
				ftType="array" ftJoin="gudGroup" 
				hint="The groups this member is a member of" />
				
	<cfproperty ftLabel="Groups" 
				name="lGroups" type="longchar" default="" 
				ftType="arrayList" ftArrayField="aGroups" ftJoin="farGroup" 
				hint="The groups this member is a member of (list generated automatically)" />
	
	
	<cffunction name="addGroup" access="public" output="false" returntype="void" hint="Adds this user to a group">
		<cfargument name="user" type="string" required="true" hint="The user to add" />
		<cfargument name="group" type="string" required="true" hint="The group to add to" />
		
		<cfset var stUser = structnew() />
		<cfset var stGroup = structnew() />
		<cfset var oGroup = createObject("component", application.stcoapi["gudGroup"].packagePath) />
		<cfset var i = 0 />
		
		<!--- Get the user by objectid or userid --->
		<cfif isvalid("uuid",arguments.user)>
			<cfset stUser = getData(arguments.user) />
		<cfelse>
			<cfset stUser = getByUserID(arguments.user) />
		</cfif>
	
		<cfif not isvalid("uuid",arguments.group)>
			<cfset arguments.group = oGroup.getID(arguments.group) />
		</cfif>
		
		<!--- Check to see if they are already a member of the group --->
		<cfparam name="stUser.aGroups" default="#arraynew(1)#" />
		<cfif listfindnocase(arraytolist(stUser.aGroups),arguments.group)>
			<cfset arrayappend(stUser.aGroups,arguments.group) />
			<cfset setData(stProperties=stUser) />
		</cfif>
	</cffunction>
	
	<cffunction name="removeGroup" access="public" output="false" returntype="void" hint="Removes this user from a group">
		<cfargument name="user" type="string" required="true" hint="The user to add" />
		<cfargument name="group" type="string" required="true" hint="The group to add to" />
		
		<cfset var stUser = structnew() />
		<cfset var i = 0 />
		<cfset var oGroup = createObject("component", application.stcoapi["gudGroup"].packagePath) />
		
		<!--- Get the user by objectid or userid --->
		<cfif isvalid("uuid",arguments.user)>
			<cfset stUser = getData(arguments.user) />
		<cfelse>
			<cfset stUser = getByUserID(arguments.user) />
		</cfif>
		
		<cfif not isvalid("uuid",arguments.group)>
			<cfset arguments.group = oGroup.getID(arguments.group) />
		</cfif>
		
		<!--- Check to see if they are a member of the group --->
		<cfparam name="stUser.aGroups" default="#arraynew(1)#" />
		<cfloop from="#arraylen(stUser.aGroups)#" to="1" index="i" step="-1">
			<cfif stUser.aGroups[i] eq arguments.group>
				<cfset arraydeleteat(stUser.aGroups,i) />
			</cfif>
		</cfloop>
		
		<cfset setData(stProperties=stUser) />
	</cffunction>
	
	<cffunction name="getByUserID" access="public" output="false" returntype="struct" hint="Returns the data struct for the specified user id">
		<cfargument name="userid" type="string" required="true" hint="The user id" />
		
		<cfset var stResult = structnew() />
		<cfset var qUser = "" />
		
		<cfquery datasource="#application.dsn#" name="qUser">
			select	*
			from	#application.dbowner#gudUser
			where	lower(userid)=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(arguments.userid)#" />
		</cfquery>
		
		<cfif qUser.recordcount>
			<cfset stResult = getData(qUser.objectid) />
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	
	<cffunction name="queryUserPassword" access="public" output="false" returntype="query" hint="Return a query of farUser rows that match the provided credentials">
		<cfargument name="username" type="string" required="true" />
		<cfargument name="password" type="string" required="true" />
		
		<cfset var qUser = "" />
		<cfset var authenticatedObjectId = "" />
		<cfset var hashName = application.security.userdirectories.clientud.getOutputHashName() />
		
		<!--- Find the user --->
		<cfquery datasource="#application.dsn#" name="qUser">
			select	objectid,userid,password,userstatus
			from	#application.dbowner#farUser
			where	userid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.username)#" />
		</cfquery>
		
		<!--- Try to match the entered password against the users in the DB --->
		<cfloop query="qUser">
			<cfif application.security.cryptlib.passwordMatchesHash(password=arguments.password,hashedPassword=qUser.password)>
				<cfset authenticatedObjectId = qUser.objectid />
				<cfbreak />
			</cfif>
		</cfloop>
		
		<cfif Len(authenticatedObjectId)>
			<!--- Return the row with the password match --->
			<cfquery dbtype="query" name="qUser">
				select *
				from qUser
				where objectid = '#authenticatedObjectId#'
			</cfquery>
			<!--- Does the hashed password need to be updated? --->
			<cfif application.security.cryptlib.hashedPasswordIsStale(hashedPassword=qUser.password,password=arguments.password,hashname=hashName)>
				<cfquery datasource="#application.dsn#">
					update	#application.dbowner#farUser
					set		password=<cfqueryparam cfsqltype="cf_sql_varchar" value="#application.security.cryptlib.encodePassword(password=arguments.password,hashname=hashName)#" />
					where	objectid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#authenticatedObjectId#" />
				</cfquery>
			</cfif>
		<cfelse>
			<!--- Delete all rows from the query --->
			<cfquery dbtype="query" name="qUser">
				select *
				from qUser
				where 0 = 1
			</cfquery>
		</cfif>
		
		<cfreturn qUser />
	</cffunction>
	
	
	<cffunction name="migrateContentUserData" access="private" output="false" returntype="void">
		<cfargument name="typename" type="string" required="true" />
		<cfargument name="oldprofile" type="struct" required="true" />
		<cfargument name="newprofile" type="struct" required="true" />
		
		<cfset var property = "" />
		
		<!--- Extended array component - skip --->
		<cfif find("_",arguments.typename)>
			<cfreturn />
		</cfif>
		
		<!--- Undeployed - skip --->
		<cfif isdefined("application.fc.lib.db")>
			<cfif not application.fc.lib.db.isDeployed(arguments.typename)>
				<cfreturn />
			</cfif>
		<cfelse>
			<cfif not createObject("component", "farcry.core.packages.farcry.alterType").isCFCDeployed(arguments.typename)>
				<cfreturn />
			</cfif>
		</cfif>
		
		<!--- Update user properties --->
		<cfloop list="createdby,lastupdatedby,lockedby" index="property">
			<cfif structkeyexists(application.stCOAPI[arguments.typename].stProps,property)>
				<cfquery datasource="#application.dsn#">
					update	#application.dbowner##arguments.typename#
					set		#property# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.newprofile.username#" />
					where	#property# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.oldprofile.username#" />
				</cfquery>
			</cfif>
		</cfloop>
		
		<!--- Update profile properties --->
		<cfloop list="ownedby" index="property">
			<cfif structkeyexists(application.stCOAPI[arguments.typename].stProps,property)>
				<cfquery datasource="#application.dsn#">
					update	#application.dbowner##arguments.typename#
					set		#property# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.newprofile.objectid#" />
					where	#property# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.oldprofile.objectid#" />
				</cfquery>
			</cfif>
		</cfloop>
		
		<cfloop collection="#application.stCOAPI[arguments.typename].stProps#" item="property">
			<cfif application.stCOAPI[arguments.typename].stProps[property].metadata.type eq "uuid" and structkeyexists(application.stCOAPI[arguments.typename].stProps[property].metadata,"ftJoin") and application.stCOAPI[arguments.typename].stProps[property].metadata.ftJoin eq "dmProfile">
				<cfquery datasource="#application.dsn#">
					update	#application.dbowner##arguments.typename#
					set		#property# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.newprofile.objectid#" />
					where	#property# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.oldprofile.objectid#" />
				</cfquery>
			</cfif>
		</cfloop>
	</cffunction>
	
	<cffunction name="migrateLogs" access="private" output="false" returntype="void">
		<cfargument name="oldusername" type="string" required="true" />
		<cfargument name="newusername" type="string" required="true" />
		
		<cfquery datasource="#application.dsn#">
			update	farLog
			set		userid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.newusername#" />
			where	userid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.oldusername#" />
					and type in ('types','rules')
		</cfquery>
	</cffunction>
	
	<cffunction name="migrateProfile" access="private" output="false" returntype="void">
		<cfargument name="oldprofile" type="struct" required="true" />
		<cfargument name="newprofile" type="struct" required="true" />
		
		<cfset var property = "" />
		
		<cfloop collection="#oldprofile#" item="property">
			<cfif listfindnocase("bReceiveEmail,phone,fax,position,department,locale,overviewhome,notes",property)>
				<cfset arguments.newprofile[property] = arguments.oldprofile[property] />
			</cfif>
		</cfloop>
		
		<cfset application.fapi.setData(stProperties=arguments.newprofile) />
		<cfset session.dmProfile = arguments.newprofile />
	</cffunction>
	
	<cffunction name="disableOldUser" access="private" output="false" returntype="void">
		<cfargument name="userid" type="string" required="true" />
		
		<cfset var oUser = application.fapi.getContentType("farUser") />
		<cfset var stUser = oUser.getByUserID(arguments.userid) />
		
		<cfset stUser.userstatus = "inactive" />
		
		<cfset oUser.setData(stProperties=stUser) />
	</cffunction>
	
	<cffunction name="mergeFarcryUDAccount" access="public" output="false" returntype="void">
		<cfargument name="userid" type="string" required="true" />
		<cfargument name="profileid" type="uuid" required="true" />
		
		<cfset var typename = "" />
		<cfset var oProfile = application.fapi.getContentType("dmProfile") />
		<cfset var stOldProfile = oProfile.getProfile(arguments.userid,"CLIENTUD") />
		<cfset var stNewProfile = oProfile.getData(arguments.profileid) />
		
		<!--- Update createdby,lastupdatedby,lockedby,ownedby --->
		<cfloop collection="#application.stCOAPI#" item="typename">
			<cfif listfindnocase("type,rule",application.stCOAPI[typename].class)>
				<cfset migratecontentuserdata(typename,stOldProfile,stNewProfile) />
			</cfif>
		</cfloop>
		
		<!--- Update logs --->
		<cfset migrateLogs(stOldProfile.username,stNewProfile.username) />
		
		<!--- Copy profile data --->
		<cfset migrateProfile(stOldProfile,stNewProfile) />
		
		<!--- Disable old account --->
		<cfset disableOldUser(arguments.userid) />
	</cffunction>
	
</cfcomponent>