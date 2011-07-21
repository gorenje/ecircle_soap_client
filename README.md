eCircle SOAP Client
===================

Warning
-------
Experimental code and not yet complete. Lots of testing are missing and functionality is limited.
Simple things like creating and deleting users and groups is possible, but message creation and
sending are not yet supported.

Description
-----------

Based on [Savon](http://savonrb.com/) and [Nokogiri](http://nokogiri.org/) and provides a simple interface for accessing the eCircle [WSDL synchronous API](http://www.soapclient.com/soapclient?template=%2Fclientform.html&fn=soapform&SoapTemplate=%2FSoapResult.html&SoapWSDL=http%3A%2F%2Fwebservices.ecircle-ag.com%2Fsoap%2Fecm.wsdl&_ArraySize=2).

Intention is to provide a ActiveRecord/ActiveModel-like interface to the individual entities provided by the SOAP API. It's far from complete and you can only do a few selected things with this gem.

Installation
------------

Currently only via bundle with:

```
gem 'ecircle_soap_client', :git => 'git://github.com/gorenje/ecircle_soap_client.git'
```

Usage
-----

Configration:

```
Ecircle.configure do |config|
  config.user     = "your@user.email.com"
  config.realm    = "http://example.com"
  config.password = "supersecret"
end
```

the WSDL settings are assumed to be

```
wsdl.document = "http://webservices.ecircle-ag.com/soap/ecm.wsdl"
wsdl.endpoint = "http://webservices.ecircle-ag.com/rpc"
wsdl.namespace = "http://webservices.ecircleag.com/rpcns"
```

but can be overridden in the configuration

```
Ecircle.configure do |config|
  config.wsdl.document = "http://example.com/?wsdl"
  config.wsdl.endpoint = "http://blah.com"
  config.wsdl.namespace = "some new namespace"
end
```

Having configured the client, User retrieval is done via email or id:

```
user = Ecircle::User.find_by_email("some@email.com")
user = Ecircle::User.find_by_id("1234131")
```

Logon is handled automagically by the Ecircle::Client, however the caller is responsible for
retrying requests if a Ecircle::Client::NotLoggedIn exception is raised. There no need to
explicitly call Ecircle::Client#logon, the exception notifies the client that it's not longer
logged in and needs to login before the next request.

Groups and Members
------------------

Having gotten a user, it's possible to find their memeberships of groups

```
groups = user.membership
```

Now a new user can be added to a group

```
member = groups.first.add_member Ecircle::User.create_by_email( "another@email.com" )
```

But if the member should be deleted from the group again

```
member.delete
```

