# NetBoxing

Text in this document is automatically created - don't change it manually

## Index

[Connect-Netbox](#Connect-Netbox)<br>
[Find-NetboxObject](#Find-NetboxObject)<br>
[Invoke-NetboxPatch](#Invoke-NetboxPatch)<br>
[Invoke-NetboxRequest](#Invoke-NetboxRequest)<br>
[Invoke-NetboxUpsert](#Invoke-NetboxUpsert)<br>

## Functions

<a name="Connect-Netbox"></a>
### Connect-Netbox

```

NAME
    Connect-Netbox
    
SYNOPSIS
    Connect to NetBox
    
    
SYNTAX
    Connect-Netbox [-Uri] <String> [-Token] <String> [<CommonParameters>]
    
    
DESCRIPTION
    Connect to Netbox.
    Or that is, tell the PowerShell module URI and token - so the other functions in the module know what to connect to.
    This function doesn't actually connect to anything.
    

PARAMETERS
    -Uri <String>
        Uri. Eg. https://netbox.yourdomain.tld
        
    -Token <String>
        API token created in NetBox
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Connect-Netbox -Uri https://netbox.yourdomain.tld -Token abcabcabc
    
    
    
    
    
    
REMARKS
    To see the examples, type: "get-help Connect-Netbox -examples".
    For more information, type: "get-help Connect-Netbox -detailed".
    For technical information, type: "get-help Connect-Netbox -full".

```

<a name="Find-NetboxObject"></a>
### Find-NetboxObject

```
NAME
    Find-NetboxObject
    
SYNOPSIS
    Find object(s) in NetBox
    
    
SYNTAX
    Find-NetboxObject [-Uri] <String> [-Properties] <Hashtable> [[-FindBy] <String[]>] [<CommonParameters>]
    
    
DESCRIPTION
    Find object(s) in NetBox
    

PARAMETERS
    -Uri <String>
        Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")
        
    -Properties <Hashtable>
        Hashtable with properties
        
    -FindBy <String[]>
        Which properties should be used to find object
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Find-NetboxObject -Uri ipam/prefixes/ -Properties @{vlan = @{vid = 3999}}
    
    Find all prefixes attaced to VLAN 3999.
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Find-NetboxObject -Uri ipam/prefixes/ -FindBy 'vlan.vid' -Properties @{vlan = @{vid = 3999}; otherproperty='foobar'}
    
    Find all prefixes attaced to VLAN 3999. "otherproperty" is ignored in search.
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>Find-NetboxObject ipam/vlans/ -Properties @{group=@{slug='test'}} -FindBy 'group=group.slug'
    
    Find all VLANs belonging to VLAN group "test".
    Sometimes the NetBox API want queries "different". It's not "?group_slug=test" but "?group=test"
    If the "Findby" is omitted in this example, then NetBox will return all VLAN objects back, and the filtering will be done only on client side.
    Stuff like "Got 18 objects back from server and returned 2" can be seen in verbose output.
    
    
    
    
REMARKS
    To see the examples, type: "get-help Find-NetboxObject -examples".
    For more information, type: "get-help Find-NetboxObject -detailed".
    For technical information, type: "get-help Find-NetboxObject -full".

```

<a name="Invoke-NetboxPatch"></a>
### Invoke-NetboxPatch

```
NAME
    Invoke-NetboxPatch
    
SYNOPSIS
    Patch object in Netbox
    
    
SYNTAX
    Invoke-NetboxPatch [[-Uri] <String>] [[-Item] <PSObject>] [-Changes] <Hashtable> [-NoUpdate] [-Wait] [<CommonParameters>]
    
    
DESCRIPTION
    Patch object in Netbox
    

PARAMETERS
    -Uri <String>
        Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")
        
    -Item <PSObject>
        Original unpatched object
        
    -Changes <Hashtable>
        Hashtable with changes to be made to object
        
    -NoUpdate [<SwitchParameter>]
        Don't update object, only show what would be sent to server (as a warning)
        
    -Wait [<SwitchParameter>]
        After patch is sent to NetBox, wait with a "Press enter to continue" prompt
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Invoke-NetboxPatch -Uri tenancy/tenants/3/ -Changes @{description = 'example'}
    
    Patch tenant 3 with description.
    This is always sent to Netbox, even if description hasn't changes.
    The function doesn't know the previous state of the properties.
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>$v = Invoke-NetboxRequest ipam/vlans/1/ ; Invoke-NetboxPatch -Item $v -Changes @{description = 'example'}
    
    Fetch VLAN object with id 1 and change description.
    If description is already correct, then a patch request isn't sent to Netbox.
    Old versions of Netbox didn't have an "url" property in objects. If that's the case, then this should be added:
     -Uri "ipam/vlans/$($v.id)/"
    
    
    
    
REMARKS
    To see the examples, type: "get-help Invoke-NetboxPatch -examples".
    For more information, type: "get-help Invoke-NetboxPatch -detailed".
    For technical information, type: "get-help Invoke-NetboxPatch -full".

```

<a name="Invoke-NetboxRequest"></a>
### Invoke-NetboxRequest

```
NAME
    Invoke-NetboxRequest
    
SYNOPSIS
    Send HTTP request to NetBox
    
    
SYNTAX
    Invoke-NetboxRequest [-Uri] <String> [-Method {Default | Get | Head | Post | Put | Delete | Trace | Options | Merge | Patch}] [-Body <PSObject>] [-FullResponse] [-Follow] [<CommonParameters>]
    
    
DESCRIPTION
    Send HTTP request to NetBox
    

PARAMETERS
    -Uri <String>
        Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")
        
    -Method
        HTTP method
        Get, Post, ...
        
    -Body <PSObject>
        Object (or hashtable) that should be sent if Method is POST or PATCH
        
    -FullResponse [<SwitchParameter>]
        Return the full object returned from Netbox - and not only the "relevant" part
        
    -Follow [<SwitchParameter>]
        If result from NetBox contains more than 50 objects, then follow next-page links and get it all
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Invoke-NetboxRequest dcim/sites/ -Follow
    
    Fetch all sites from NetBox
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Invoke-NetboxRequest -Uri https://netbox.yourdomain.tld/api/dcim/sites/1/
    
    Fetch site with ID 1 from Netbox
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>Invoke-NetboxRequest -Uri tenancy/tenants/ -Method Post -Body @{name='Example Tenant'; slug='example-tenant'}
    
    Create new tenant
    
    
    
    
REMARKS
    To see the examples, type: "get-help Invoke-NetboxRequest -examples".
    For more information, type: "get-help Invoke-NetboxRequest -detailed".
    For technical information, type: "get-help Invoke-NetboxRequest -full".

```

<a name="Invoke-NetboxUpsert"></a>
### Invoke-NetboxUpsert

```
NAME
    Invoke-NetboxUpsert
    
SYNOPSIS
    Update (patch) or create NetBox object
    
    
SYNTAX
    Invoke-NetboxUpsert [-Uri] <String> [-Properties] <Hashtable> [[-PropertiesNew] <Hashtable>] [-FindBy] <String[]> [[-Item] <PSObject[]>] [-Multi] [-NoCreate] [-NoUpdate] [-Wait] [<CommonParameters>]
    
    
DESCRIPTION
    Update (patch) or create NetBox object
    If existing object is found
    

PARAMETERS
    -Uri <String>
        Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")
        
    -Properties <Hashtable>
        Properties that should be set when updating or creating object
        
    -PropertiesNew <Hashtable>
        Properties that should only be set when creating object - not when updating
        
    -FindBy <String[]>
        Which properties should be used to find existing object
        
    -Item <PSObject[]>
        Existing NetBox object can be passed (normally not used).
        
    -Multi [<SwitchParameter>]
        Changes to multiple objects is allowed.
        Normally only changes to one object is allowed.
        If this is set, no new objects will be created, only existing will be updated.
        
    -NoCreate [<SwitchParameter>]
        Don't create object, only show what would be sent to server (as a warning)
        
    -NoUpdate [<SwitchParameter>]
        Don't update object, only show what would be sent to server (as a warning)
        
    -Wait [<SwitchParameter>]
        After post/patch is sent to NetBox, wait with a "Press enter to continue" prompt
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Invoke-NetboxUpsert -Uri ipam/prefixes/ -FindBy 'prefix' -Properties @{prefix='10.0.0.0/30'; description='example'}
    
    If prefix 10.0.0.0/30 already exist, then set description. If it doesn't exist, then create it.
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Invoke-NetboxUpsert -Uri ipam/prefixes/ -FindBy 'vlan.vid' -Properties @{vlan=@{vid=3999}; description='example'} -Multi -NoUpdate
    
    Find all prefixes attached to VLAN 3999 and show which changes that should be made (as warning).
    Remove -NoUpdate to send patch requests to NetBox
    
    
    
    
REMARKS
    To see the examples, type: "get-help Invoke-NetboxUpsert -examples".
    For more information, type: "get-help Invoke-NetboxUpsert -detailed".
    For technical information, type: "get-help Invoke-NetboxUpsert -full".

```



