[![Build Status](https://travis-ci.org/open-io/ansible-role-openio-oioswift.svg?branch=master)](https://travis-ci.org/open-io/ansible-role-openio-oioswift)
# Ansible role `oioswift`

An Ansible role for deploy an OpenIO swift gateway.
Specifically, the responsibilities of this role are to:

- Install package
- Configure typed pipeline
- Configure middleware filter

## Requirements

- Ansible 2.4+

## Role Variables


| Variable   | Default | Comments (type)  |
| :---       | :---    | :---             |
| `openio_oioswift_app_proxy_server` | `dict` | Options of proxy-server  |
| `openio_oioswift_backup_file_modifications` | `true` | Create a backup file including the timestamp information |
| `openio_oioswift_bind_address` | `hostvars[inventory_hostname]['ansible_' + openio_oioswift_bind_interface]['ipv4']['address']` | IP address to use |
| `openio_oioswift_bind_interface` | `ansible_default_ipv4.alias` | NIC name to use |
| `openio_oioswift_bind_port` | `6007` | Port to use |
| `openio_oioswift_filter_*` | `dict` | Options of most used middleware |
| `openio_oioswift_gridinit_dir` | `/etc/gridinit.d/{{ openio_oioswift_namespace }}` | Path to copy the gridinit conf |
| `openio_oioswift_gridinit_file_prefix` | `""` | Maybe set it to `{{ openio_oioswift_namespace }}-` for legacy gridinit's style |
| `openio_oioswift_inventory_groupname` | `""` | Set your inventory groupname to auto feed memcached server on port `6019` |
| `openio_oioswift_log_level` | `INFO` | Log level |
| `openio_oioswift_namespace` | `OPENIO` | OpenIO namespace for this proxy swift |
| `openio_oioswift_pipeline` | ` pipeline_keystone` | `list` of middleware. Some preconfigured are available in `vars/main.yml` |
| `openio_oioswift_proxy_bind_address` | `openio_oioswift_bind_address` | Listen address for the proxy swift ('0.0.0.0' is possible) |
| `openio_oioswift_sds_auto_storage_policies` | `[]` | Setup default policie and limits. Example: `['EC','THREECOPIES:1','EC:262144']` defines `Erasur Code`as default policy and THREECOPIES from 1 byte to `262143`|
| `openio_oioswift_sds_connection_timeout` | `5` | Timeout for SDS requests |
| `openio_oioswift_sds_default_account` | `default` | Default Account/Project in OpenIO SDS |
| `openio_oioswift_sds_max_retries` | `0` | Maximum retries |
| `openio_oioswift_sds_oio_storage_policies` | `[]` | Available sotrage policies |
| `openio_oioswift_sds_pool_connections` | `50` | Pool of connection to SDS |
| `openio_oioswift_sds_pool_maxsize` | `50` | Maximum size of pool connection |
| `openio_oioswift_sds_proxy_namespace` | `"openio_oioswift_namespace"` | OpenIO namespace of the oioproxy & rawx  |
| `openio_oioswift_sds_proxy_url` | `http://{{ openio_oioswift_bind_address }}:6006` | Address of the oioproxy used |
| `openio_oioswift_sds_read_timeout` | `35` | Timeout for read operations |
| `openio_oioswift_sds_version` | `latest` | Version of the `openio-sds-server` package  |
| `openio_oioswift_sds_write_timeout` | `35` | Timeout for write operations |
| `openio_oioswift_serviceid` | `0` | Service Id in gridinit |
| `openio_oioswift_swift_constraints` | `list` | The swift-constraints section sets the basic constraints on data saved in the swift cluster |
| `openio_oioswift_swift3_version` | `latest` | Version of the `openio-sds-swift-plugin-s3` package |
| `openio_oioswift_version` | `latest` | Version of the `openio-sds-swift` package |
| `openio_oioswift_workers` | `3 ansible_processor_vcpus / 4` | Number of threads to process requests |
| `openio_oioswift_provision_only` | `false` | Provision only without restarting services |

## Dependencies

No dependencies.

## Example Playbook

### Tempauth
```yaml
- hosts: all
  become: true
  vars:
    NS: OPENIO
  roles:
    - role: users
    - role: repository
    - role: gridinit
    - role: memcached
    - role: oioswift
      openio_oioswift_bind_interface: bond0
      openio_oioswift_pipeline: "{{ pipeline_tempauth }}"
      openio_oioswift_filter_tempauth:
        use: "egg:swift#tempauth"
        user_me_myproject: "MY_PASS .admin"
```

### Keystone
```yaml
- hosts: all
  become: true
  vars:
    NS: OPENIO
  roles:
    - role: users
    - role: repository
    - role: gridinit
    - role: memcached
    - role: keystone
      openio_keystone_nodes_group: all
      openio_keystone_database_engine: sqlite
      openio_keystone_services_to_bootstrap:
        - name: keystone
          user: admin
          password: ADMIN_PASS
          project: admin
          role: admin
          regionid: "us-east-1"
          adminurl: "http://{{ VIP.address }}:35357"
          publicurl: "http://{{ VIP.address }}:5000"
          internalurl: "http://{{ VIP.address }}:5000"
      openio_keystone_services:
        - name: openio-swift
          type: object-store
          description: OpenIO SDS swift proxy
          endpoint:
            - interface: admin
              url: "http://{{ VIP.address }}:6007/v1/AUTH_%(tenant_id)s"
            - interface: internal
              url: "http://{{ VIP.address }}:6007/v1/AUTH_%(tenant_id)s"
            - interface: public
              url: "http://{{ VIP.address }}:6007/v1/AUTH_%(tenant_id)s"

    - role: oioswift
      openio_oioswift_bind_interface: bond0
      openio_oioswift_workers: 1
      openio_oioswift_pipeline: "{{ pipeline_keystone }}"
      openio_oioswift_filter_authtoken:
        paste.filter_factory: keystonemiddleware.auth_token:filter_factory
        auth_type: password
        auth_url: "http://{{ VIP.address }}:35357"
        www_authenticate_uri: "http://{{ VIP.address }}:5000"
        insecure: "True"
        region_name: "us-east-1"
        project_domain_id: default
        user_domain_id: default
        project_name: service
        username: swift
        password: SWIFT_PASS
        delay_auth_decision: "True"
        include_service_catalog: "False"
        memcached_servers: "ks1:6019,ks2:6019"
        cache: swift.cache
        token_cache_time: 300
        revocation_cache_time: 60
        memcache_security_strategy: ENCRYPT
        memcache_secret_key: memcache_secret_key
      openio_oioswift_filter_s3token:
        use: "egg:swift3#s3token"
        delay_auth_decision: "True"
        auth_uri: "http://{{ VIP.address }}:35357/"
```


```ini
[all]
node1 ansible_host=192.168.1.173
```
## Pipeline / Middleware

Middleware available in the template

* catch_errors
* gatekeeper
* healthcheck
* proxy-logging
* cache
* bulk
* tempurl
* swift3
* tempauth
* copy
* container_quotas
* account_quotas
* slo
* dlo
* verb_acl
* versioned_writes
* ratelimit
* hashedcontainer
* s3token
* authtoken
* keystoneauth
* container_hierarchy
* regexcontainer
* staticweb
* crossdomain
* keymaster
* encryption

You can compose your own pipeline by redefining the variable `openio_oioswift_pipeline`


```yaml
openio_oioswift_pipeline:
  - catch_errors
  - gatekeeper
  - healthcheck
  - proxy-logging
  - cache
  - bulk
  - tempurl
```

### Cache Filter

If you set your inventory groupname in `openio_oioswift_inventory_groupname`, the `memcache_servers` option will be feed by the `openio_oioswift_bind_interface` and the default port (6019) of each servers

## Contributing

Issues, feature requests, ideas are appreciated and can be posted in the Issues section.

Pull requests are also very welcome.
The best way to submit a PR is by first creating a fork of this Github project, then creating a topic branch for the suggested change and pushing that branch to your own fork.
Github can then easily create a PR based on that branch.

## License

GNU AFFERO GENERAL PUBLIC LICENSE, Version 3

## Contributors

- [Cedric DELGEHIER](https://github.com/cdelgehier) (maintainer)
