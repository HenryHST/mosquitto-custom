# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it by:

1. Opening a private security advisory on GitHub
2. Or emailing the maintainer directly (see GitHub profile)

**Please do not** open public issues for security vulnerabilities.

## Security Considerations

This Docker image packages:
- **Eclipse Mosquitto** - A widely-used MQTT broker
- **mosquitto-go-auth** - An authentication plugin (note: archived upstream project)

### Known Limitations

1. **mosquitto-go-auth upstream is archived** — this repo vendors a maintenance
   fork under `third_party/mosquitto-go-auth/`. Prefer `ldaps://`, short-lived
   credentials, and review [README.vendored.md](third_party/mosquitto-go-auth/README.vendored.md).

2. **LDAP Authentication** - Security recommendations:
   - Always use `ldaps://` (LDAP over TLS) when LDAP is not on a trusted network
   - Never store bind passwords in Git; use HA app options, Kubernetes Secrets, or secret managers
   - Implement network segmentation
   - Use strong TLS certificates from trusted CAs

3. **Advanced go_auth options** — `extra_options` can inject arbitrary `auth_opt_*`
   lines. Do not put secrets into the repository; never enable plugin debug logging
   in production.

4. **Multi-tenancy** - Configure proper ACLs to isolate topics between users/groups

5. **Monitoring** - Enable and monitor `$SYS/#` topics for anomalies

## Security Best Practices

### TLS/SSL Configuration
```conf
listener 8883
protocol mqtt
certfile /mosquitto/certs/tls.crt
keyfile /mosquitto/certs/tls.key
require_certificate false  # Set to true for mutual TLS
```

### LDAP Over TLS
```conf
auth_opt_ldap_url ldaps://ldap.example.com:636
```

### Kubernetes Secrets
```yaml
env:
  - name: LDAP_BIND_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mosquitto-ldap
        key: bind-password
```

### Network Policies
Restrict network access to the MQTT broker using Kubernetes NetworkPolicies or firewall rules.

### Regular Updates
- Monitor this repository for updates
- Track Eclipse Mosquitto security advisories
- Review [mosquitto-go-auth security considerations](https://github.com/iegomez/mosquitto-go-auth#security)

## CVE Tracking

Known CVEs affecting components:
- Check [Mosquitto CVE list](https://mosquitto.org/security/)
- Review dependencies in the Dockerfile

## Security Review

A comprehensive security review of mosquitto-go-auth was conducted. See:
- [minilab Issue #100](https://github.com/HenryHST/minilab/issues/100)
- Code review findings (internal documentation)

**Key findings summary:**
- Plugin suitable for controlled/private network environments
- Requires careful configuration to avoid security issues
- Not recommended for public internet-facing deployments without hardening

## Disclosure Timeline

Security issues will be disclosed following responsible disclosure practices:
1. Issue reported privately
2. Fix developed and tested
3. Security advisory published
4. Fixed version released
5. Public disclosure after users have time to update
