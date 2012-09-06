<cfcomponent displayname="GUD User" hint="User model for the Google User Directory." extends="farcry.core.packages.types.types" output="false" description="">
	
	<cfproperty ftLabel="UserID" 
				name="userid" type="string" default="" hint="The userid to use in FarCry" 
				ftType="string" />
				
	<cfproperty ftLabel="Refresh Token"
				name="refreshToken" type="string" default="" />
				
	<cfproperty ftLabel="Provider Domain" ftType="string"
				name="providerDomain" type="string" default="" 
				hint="The stripped email domain" />
				
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
	
</cfcomponent>