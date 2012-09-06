<cfcomponent displayname="Google User Directory" extends="farcry.core.packages.forms.forms" output="false" key="gud">
	
	<cfproperty ftSeq="1" ftFieldset="Google Analytics API Access" ftLabel="Proxy" 
				name="proxy" type="string" 
				ftHint="If internet access is only available through a proxy, set here. Use the format '[username:password@]domain[:port]'."
				ftHelpSection="When you set up this config you will need to enter the redirect URL: http://[hostname]/index.cfm?type=gudLogin&view=displayLogin" />
				
	<cfproperty ftSeq="2" ftFieldset="Google Analytics API Access" ftLabel="Client ID" 
				name="clientID" type="string" 
				ftHint="This should be copied exactly from the <a href='https://code.google.com/apis/console'>API Console</a>." />
				
	<cfproperty ftSeq="3" ftFieldset="Google Analytics API Access" ftLabel="Client Secret" 
				name="clientSecret" type="string" 
				ftHint="This should be copied exactly from the <a href='https://code.google.com/apis/console'>API Console</a>." />
	
	
</cfcomponent>