## I. Introduction

>[!NOTE]
>An example of how these initial steps in *Part I. Introduction* can be automated to be provided at later time for 'zero touch' provisioning.

Deploy two tenants on separate rSeries appliances. BIGIP1 on the first appliance and BIGIP2 on the second appliance.

Login to the Configuration Utility (WebUI) of BIGIP1.

Change admin password.

Change admin user's shell from 'none' to 'advanced shell'.

[Install iControl LX extensions](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/installation.html):
- [AS3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/)
- [DO](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/)
- [TS](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/)

The hostnames of our two example BIG-IP tenants are:

- BIGIP1 is r10900-1-tenant-1.local
- BIGIP2 is r10900-2-tenant-1.local

Create host records on each BIG-IP and provision extra management memory.

```bash
tmsh modify sys global-settings remote-host add { r10900-1-tenant-1.local {hostname r10900-1-tenant-1.local addr 10.10.10.10}}
tmsh modify sys global-settings remote-host add { r10900-2-tenant-1.local {hostname r10900-2-tenant-1.local addr 10.10.10.20}}
tmsh modify sys db provision.extramb value 2048
tmsh modify cli preference list-all-properties disabled
bigstart restart restjavad
bigstart restart restnoded
tmsh save sys config
```

Repeat the steps above on BIGIP2.

## II. Postman

Disable `SSL certificate verification` in settings.

Import the Postman collection and environment files _directly_ from the links below into Postman.

Postman collection:
```
https://raw.githubusercontent.com/tmarfil/20240430_poc/main/PoC.postman_collection.json
```
Postman environment:
```
https://raw.githubusercontent.com/tmarfil/20240430_poc/main/Env1.postman_environment.json
```
Edit the environment with _your_ values. The values below are just an example.

| key                      | value                   | notes                                                                                                                                                                                                                                                                   |
| ------------------------ | ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| BIGIP1                   | 10.10.10.10             | Management IP address of BIGIP1                                                                                                                                                                                                                                         |
| BIGIP2                   | 10.10.10.20             | Management IP address of BIGIP2                                                                                                                                                                                                                                         |
| ADMIN_USERNAME           | admin                   |                                                                                                                                                                                                                                                                         |
| ADMIN_PASSWORD           | mySecretPass            |                                                                                                                                                                                                                                                                         |
| OUTSIDE_VLAN             | outside1_on_tenant1     | VLANs are created at the F5OS platform later and then exposed to the BIG-IP tenant                                                                                                                                                                                     |
| INSIDE_VLAN              | inside1_on_tenant1      | ""                                                                                                                                                                                                                                                                      |
| BIGIP1_INSIDE_SELF_IP    | 10.91.10.20/24          |                                                                                                                                                                                                                                                                         |
| BIGIP1_OUTSIDE_SELF_IP   | 10.91.20.20/24          |                                                                                                                                                                                                                                                                         |
| BIGIP2_INSIDE_SELF_IP    | 10.91.10.21/24          |                                                                                                                                                                                                                                                                         |
| BIGIP2_OUTSIDE_SELF_IP   | 10.91.20.21/24          |                                                                                                                                                                                                                                                                         |
| INSIDE_FLOATING_SELF_IP  | 10.91.10.25/24          |                                                                                                                                                                                                                                                                         |
| OUTSIDE_FLOATING_SELF_IP | 10.91.20.25/24          |                                                                                                                                                                                                                                                                         |
| BIGIP1_HOSTNAME          | r10900-1-tenant-1.local | Must be an FDQN resolvable from both BIGIP1 and BIGIP2. We created a manual hosts file entry in a previous step to ensure name resolution works.                                                                                                                        |
| BIGIP2_HOSTNAME          | r10900-2-tenant-1.local | ""                                                                                                                                                                                                                                                                      |
| DNS_NAME_SERVER          | 10.53.53.53             |                                                                                                                                                                                                                                                                         |
| NTP_SERVER               | pool.ntp.org            |                                                                                                                                                                                                                                                                         |
| BIGIP1-X-F5-Auth-Token   |                         | Leave **BIGIP1-X-F5-Auth-Token** and **BIGIP2-X-F5-Auth-Token** empty for now. We will request an authentication token in a later step.<br><br>Once the BIG-IP devices are clustered you can use the same **BIGIP1-X-F5-Auth-Token** value for _both_ BIGIP1 and BIGIP2 |
| BIGIP2-X-F5-Auth-Token   |                         | ""                                                                                                                                                                                                                                                                      |


## III. Build HA Cluster

Open an SSH terminal session to both BIGIP1 and BIGIP2. Monitor API requests for errors:

```bash
tail -f /var/log/restnoded/restnoded.log
```

Run the Postman tasks in the **PoC** Collection in sequential order.

### Step 1: BIGIP1 Check DO Version
This step uses basic authentication to verify the Declarative Onboarding (DO) API endpoint is ready to receive requests.

### Step 2: BIGIP2 Check DO Version
Same as previous step, but for BIGIP2.

### Step 3: BIGIP1 request X-F5-Auth-Token
Toggle the HTTP method to `POST`. This step uses basic authentication to request a token. You can then use this token value inside of the 'X-F5-Auth-Token' header for subsequent API requests. More info: https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/authentication.html

### Step 4: BIGIP2 request X-F5-Auth-Token Copy
Toggle the HTTP method to `POST`. Same as previous step, but for BIGIP2.

### Step 5: BIGIP1 Cluster Onboarding
Toggle the HTTP method to `POST`. Use the token you received in the body of the response from the previous step to provide a value for the X-F5-Auth-Token header. You will fail authentication otherwise. You can POST Step 5 and Step 6 one right after the other. After POSTing, you can toggle the method from POST to GET and track the status of the API task until you receive a status code 200 (success) or work through any errors.

### Step 6: BIGIP2 Cluster Onboarding
Toggle the HTTP method to `POST`. Same as above, but for BIGIP2

## IV. Create Example Virtual Server

### Step 1: BIGIP1 Check AS3

### Step 2: BIGIP2 Check AS3

### Step 3: Create Virtual Server with iRule
When creating a Virtual Server, you only need to POST an AS3 declaration to one of the devices in the HA cluster, and the HA config sync will sync the configuration changes automatically.

This example creates a Virtual Server using the default 'clientssl' TLS profile and responds to HTTPS requests via the 'WebServer' iRule.

### Step 4: Step 4: Create Virtual Server with Pool Members
