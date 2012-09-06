<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Edit Profile --->
<!--- @@description: Form for users editing their own profile --->

<!--- import tag libraries --->
<cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" />
<cfimport taglib="/farcry/core/tags/webskin/" prefix="skin" />

<cfset oUser = application.fapi.getContentType(typename="gudUser") />

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
			<cfif stProperties.username NEQ "#stUser.objectid#_GUD"><!--- New user --->
				<cfset stProperties.username = "#stUser.objectid#_GUD" />
				<cfset stProperties.userdirectory = "GUD" />
			</cfif>
		</cfif>			
		
	</ft:processformobjects>
</ft:processform>

<ft:processform action="Cancel" exit="true" />

<cfif stObj.userdirectory eq "GUD" or stObj.userdirectory eq "">

	<cfset userID = application.factory.oUtils.listSlice(stObj.username,1,-2,"_") />
	<cfset stUser = oUser.getByUserID(userID) />
	
<cfelse>
	
	<cfset stUser = structnew() />

</cfif>

<!----------------------------- 
VIEW	
------------------------------>
<cfoutput>
	<h1>EDIT: #stObj.firstname# #stObj.lastname# (#stObj.userdirectory#)</h1>
</cfoutput>

<ft:form>
	<ft:object objectid="#stObj.objectid#" typename="dmProfile" lfields="firstname,lastname,breceiveemail,emailaddress,phone,fax,position,department,locale,overviewHome" lhiddenFields="username,userdirectory" legend="User details" />
	
	<cfset userID = application.factory.oUtils.listSlice(stObj.username,1,-2,"_") />
	<cfset stUser = oUser.getByUserID(userID) />
	
	<cfif structIsEmpty(stUser) or stUser.userid eq "">
		<cfset stPropValues = structnew() />
		<cfset stPropValues.userdirectory = "GUD" />

		<ft:object stObject="#stObj#" typename="gudUser" lfields="userid,providerDomain,aGroups" stPropValues="#stPropValues#" legend="Security" />
	<cfelse>
		<ft:object stObject="#stUser#" typename="gudUser" lfields="aGroups" legend="Security" />
	</cfif>
	
	<ft:farcryButtonPanel>
		<ft:button value="Save" color="orange" />
		<ft:button value="Cancel" validate="false" />
	</ft:farcryButtonPanel>
</ft:form>

<cfsetting enablecfoutputonly="false" />