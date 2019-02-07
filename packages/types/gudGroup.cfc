<cfcomponent displayname="Google UD Group" extends="farcry.core.packages.types.types" output="false" bsystem="true" hint="Users can be assigned to any number of groups.  Groups in turn are mapped to roles within the system which determine what a user has permission to do."
	bObjectBroker="true">
	
	<cfproperty ftSeq="1" ftFieldset="Google UD Group" ftLabel="Title" 
				name="title" type="string" default="" 
				hint="The title of this group" />
				
	<cfproperty ftSeq="2" ftFieldset="Google UD Group" ftRenderType="custom" ftLabel="Domains" 
				name="aDomains" type="array" 
				ftHint="A list of domains (one per line) that should automatically be assigned this group. '*' for all users. Strict matching to the domain part of the user's email address" />
	
	
	<cffunction name="ftEditADomains" access="public" output="true" returntype="string" hint="his will return a string of formatted HTML text to enable the user to edit the data">
		<cfargument name="typename" required="true" type="string" hint="The name of the type that this field is part of.">
		<cfargument name="stObject" required="true" type="struct" hint="The object of the record that this field is part of.">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		<cfargument name="fieldname" required="true" type="string" hint="This is the name that will be used for the form field. It includes the prefix that will be used by ft:processform.">

		<cfset var html = "" />
		<cfset var nl = "
" />
		
		<cfsavecontent variable="html">
			<cfoutput>
				<div class="multiField">
					<div id="#arguments.fieldname#DIV">
						<div class="blockLabel">
							<textarea name="#arguments.fieldname#" id="#arguments.fieldname#" class="textareaInput #arguments.stMetadata.ftclass#" style="#arguments.stMetadata.ftstyle#">#arraytolist(arguments.stMetadata.value,nl)#</textarea>
						</div>
					</div>
				</div>
			</cfoutput>
		</cfsavecontent>
		
		<cfreturn html>
	</cffunction>

	<cffunction name="ftValidateADomains" access="public" output="false" returntype="struct" hint="This will return a struct with bSuccess and stError">
		<cfargument name="stFieldPost" required="true" type="struct" hint="The fields that are relevent to this field type.It consists of value and stSupporting">
		<cfargument name="stMetadata" required="true" type="struct" hint="This is the metadata that is either setup as part of the type.cfc or overridden when calling ft:object by using the stMetadata argument.">
		
		<cfset var stResult = structNew()>		
		<cfset stResult.bSuccess = true>
		<cfset stResult.value = stFieldPost.Value>
		<cfset stResult.stError = StructNew()>
		
		<!--- --------------------------- --->
		<!--- Perform any validation here --->
		<!--- --------------------------- --->
		<cfset stResult.value = listtoarray(arguments.stFieldPost.value,"#chr(10)##chr(13)#") />

		<!--- ----------------- --->
		<!--- Return the Result --->
		<!--- ----------------- --->
		<cfreturn stResult>
		
	</cffunction>

	
	
	<cffunction name="getID" access="public" output="false" returntype="uuid" hint="Returns the objectid for the specified object (name can be the objectid or the title)">
		<cfargument name="name" type="string" required="true" hint="Pass in a role name and the objectid will be returned" />
		
		<cfset var qItem = "" />
		
		<cfif isvalid("uuid",arguments.name)>
			<cfreturn arguments.name />
		<cfelse>
			<cfquery datasource="#application.dsn#" name="qItem">
				select	*
				from	#application.dbOwner#gudGroup
				where	lower(title)=<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(arguments.name)#" />
			</cfquery>
			
			<cfreturn qItem.objectid[1] />
		</cfif>
	</cffunction>
	
	<cffunction name="delete" access="public" hint="Removes any corresponding entries in farUser" returntype="struct" output="false">
		<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of the object being deleted">
		<cfargument name="user" type="string" required="true" hint="Username for object creator" default="">
		<cfargument name="auditNote" type="string" required="true" hint="Note for audit trail" default="">
		
		<cfset var stUser = structnew() />
		<cfset var qUser = "" />
		<cfset var oUser = createObject("component", application.stcoapi["gudUser"].packagePath) />
		
		<cfquery datasource="#application.dsn#" name="qUser">
			delete
			from	#application.dbowner#gudUser_aGroups
			where	<cfif application.dbtype eq "mysql">`data`<cfelse>data</cfif>=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.objectid#" />
		</cfquery>
		
		<cfreturn super.delete(objectid=arguments.objectid,user=arguments.user,auditNote=arguments.auditNote) />
	</cffunction>
	
	<cffunction name="afterSave" access="public" output="false" returntype="struct" hint="Processes new type content">
		<cfargument name="stProperties" type="struct" required="true" hint="The properties that have been saved" />
		
		<cfset application.security.initCache() />
		
		<cfreturn arguments.stProperties />
	</cffunction>
	
</cfcomponent>