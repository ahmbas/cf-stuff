require 'rest-client'
require 'json'
require "base64"
require 'fog/openstack'

def get_fog_object(provider, type, tenant)
  endpoint='publicURL'
  (provider.api_version == 'v2') ? (conn_ref = '/v2.0/tokens') : (conn_ref = '/v3/auth/tokens')
  (provider.security_protocol == 'non-ssl') ? (proto = 'http') : (proto = 'https')

  connection_hash = {
    :provider => 'OpenStack',
    :openstack_api_key => provider.authentication_password,
    :openstack_username => provider.authentication_userid,
    :openstack_auth_url => "#{proto}://#{provider.hostname}:#{provider.port}#{conn_ref}",
    # in a OSPd environment, this might need to be commented out depending on accessibility of endpoints
    :openstack_endpoint_type => endpoint,
    :openstack_tenant => tenant,
  }
  # if the openstack environment is using keystone v3, add two keys to hash and replace the auth_url
  if provider.api_version == 'v3'
    connection_hash[:connection_options] = {:ssl_verify_peer => false}
    connection_hash[:openstack_domain_id] = provider.uid_ems
    connection_hash[:openstack_project_name] = tenant
    connection_hash[:openstack_auth_url] = "#{proto}://#{provider.hostname}:#{provider.port}/#{conn_ref}"
  end
  return Object::const_get("Fog").const_get("#{type}").new(connection_hash)
end


vm = $evm.root['vm']
automated_floating_ip = vm.custom_get("automated_floating_ip")
if not automated_floating_ip.nil?
  tenant = $evm.vmdb(:cloud_tenant,vm.cloud_tenant_id)
  provider = vm.ext_management_system
  openstack_compute = get_fog_object(provider, 'Compute', tenant.name)
  openstack_compute.disassociate_address(vm.ems_ref, automated_floating_ip)
  openstack_compute.release_address(automated_floating_ip)
end
