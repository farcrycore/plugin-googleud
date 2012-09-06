<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: Summary options (CLIENTUD) --->
<!--- @@description: Farcry UD specific options --->

<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfset stUser = createObject("component", application.stcoapi["farUser"].packagePath).getByUserID(listfirst(stObj.username,"_")) />

<cfoutput>
	<li>
		<small>
			<a href="https://www.google.com/settings/account">Google Account Settings</a>
		</small>
	</li>
</cfoutput>

<cfsetting enablecfoutputonly="false" />