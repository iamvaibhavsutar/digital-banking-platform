# Certificate expiry / TLS failure

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
x509 errors in logs, browsers warn, cert-manager Certificate not Ready, kubeadm certs near expiry.

## Impact
Clients cannot connect or Fluent Bit stops shipping (silent).

## Investigate (commands)
```bash
kubectl -n banking describe certificate bank-tls | tail -20
sudo kubeadm certs check-expiration
kubectl -n logging logs ds/fluent-bit --tail=20 | grep -i -E 'tls|x509'
```

## Mitigate / Fix
cert-manager: check the Issuer and events, delete the failed CertificateRequest to retry. kubeadm: sudo kubeadm certs renew all (backup /etc/kubernetes/pki first) and restart control-plane static pods.

## Prevention
Short-lived auto-renewed certificates, CertificateExpiringSoon alert, yearly kubeadm upgrade.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
