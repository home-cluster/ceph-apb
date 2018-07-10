FROM ansibleplaybookbundle/apb-base:canary

LABEL "com.redhat.apb.spec"=\
"dmVyc2lvbjogMS4wCm5hbWU6IGNlcGgtYXBiCmRlc2NyaXB0aW9uOiBQcm92aXNpb25zIGNvbnRh\
aW5lcml6ZWQgY2VwaCBpbnNpZGUgYSBrdWJlcm5ldGVzIG9yIG9wZW5zaGlmdCBjbHVzdGVyCmJp\
bmRhYmxlOiBGYWxzZQphc3luYzogb3B0aW9uYWwKbWV0YWRhdGE6CiAgZGlzcGxheU5hbWU6IGNl\
cGgtYXBiCnBsYW5zOgogIC0gbmFtZTogZGVmYXVsdAogICAgZGVzY3JpcHRpb246IFRoaXMgZGVm\
YXVsdCBwbGFuIGRlcGxveXMgY2VwaC1hcGIKICAgIGZyZWU6IFRydWUKICAgIG1ldGFkYXRhOgog\
ICAgICBkaXNwbGF5TmFtZTogQ2VwaCBjb250YWluZXJpemVkIHN0b3JhZ2UKICAgICAgbG9uZ0Rl\
c2NyaXB0aW9uOiBEZXBsb3lzIHJvb2sgd2l0aCBhIGNlcGggYmFja2VuZCBmb3IgY2x1c3RlciBz\
dG9yYWdlCiAgICBwYXJhbWV0ZXJzOiB7fSAgIyBUT0RPCg=="

ADD playbooks /opt/apb/actions
ADD . /opt/ansible/roles/ceph-apb

RUN chmod -R g=u /opt/{ansible,apb}

USER apb
