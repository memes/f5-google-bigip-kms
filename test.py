from typing import Dict

import pytest
import requests
from testinfra.host import Host

labels = {'use-case': 'kms-test'}


@pytest.fixture
def hosts(find_hosts, label_filter) -> Dict[str, Host]:
    filter = label_filter(labels=labels)
    return find_hosts(filter=filter)


@pytest.fixture
def endpoints(find_endpoints, label_filter) -> Dict[str, str]:
    filter = label_filter(labels=labels)
    return find_endpoints(filter=filter)


def test_hosts(hosts: Dict[str, Host], bigip_is_ready, bigip_is_licensed) -> None:
    assert len(hosts) > 0

    for name, host in hosts.items():
        print('Validating {}'.format(name))
        bigip_is_ready(name, host)
        bigip_is_licensed(name, host)


def test_services(endpoints: Dict[str, str]) -> None:
    assert len(endpoints) > 0

    for name, endpoint in endpoints.items():
        print('Testing {}'.format(name))
        resp = requests.get('http://{0}/'.format(endpoint))
        assert resp.status_code == 200, 'HTTP response from {} has unexpected status code'.format(
            name)
        assert resp.text == 'OK', 'HTTP response from {} has unexpected body'.format(
            name)
        resp = requests.get('https://{0}/'.format(endpoint), verify=False)
        assert resp.status_code == 200, 'HTTPS response from {} has unexpected status code'.format(
            name)
        assert resp.text == 'OK', 'HTTPS response from {} has unexpected body'.format(
            name)
