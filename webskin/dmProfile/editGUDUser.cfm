<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Edit Profile --->
<!--- @@description: Form for users editing their own profile --->

<!--- import tag libraries --->
<cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" />
<cfimport taglib="/farcry/core/tags/webskin/" prefix="skin" />

<!--- check permissions --->
<cfif NOT application.security.checkPermission(permission="SecurityManagement")>
	<skin:view typename="farCOAPI" webskin="webtopBodyNotFound" />
	<cfexit method="exittemplate">
</cfif>

<cfset oUser = application.fapi.getContentType(typename="gudUser") />

<!--- profile usernames are either "<userid>_GUD" or the bare Google user id (core dmProfile.getProfileID accepts both) --->
<cfset userID = stObj.username />
<cfif listLen(userID,"_") gt 1 and listLast(userID,"_") eq "GUD">
	<cfset userID = application.factory.oUtils.listSlice(userID,1,-2,"_") />
</cfif>

<!----------------------------- 
ACTION	
------------------------------>
<ft:serverSideValidation />

<ft:processform action="Save" exit="true">
	<ft:processformobjects typename="gudUser" lArrayListGenerate="lgroups" />
	
	<!--- track whether we have saved a farUser record--->
	<cfset savedUserID = lsavedobjectids />
	
	<ft:processformobjects typename="dmProfile">
		
		<!--- We only check the profile/faruser relationship if we saved a CLIENTUD user --->
		<cfif len(savedUserID)>
			<cfset stUser = oUser.getData(objectid=savedUserID) />
			
			<!--- If the current username is not the same one we saved (ie. new user) --->
			<cfif userID NEQ stUser.userid><!--- New user --->
				<cfset stProperties.username = "#stUser.userid#_GUD" />
				<cfset stProperties.userdirectory = "GUD" />
			</cfif>
		</cfif>			
		
	</ft:processformobjects>
</ft:processform>

<ft:processform action="Cancel" exit="true" />

<cfif stObj.userdirectory eq "GUD" or stObj.userdirectory eq "">

	<cfset stUser = oUser.getByUserID(userID) />
	
<cfelse>
	
	<cfset stUser = structnew() />

</cfif>

<!----------------------------- 
VIEW	
------------------------------>
<cfoutput>
	<h1>EDIT: #encodeForHTML(stObj.firstname)# #encodeForHTML(stObj.lastname)# (#stObj.userdirectory#)</h1>
</cfoutput>

<ft:form>
	<ft:object objectid="#stObj.objectid#" typename="dmProfile" lfields="firstname,lastname,breceiveemail,emailaddress,phone,fax,position,department,locale,overviewHome" lhiddenFields="username,userdirectory" legend="User details" />
	
	<!--- gudUser identity fields are set by Google on login (see GoogleUserDirectory.authenticate), so they are display only --->
	<cfif structIsEmpty(stUser) or stUser.userid eq "">
		<ft:fieldset legend="Security">
			<cfoutput><p>This user has not signed in with Google yet. Groups can be assigned after their first sign in, or through a group's domain/email mapping.</p></cfoutput>
		</ft:fieldset>
	<cfelse>
		<ft:object stObject="#stUser#" typename="gudUser" lfields="userid,providerEmail,providerDomain" format="display" legend="Google Account" />
		<ft:object stObject="#stUser#" typename="gudUser" lfields="aGroups" legend="Security" />
	</cfif>
	
	<ft:farcryButtonPanel>
		<ft:button value="Save" color="orange" />
		<ft:button value="Cancel" validate="false" />
	</ft:farcryButtonPanel>
</ft:form>

<cfsetting enablecfoutputonly="false" />