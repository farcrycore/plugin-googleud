<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Merge existing profile --->
<!--- @@fuAlias: merge --->

<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<ft:processform action="Merge">
	<ft:processformObjects typename="farLogin">
		<cfset oUser = application.fapi.getContentType("gudUser") />
		<cfset qUsers = oUser.queryUserPassword(stProperties.username,stProperties.password) />
		<cfif qUsers.recordcount>
			<cfset oUser.mergeFarcryUDAccount(qUsers.userid,session.dmProfile.objectid) />
			<skin:bubble message="The '#qUsers.userid#' FarCry account has been merged into this Google profile. You will no longer be able to log in with that username / password." />
		<cfelse>
			<skin:bubble message="No users match those credentials" tags="error" />
		</cfif>
	</ft:processformObjects>
</ft:processform>


<cfoutput>
	<h1>Merge Existing Account</h1>
</cfoutput>

<cfif application.security.isLoggedIn() and refindnocase("_GUD$",session.dmProfile.username)>
	<cfoutput>
		<p>This utility merges an existing account into this one. Specifically it will:</p>
		<ul>
			<li>copy profile information (where it hasn't already been set)</li>
			<li>disable the username / password login</li>
			<li>update audit logs and history to the new account</li>
		</ul>
	</cfoutput>
	
	<skin:pop tags="error" start="<ul class='error'>" end="</ul>"><cfoutput><li>#message.message#</li></cfoutput></skin:pop>
	<skin:pop start="<ul class='success'>" end="</ul>"><cfoutput><li>#message.message#</li></cfoutput></skin:pop>
	
	<ft:form>
		<ft:object typename="farLogin" lFields="username,password" prefix="login" legend="" focusField="username" />
		
		<ft:buttonPanel>
			<ft:button value="Merge" />
		</ft:buttonPanel>
	</ft:form>
<cfelse>
	<cfoutput><ul id='errorMsg'><li>You must be logged in via Google to use this functionality</li></ul></cfoutput>
</cfif>

<cfsetting enablecfoutputonly="false" />