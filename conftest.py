import json
import re
from typing import Any, Dict, Optional

import pytest
import testinfra
from google.cloud import compute_v1
from google.cloud.compute_v1.types import Instance


@pytest.fixture(scope="session")
def harness_values() -> Dict[str, Any]:
    """Extract the values written by tofu/terraform during resource creation."""
    with open("test/harness.json", mode='r') as harness:
        return json.load(harness)


@pytest.fixture(scope="session")
def project_id(harness_values: Dict[str, Any]) -> str:
    """Returns the project_id containing the BIG-IP resources."""
    assert harness_values['project_id']
    return harness_values['project_id']


@pytest.fixture(scope="session")
def prefix(harness_values: Dict[str, Any]) -> str:
    """Returns the test harness prefix string used to name resources."""
    assert harness_values['prefix']
    return harness_values['prefix']


@pytest.fixture(scope="session")
def ssh_privkey(harness_values: Dict[str, Any]) -> str:
    """Returns the path to the SSH private key to use."""
    assert harness_values['ssh_privkey']
    return harness_values['ssh_privkey']


@pytest.fixture(scope="session")
def zone(harness_values: Dict[str, Any]) -> str:
    """Returns the Compute Engine zone containing BIG-IP resources."""
    assert harness_values['zone']
    return harness_values['zone']


@pytest.fixture(scope="session")
def ssh_config(harness_values: Dict[str, Any]) -> str:
    """Returns the SSH config file to use for connections."""
    assert harness_values['ssh_config']
    return harness_values['ssh_config']


@pytest.fixture
def label_filter(prefix: str):

    def _builder(labels: Dict[str, str]) -> str:
        """Builds a CEL filter that will match instances with the supplied labels."""
        filters = list(map(lambda kv: 'labels.{0} = "{1}"'.format(
            kv[0], kv[1]), ({'group': prefix} | labels).items()))
        if len(filters) == 1:
            return filters[0]
        return ' AND '.join(map(lambda x: '({})'.format(x), filters))

    return _builder


def get_mgmt_public_address(instance: Instance) -> str:
    """Extract the public IP address of the instance's management interface."""
    assert instance.network_interfaces
    interface = instance.network_interfaces[min(
        len(instance.network_interfaces), 1)]
    assert interface
    assert interface.access_configs
    assert interface.access_configs[0]
    return interface.access_configs[0].nat_i_p


def get_ext_public_address(instance: Instance) -> str:
    """Extract the public IP address of the instance's external interface."""
    assert instance.network_interfaces
    interface = instance.network_interfaces[0]
    assert interface
    assert interface.access_configs
    assert interface.access_configs[0]
    return interface.access_configs[0].nat_i_p


@pytest.fixture
def find_hosts(project_id: str, zone: str, ssh_config: str):

    def _builder(filter: Optional[str]) -> Dict[str, testinfra.host.Host]:
        """Find the set of running instances and map into a labeled dictionary."""
        client = compute_v1.InstancesClient()
        req = compute_v1.ListInstancesRequest(
            project=project_id,
            zone=zone,
            filter=filter
        )
        results = client.list(request=req)
        return {k: v for k, v in map(lambda vm: (vm.name, testinfra.get_host(get_mgmt_public_address(vm), ssh_config=ssh_config)), results)}

    return _builder


@pytest.fixture
def find_endpoints(project_id: str, zone: str, ssh_config: str):

    def _builder(filter: Optional[str]) -> Dict[str, str]:
        """Find the set of running instances and map into a labeled dictionary."""
        client = compute_v1.InstancesClient()
        req = compute_v1.ListInstancesRequest(
            project=project_id,
            zone=zone,
            filter=filter
        )
        results = client.list(request=req)
        return {k: v for k, v in map(lambda vm: (vm.name, get_ext_public_address(vm)), results)}

    return _builder


@pytest.fixture(scope="session")
def bigip_is_ready():
    is_config_ready = re.compile('^config\s+yes$', re.MULTILINE)
    is_license_ready = re.compile('^license\s+yes$', re.MULTILINE)
    is_provision_ready = re.compile('^provision\s+yes$', re.MULTILINE)

    def _builder(name: str, host: testinfra.host.Host) -> None:
        stdout = host.check_output('tmsh show /sys ready')
        assert is_config_ready.search(
            stdout), '{} is not configured'.format(name)
        assert is_license_ready.search(
            stdout), '{} is not licensed'.format(name)
        assert is_provision_ready.search(
            stdout), '{} is not provisioned'.format(name)

    return _builder


@pytest.fixture(scope="session")
def bigip_is_licensed():
    cant_load_license = re.compile("^Can't load license")

    def _builder(name: str, host: testinfra.host.Host) -> None:
        stdout = host.check_output('tmsh show /sys license')
        assert not cant_load_license.search(
            stdout), '{} does not have an active license'

    return _builder
