#### Connect-Netbox

# Connect to Netbox
$nbUri   = 'https://netbox.domain.tld'
$nbToken = 'ApiKeyGoesHere'  # If "PSVault" module is installed, then something like this could be used:
                             # $nbToken = (Get-VaultCredential -Name Netbox).GetNetworkCredential().Password
Connect-Netbox -Uri $nbUri -Token $nbToken



#### Invoke-NetboxRequest

# Fetch all sites from NetBox
Invoke-NetboxRequest dcim/sites/ -Follow

# Fetch site with ID 1 from Netbox
Invoke-NetboxRequest -Uri dcim/sites/1/

# Create new tenant
Invoke-NetboxRequest -Uri tenancy/tenants/ -Method Post -Body @{name='Example Tenant'; slug='example-tenant'}



#### Find-NetboxObject


# Find all prefixes attaced to VLAN 3999.
Find-NetboxObject -Uri ipam/prefixes/ -Properties @{vlan = @{vid = 3999}}

# Find all prefixes attaced to VLAN 3999. "otherproperty" is ignored in search.
Find-NetboxObject -Uri ipam/prefixes/ -FindBy 'vlan.vid' -Properties @{vlan = @{vid = 3999}; otherproperty='foobar'}

# Find all VLANs belonging to VLAN group "test".
# Sometimes the NetBox API want queries "different". It's not "?group_slug=test" but "?group=test"
# If the "Findby" is omitted in this example, then NetBox will return all VLAN objects back, and the filtering will be done only on client side.
# Stuff like "Got 18 objects back from server and returned 2" can be seen in verbose output.
Find-NetboxObject ipam/vlans/ -Properties @{group=@{slug='test'}} -FindBy 'group=group.slug'



#### Invoke-NetboxPatch (you would often use Invoke-NetboxUpsert instead!)

# Patch tenant 3 with description.
# This is always sent to Netbox, even if description hasn't changes.
# The function doesn't know the previous state of the properties.
Invoke-NetboxPatch -Uri tenancy/tenants/3/ -Changes @{description = 'example'}

# Fetch VLAN object with id 1 and change description.
# If description is already correct, then a patch request isn't sent to Netbox.
# Old versions of Netbox didn't have an "url" property in objects. If that's the case, then this should be added:
# -Uri "ipam/vlans/$($v.id)/"
$v = Invoke-NetboxRequest ipam/vlans/1/
Invoke-NetboxPatch -Item $v -Changes @{description = 'example'}



#### Invoke-NetboxUpsert

# If prefix 10.0.0.0/30 already exist, then set description. If it doesn't exist, then create it.
Invoke-NetboxUpsert -Uri ipam/prefixes/ -FindBy 'prefix' -Properties @{
    prefix='10.0.0.0/30'
    description='example'
}

# Find all prefixes attached to VLAN 3999 and show which changes that should be made (as warning).
# Remove -NoUpdate to send patch requests to NetBox
Invoke-NetboxUpsert -Uri ipam/prefixes/ -FindBy 'vlan.vid' -Properties @{vlan=@{vid=3999}; description='example'} -Multi -NoUpdate



#### Example on how to loop through structure and upsert info in NetBox (only update if there's changes)

$sites = @(
    @{
        name = 'netboxing-test-site1'
        devices = @(
            @{
                name = 'netboxing-test-dev1'
                nics = @(
                    @{name = 'netboxing-test-nic1-1'; ip = @('10.99.99.1','10.99.99.2')}
                    @{name = 'netboxing-test-nic1-2'; ip = @('10.99.99.3')}
                )
            }
            @{
                name = 'netboxing-test-dev2'
                nics = @(
                    @{name = 'netboxing-test-nic2-1'; ip = @('10.99.99.4')}
                )
            }
            @{
                name = 'netboxing-test-dev3'
                nics = @(
                    @{name = 'netboxing-test-nic3-1'}
                )
            }
        )
    }
    @{
        name = 'netboxing-test-site2'
    }
)

$ErrorActionPreference = 'Stop'
$nbRole = Invoke-NetboxUpsert -Uri dcim/device-roles/ -FindBy slug -Properties @{slug= 'netboxing-test-role1'; name = 'netboxing-test-role1'}
$nbManufacturer = Invoke-NetboxUpsert -Uri dcim/manufacturers/ -FindBy slug -Properties @{slug= 'netboxing-test-manufacturer1'; name = 'netboxing-test-manufacturer1'}
$nbType = Invoke-NetboxUpsert -Uri dcim/device-types/ -FindBy slug -Properties @{
    slug         = 'netboxing-test-type1'
    model        = 'netboxing-test-type1'
    manufacturer = @{slug = 'netboxing-test-manufacturer1'}
}
foreach ($site in $sites)
{
    $nbSite = Invoke-NetboxUpsert -Uri dcim/sites/ -FindBy name -Properties @{name = $site.name} -PropertiesNew @{slug = $site.name}
    foreach ($device in $site.devices)
    {
        $nbDevice = Invoke-NetboxUpsert -Uri dcim/devices/ -FindBy name -Properties @{name = $device.name} -PropertiesNew @{
            site        = @{slug = $site.name}
            device_role = @{slug = 'netboxing-test-role1'}
            device_type = @{slug = 'netboxing-test-type1'}
        }
        foreach ($nic in $device.nics)
        {
            # The difference between "Properties" and "PropertiesNew" is that PropertiesNew only gets 
            # send to NetBox when creating a new object, not when updating/patching and existing object.
            # So in this case, the "type" will not be changed to "other", if it's already another type in NetBox.
            # But "label" will be changed to "netboxing-test-label1", if it's something else in NetBox.
            $nbInterface = Invoke-NetboxUpsert -Uri dcim/interfaces/ -FindBy device.id,name -Properties @{
                name = $nic.name
                device = @{
                    id = $nbDevice.id
                }
                label = 'netboxing-test-label1'
            } -PropertiesNew @{
                type = @{
                    value     = 'other'  # Expand so "type=other" - and not "type={value=other}" when sending data to Netbox.
                    ___EXPAND = 'value'  # We could also just have written <Value='other'>, and avoided the "___EXPAND".
                }
            }
            foreach ($ip in $nic.ip)
            {
                $nbIp = Invoke-NetboxUpsert -Uri ipam/ip-addresses/ -FindBy interface_id=assigned_object_id,address -Properties @{
                    address              = "$ip/32"
                    assigned_object_type = 'dcim.interface'
                    assigned_object_id   = $nbInterface.id
                }
            }
        }
    }
}
