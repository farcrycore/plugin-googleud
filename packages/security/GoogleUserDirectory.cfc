<cfcomponent displayname="Google User Directory" extends="farcry.core.packages.security.UserDirectory" output="false" key="GUD">
	
	
	<cffunction name="getLoginForm" access="public" output="false" returntype="string" hint="Returns the form component to use for login">
		
		<cfreturn "gudLogin" />
	</cffunction>
	
	<cffunction name="authenticate" access="public" output="false" returntype="struct" hint="Attempts to process a user. Runs every time the login form is loaded.">
		<cfset var stResult = structnew() />
		<cfset var stTokens = structnew() />
		<cfset var stTokenInfo = structnew() />
		<cfset var oUser = application.fapi.getContentType("gudUser") />
		
		<cfif structkeyexists(url,"error")>
			
			<cfset stResult.userid = "" />
			<cfset stResult.authenticated = false />
			<cfset stResult.message = url.error />
			
		<cfelseif structkeyexists(url,"code")>
			
			<cftry>
				<!--- Get Google access information --->
				<cfset stTokens = getTokens(url.code,application.config.GUD.clientID,application.config.GUD.clientSecret,application.security.userdirectories.gud.getRedirectURL(),application.config.GUD.proxy) />
				<cfset stTokenInfo = getTokenInfo(application.config.GUD.clientID,stTokens.access_token,application.config.GUD.proxy) />
				<cfparam name="session.security.ga" default="#structnew()#" >
				<cfset session.security.ga[hash(stTokenInfo.user_id)] = stTokens />
				<cfset session.security.ga[hash(stTokenInfo.user_id)].user_id = stTokenInfo.user_id />
				<cfset session.security.ga[hash(stTokenInfo.user_id)].profile = getGoogleProfile(stTokens.access_token,application.config.GUD.proxy) />
				
				<!--- If there isn't a gudUser record, create one --->
				<cfset stUser = oUser.getByUserID(stTokenInfo.user_id) />
				<cfif structisempty(stUser)>
					<cfset stUser = oUser.getData(createuuid()) />
					<cfset stUser.userid = stTokenInfo.user_id />
					<cfif structkeyexists(stTokens,"refresh_token")>
						<cfset stUser.refreshToken = stTokens.refresh_token />
					</cfif>
					<cfset stUser.providerDomain = listlast(session.security.ga[hash(stTokenInfo.user_id)].profile.email,"@") />
					<cfset oUser.setData(stProperties=stUser) />
				<cfelse>
					<cfset session.security.ga[hash(stTokenInfo.user_id)].refresh_token = stUser.refreshToken />
				</cfif>
					
				<cfset stResult.authenticated = "true" />
				<cfset stResult.userid = stTokenInfo.user_id />
				<cfset stResult.ud = "GUD" />
				
				<cfcatch>
					<cfset application.fc.lib.error.logData(application.fc.lib.error.normalizeError(cfcatch)) />
					<cfset stResult.authenticated = "false" />
					<cfset stResult.userid = "" />
					<cfset stResult.message = "Error while logging into Google: #cfcatch.message#" />
				</cfcatch>
			</cftry>
			
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getUserGroups" access="public" output="false" returntype="array" hint="Returns the groups that the specified user is a member of">
		<cfargument name="UserID" type="string" required="true" hint="The user being queried" />
		
		<cfset var qGroups = "" />
		<cfset var aGroups = arraynew(1) />
		<cfset var stUser = application.fapi.getContentType(typename="gudUser").getByUserID(arguments.userID) />
		
		<cfquery datasource="#application.dsn#" name="qGroups">
			select	title
			from	#application.dbowner#gudGroup
			where	objectid in (
						select	data
						from	#application.dbowner#gudUser_aGroups
						where	parentid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#stUser.objectid#" />
					)
					or objectid in (
						select	parentid
						from	#application.dbowner#gudGroup_aDomains
						where	data=<cfqueryparam cfsqltype="cf_sql_varchar" value="*" />
								or data=<cfqueryparam cfsqltype="cf_sql_varchar" value="#stUser.providerDomain#" />
					)
		</cfquery>
		
		<cfloop query="qGroups">
			<cfset arrayappend(aGroups,title) />
		</cfloop>
		
		<cfreturn listtoarray(valuelist(qGroups.title)) />
	</cffunction>
	
	<cffunction name="getAllGroups" access="public" output="false" returntype="array" hint="Returns all the groups that this user directory supports">
		<cfset var qGroups = "" />
		<cfset var aGroups = arraynew(1) />
		
		<cfquery datasource="#application.dsn#" name="qGroups">
			select		*
			from		#application.dbowner#gudGroup
			order by	title
		</cfquery>
		
		<cfloop query="qGroups">
			<cfset arrayappend(aGroups,title) />
		</cfloop>

		<cfreturn aGroups />
	</cffunction>

	<cffunction name="getGroupUsers" access="public" output="false" returntype="array" hint="Returns all the users in a specified group">
		<cfargument name="group" type="string" required="true" hint="The group to query" />
		
		<cfset var qUsers = "" />
		
		<cfquery datasource="#application.dsn#" name="qUsers">
			select	objectid
			from	#application.dbowner#gudUser
			where	objectid in (
						select	parentid
						from	#application.dbowner#gudUser_aGroups ug
								inner join
								#application.dbowner#gudGroup g
								ug.data=g.objectid
						where	g.title=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.group#" />
								or objectid in (
									select	parentid
									from	#application.dbowner#gudGroup_aDomains
									where	data=<cfqueryparam cfsqltype="cf_sql_varchar" value="*" />
											or data=gudUser.providerDomain
								)
					)
		</cfquery>
		
		<cfreturn listtoarray(valuelist(qUsers.objectid)) />
	</cffunction>
	
	<cffunction name="getProfile" access="public" output="false" returntype="struct" hint="Returns profile data available through the user directory">
		<cfargument name="userid" type="string" required="true" hint="The user directory specific user id" />
		<cfargument name="currentprofile" type="struct" required="false" hint="The current user profile" />
		
		<cfset var stProfile = structnew() />
		
		<cfif isdefined("session.security.ga.#hash(arguments.userid)#") and not isdefined("session.security.ga.#hash(arguments.userid)#.profile")>
			<cfset session.security.ga[hash(arguments.userid)].profile = getGoogleProfile(access_token=session.security.ga[hash(arguments.userid)].access_token,proxy=application.config.GUD.proxy) />
		</cfif>
		
		<cfset stProfile.firstname = session.security.ga[hash(arguments.userid)].profile.given_name />
		<cfset stProfile.lastname = session.security.ga[hash(arguments.userid)].profile.family_name />
		<cfset stProfile.emailaddress = session.security.ga[hash(arguments.userid)].profile.email />
		<cfset stProfile.override = true />
		
		<cfreturn stProfile />
	</cffunction>
	
	<cffunction name="isEnabled" access="public" output="false" returntype="boolean" hint="Returns true if this user directory is active. This function can be overridden to check for the existence of config settings.">
		
		<cfreturn isdefined("application.config.GUD.clientID") and len(application.config.GUD.clientID) and isdefined("application.config.GUD.clientSecret") and len(application.config.GUD.clientSecret) />
	</cffunction>
					
	
	<cffunction name="parseProxy" access="private" output="false" returntype="struct">
		<cfargument name="proxy" type="string" required="true" />
		
		<cfset var stResult = structnew() />
		
		<cfif len(arguments.proxy)>
			<cfif listlen(arguments.proxy,"@") eq 2>
				<cfset stResult.login = listfirst(arguments.proxy,"@") />
				<cfset stResult.proxyUser = listfirst(stResult.login,":") />
				<cfset stResult.proxyPassword = listlast(stResult.login,":") />
			<cfelse>
				<cfset stResult.proxyUser = "" />
				<cfset stResult.proxyPassword = "" />
			</cfif>
			<cfset stResult.server = listlast(arguments.proxy,"@") />
			<cfset stResult.proxyServer = listfirst(stResult.server,":") />
			<cfif listlen(stResult.server,":") eq 2>
				<cfset stResult.proxyPort = listlast(stResult.server,":") />
			<cfelse>
				<cfset stResult.proxyPort = "80" />
			</cfif>
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<!---
		From http://code.google.com/apis/analytics/docs/gdata/v3/gdataAuthorization.html: 
	    1) When you create your application, you register it with Google. Google then provides information you'll need later, such as a client ID and a client secret.
	    2) Activate the Google Analytics API in the Services pane of the Google APIs Console. (If it isn't listed in the Console, then skip this step.)
	    3) When your application needs access to user data, it asks Google for a particular scope of access. ***
	    4) Google displays an OAuth dialog to the user, asking them to authorize your application to request some of their data.
	    5) If the user approves, then Google gives your application a short-lived access token.
	    6) Your application requests user data, attaching the access token to the request.
	    7) If Google determines that your request and the token are valid, it returns the requested data.
	 --->
	<cffunction name="getAuthorisationURL" access="public" output="false" returntype="string">
		<cfargument name="clientid" type="string" required="true" />
		<cfargument name="redirectURL" type="string" required="true" />
		<cfargument name="scope" type="string" required="false" default="https://www.googleapis.com/auth/userinfo.profile" />
		<cfargument name="state" type="string" required="false" default="" />
		
		<cfreturn "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=#arguments.clientid#&redirect_uri=#urlencodedformat(arguments.redirectURL)#&scope=#urlencodedformat(arguments.scope)#&access_type=offline&state=#urlencodedformat(arguments.state)#" />
	</cffunction>
	
	<cffunction name="getTokens" access="private" output="false" returntype="struct">
		<cfargument name="authorizationCode" type="string" required="true" />
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="clientSecret" type="string" required="true" />
		<cfargument name="redirectURL" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var stAttr = structnew() />
		
		<cfset stAttr.url = "https://accounts.google.com/o/oauth2/token" />
		<cfset stAttr.method = "POST" />
		
		<cfif len(arguments.proxy)>
			<cfset structappend(stAttr,parseProxy(arguments.proxy)) />
		</cfif>
		
		<cfhttp attributeCollection="#stAttr#">
			<cfhttpparam type="formfield" name="code" value="#arguments.authorizationCode#" />
			<cfhttpparam type="formfield" name="client_id" value="#arguments.clientID#" />
			<cfhttpparam type="formfield" name="client_secret" value="#arguments.clientSecret#" />
			<cfhttpparam type="formfield" name="redirect_uri" value="#arguments.redirectURL#" />
			<cfhttpparam type="formfield" name="grant_type" value="authorization_code" />
		</cfhttp>

		<cfif not cfhttp.statuscode eq "200 OK">
			<cfset throwError(message="Error accessing Google API: #cfhttp.statuscode#",endpoint="https://accounts.google.com/o/oauth2/token",response=trim(cfhttp.filecontent),args=arguments,stAttr=stAttr) />
		</cfif>
		
		<cfset stResult = deserializeJSON(cfhttp.FileContent.toString()) />
		<cfset stResult.access_token_expires = dateadd("s",stResult.expires_in,now()) />
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getAccessToken" access="public" output="false" returntype="string">
		<cfargument name="refresh_token" type="string" required="false" />
		<cfargument name="access_token" type="string" required="true" />
		<cfargument name="access_token_expires" type="date" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var stProxy = parseProxy(arguments.proxy) />
		
		<cfif isdefined("arguments.refresh_token") and datecompare(arguments.access_token_expires,now()) lt 0>
			<cfhttp url="https://accounts.google.com/o/oauth2/token" method="POST" attributeCollection="#stProxy#">
				<cfhttpparam type="formfield" name="refresh_token" value="#arguments.refreshToken#" />
				<cfhttpparam type="formfield" name="client_id" value="#arguments.clientID#" />
				<cfhttpparam type="formfield" name="client_secret" value="#arguments.clientSecret#" />
				<cfhttpparam type="formfield" name="grant_type" value="refresh_token" />
			</cfhttp>
			
			<cfif not cfhttp.statuscode eq "200 OK">
				<cfset throwError(message="Error accessing Google API: #cfhttp.statuscode#",endpoint="https://accounts.google.com/o/oauth2/token",response=cfhttp.filecontent,argumentCollection=arguments) />
			</cfif>
			
			<cfset stResult = deserializeJSON(cfhttp.FileContent.toString()) />
			
			<cfreturn stResult.access_token />
		<cfelseif not isdefined("arguments.refresh_token")>
			<cfset throwError(message="Error accessing Google API: access token has expired and no refresh token is available",endpoint="https://accounts.google.com/o/oauth2/token",response=cfhttp.filecontent,argumentCollection=arguments) />
		</cfif>
		
		<cfreturn arguments.access_token />
	</cffunction>
	
	<cffunction name="getTokenInfo" access="private" output="false" returntype="struct">
		<cfargument name="clientID" type="string" required="true" />
		<cfargument name="accessToken" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var stProxy = parseProxy(arguments.proxy) />
		
		<cfhttp url="https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=#arguments.accessToken#" method="GET" attributeCollection="#stProxy#" />
		
		<cfif not cfhttp.statuscode eq "200 OK">
			<cfset throwError(message="Error accessing Google API: #cfhttp.statuscode#",endpoint="https://www.googleapis.com/oauth2/v1/tokeninfo",response=cfhttp.filecontent,argumentCollection=arguments) />
		</cfif>
		
		<cfset stResult = deserializeJSON(cfhttp.FileContent.toString()) />
		
		<cfif structkeyexists(stResult,"error")>
			<cfset throwError(message="Error accessing Google API: #stResult.error#",endpoint="https://www.googleapis.com/oauth2/v1/tokeninfo",response=cfhttp.filecontent,argumentCollection=arguments) />
		<cfelseif stResult.audience neq arguments.clientID>
			<cfset throwError(message="Error accessing Google API: Authorisation is for the wrong application",endpoint="https://www.googleapis.com/oauth2/v1/tokeninfo",response=cfhttp.filecontent,argumentCollection=arguments) />
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getGoogleProfile" access="private" output="false" returntype="struct">
		<cfargument name="accessToken" type="string" required="true" />
		<cfargument name="proxy" type="string" required="false" default="" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stResult = structnew() />
		<cfset var stProxy = parseProxy(arguments.proxy) />
		
		<cfhttp url="https://www.googleapis.com/oauth2/v1/userinfo" method="GET" attributeCollection="#stProxy#">
			<cfhttpparam type="header" name="Authorization" value="Bearer #arguments.accessToken#" />
		</cfhttp>

		<cfif not cfhttp.statuscode eq "200 OK">
			<cfset throwError(message="Error accessing Google API: #cfhttp.statuscode#",endpoint="https://www.googleapis.com/oauth2/v1/userinfo",response=cfhttp.filecontent,argumentCollection=arguments) />
		</cfif>
		
		<cfset stResult = deserializeJSON(cfhttp.FileContent.toString()) />
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="getRedirectURL" access="public" output="false" returntype="string" hint="For use with getAuthorisationURL and getRefreshToken">
		
		<cfreturn "http://#cgi.http_host##application.url.webroot#/index.cfm?type=gudLogin&view=displayLogin" />
	</cffunction>
	
	<cffunction name="throwError" access="private" output="false" returntype="void">
		<cfargument name="message" type="string" required="true" />
		
		<cfset var stLog = application.fc.lib.error.collectRequestInfo() />
		
		<cfset structappend(stLog,arguments) />
		<cfset stLog.stack = application.fc.lib.error.getStack(true,false,1) />
		<cfset stLog.logtype = "GUD" />
		
		<cfset application.fc.lib.error.logData(stLog,false,false) />
		
		<cfthrow message="#arguments.message#" detail="#serializeJSON(arguments)#" />
	</cffunction>
	
</cfcomponent>