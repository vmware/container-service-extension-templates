# How to Enable TKGm with CSE 3.0.3

## Software requirements
TKGm can be enabled with CSE 3.0.3 only if VCD 10.2.2 or some VCD 10.2.z
update release is being used to provide the infrastructure, any other
version of VCD should not be used.

## Steps for Cloud Provider (Cloud Administrator)
Provider needs to
* Enable CSE server for TKGm
* Create TKGm template
* Enable Tenant OrgVDC for TKGm

### Enabling CSE server for TKGm
Generate CSE config file via `cse sample` command. Fill up the relevant details.
Add the following key in the config file
```sh
service:
  enable_tkg_m: true
```
Edit the `remote_template_cookbook_url` value under `broker` section to 
```sh
broker:
  remote_template_cookbook_url: "https://raw.githubusercontent.com/ltimothy7/container-service-extension-templates/tkgm/template.yaml"
```
Freshly install CSE 3.0.3 or upgrade existing CSE to CSE 3.0.3, using this
config file.

### Creating TKGm template
The CSE install/upgrade operation will create the TKGm template, if `-t` is
not used. However, if `-t` option is used, the template can be installed later
via
```sh
cse template install [Template name] [Template revision] -c [config file]
```
The template name and revision can be retrieved using
```sh
cse template list -c [config file]
```
Provider should make sure that the `remote_template_cookbook_url` points to the
`TKGm` template repository and not the standard CSE template repository.

### Enabling Tenant OrgVDC for TKGm
Once TKGm has been enabled for CSE server and the TKGm template is created,
provider should start up CSE server. With the CSE server running, provider
needs to use `vcd-cli` to instruct CSE to enable TKGm runtime on specific
tenant OrgVDC(s).

TKGm related options won't show up in `vcd-cli`, unless explicitly enabled.
To enable TKGm options in `vcd-cli`, set the following environment variable
```sh
export CSE_TKG_M_ENABLED=True
```

The following command will enable `TKGm` runtime on a specific OrgVDC,
```sh
vcd cse ovdc enable [OrgVDC name] -o [Org name] --tkg-m
```
Similarly to revoke TKGm runtime support from a specific OrgVDC, run
```sh
vcd cse ovdc disable [OrgVDC name] -o [Org name] --tkg-m
```

## Steps for Tenant users
Tenant users who have the CSE native rights and are able to deploy CSE native
clusters, will also be able to deploy TKGm clusters on OrgVDCs that are enabled
for TKGm runtime. They will need to enable `TKGm` options in `vcd-cli` via
setting the following environment variable.
```sh
export CSE_TKG_M_ENABLED=True
```
To deploy TKGm clusters, they can generate the sample specification yaml
for `vcd cse cluster apply` command via
```sh
vcd cse cluster apply --sample --tkg-m
```
Example,
```sh
.
.
api_version: ''
kind: TKGm
metadata:
  cluster_name: cluster_name
  org_name: organization_name
  ovdc_name: org_virtual_datacenter_name
spec:
  control_plane:
  .
  .
  .
```
Note, the value in `kind` field is not `native` but `TKGm`. This sample
specification file can be filed up and used with the command
```sh
vcd cse cluster apply [specification yaml]
```
to deploy TKGm clusters.

Read more about TKGm at [here](Link to Anupam's blog).