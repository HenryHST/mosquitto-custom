# Vendored mosquitto-go-auth

Upstream: [iegomez/mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth) tag **3.0.0**  
Commit: `2d2480add26eb4f1e7923a169e813228eb5c87eb`  
License: MIT (see `LICENSE`)

This tree is a **maintenance fork** inside `mosquitto-custom` (not a git submodule).
Standalone and Home Assistant images build `go-auth.so` from here.

## Local patches (vs upstream 3.0.0)

| Change | Reason |
|--------|--------|
| `cache/cache.go` nil guard before `item.Value()` | Avoid panic if TTL expires between `Has` and `Get` |
| `go.mod`: `mattn/go-sqlite3@v1.14.24` | Alpine/musl build (`pread64` / `off64_t`) |
| `Makefile`: `/usr/include`, `-fuse-ld=bfd`, unresolved-symbols | Alpine headers + linker; Mosquitto plugin ABI |
| LDAP logging / ACL error text | Safer logs; correct option name `ldap_group_dn`; superuser empty-result returns `(false, nil)` |

## LDAP examples

### Authentik LDAP Outpost (group membership)

```conf
auth_opt_backends ldap
auth_opt_ldap_url ldap://ak-outpost-ldap.example.svc:389
auth_opt_ldap_user_dn ou=users,dc=ldap,dc=example,dc=com
auth_opt_ldap_group_dn ou=groups,dc=ldap,dc=example,dc=com
auth_opt_ldap_bind_dn cn=ldapservice,ou=users,dc=ldap,dc=example,dc=com
auth_opt_ldap_bind_password CHANGE_ME
auth_opt_ldap_user_filter (&(cn=%s)(|(memberOf=cn=mqtt_users,ou=groups,dc=ldap,dc=example,dc=com)(memberOf=cn=mqtt_admins,ou=groups,dc=ldap,dc=example,dc=com)))
auth_opt_ldap_superuser_filter (&(cn=%s)(memberOf=cn=mqtt_admins,ou=groups,dc=ldap,dc=example,dc=com))
```

### lldap (uid-based)

```conf
auth_opt_backends ldap
auth_opt_ldap_url ldap://lldap:3890
auth_opt_ldap_user_dn ou=people,dc=example,dc=com
auth_opt_ldap_group_dn ou=groups,dc=example,dc=com
auth_opt_ldap_bind_dn uid=mosquitto,ou=people,dc=example,dc=com
auth_opt_ldap_bind_password changeit
auth_opt_ldap_user_filter (&(uid=%s)(objectClass=person)(memberOf=mqtt))
auth_opt_ldap_superuser_filter (&(uid=%s)(objectClass=person)(memberOf=mqtt_superuser))
auth_opt_ldap_group_filter (member=%s)
auth_opt_ldap_acl_topic_pattern_attribute mqtt_topic_pattern
auth_opt_ldap_acl_acc_attribute mqtt_topic_acc
```

When ACL attributes are set, `ldap_group_dn` is required. Without ACL attributes, authenticated users get full pub/sub (upstream behaviour).

## Build

```bash
# Linux/Alpine-like (needs mosquitto headers)
make

# Tests (needs optional backend services for full suite)
go test ./cache ./hashing ./backends -count=1
```
