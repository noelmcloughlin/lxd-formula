#!jinja|yaml
# -*- coding: utf-8 -*-
# vi: set ft=yaml.jinja :

{% from "lxd/map.jinja" import datamap, sls_block with context %}

lxd_selinux_mode:
  selinux.mode:
    - name: permissive
    - onlyif: test -f /etc/redhat-release 

lxd_lxc_upstream_repo:
  pkgrepo.managed:
    - humanname: Copr repo for lxc owned by ganto
    - baseurl: https://copr-be.cloud.fedoraproject.org/results/ganto/lxc/fedora-$releasever-$basearch/
    - gpgcheck: 1
    - gpgkey: https://copr-be.cloud.fedoraproject.org/results/ganto/lxc/pubkey.gpg
    - enabled: 1
    - require_in:
      - pkg: lxd_lxd
    - onlyif: test -f /etc/redhat-release 

lxd_lxd_upstream_repo:
  pkgrepo.managed:
    - humanname: Copr repo for lxd owned by ganto
    - baseurl: https://copr-be.cloud.fedoraproject.org/results/ganto/lxd/fedora-$releasever-$basearch/
    - gpgcheck: 1
    - gpgkey: https://copr-be.cloud.fedoraproject.org/results/ganto/lxd/pubkey.gpg
    - enabled: 1
    - require_in:
      - pkg: lxd_lxd
    - onlyif: test -f /etc/redhat-release 

lxd_subuid:
  file.append:
    - name: /etc/subuid
    - text: root:1000000:65536
    - require_in:
      - pkg: lxd_lxd
    - onlyif: test -f /etc/redhat-release 

lxd_subgid:
  file.append:
    - name: /etc/subgid
    - text: root:1000000:65536
    - require_in:
      - pkg: lxd_lxd
    - onlyif: test -f /etc/redhat-release 

lxd_lxd:
  pkg:
    - {{ datamap.lxd.package.action }}
    {{ sls_block(datamap.lxd.package.opts )}}
    - pkgs: {{ datamap.lookup.lxd.packages }}

lxd_lxd_service:
  service.running:
    - name: lxd
    - enable: True
    - require:
      - pkg: lxd_lxd
    - onlyif: test -f /etc/redhat-release 

{% if datamap.lxd.run_init %}
  lxd:
    - init
    - storage_backend: "{{ datamap.lxd.init.storage_backend }}"
    - trust_password: "{{ datamap.lxd.init.trust_password }}"
    - network_address: "{{ datamap.lxd.init.network_address }}"
    - network_port: "{{ datamap.lxd.init.network_port }}"
    - storage_create_device: "{{ datamap.lxd.init.storage_create_device }}"
    - storage_create_loop: "{{ datamap.lxd.init.storage_create_loop }}"
    - storage_pool: "{{ datamap.lxd.init.storage_pool }}"
    - done_file: "{{ datamap.lxd.init.done_file }}"
    - require:
      - pkg: lxd_lxd
      - sls: lxd.python
{% endif %}

{% for name, cdict in datamap.lxd.config.items() %}
lxd_config_{{ name }}:
  lxd:
    - config_managed
    - name: "{{ cdict.key }}"
    - value: "{{ cdict.value }}"
    - force_password: {{ cdict.get('force_password', False) }}
    - require:
      - pkg: lxd_lxd
      - sls: lxd.python
{% endfor %}
