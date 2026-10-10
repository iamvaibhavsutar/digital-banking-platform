# Service Level Objectives

| SLI | Definition | SLO (30 days) |
|---|---|---|
| Availability | requests not answered with 5xx / all requests, services `*-service` | 99.9% |
| Latency | requests answered in under 300 ms | 95% |

* Error budget: 0.1% = **43.2 minutes per 30 days**.
* 4xx (including 422 insufficient funds) are customer mistakes and do NOT count against the budget.
* Alerts (see `deploy/monitoring/prometheusrules.yaml`): fast burn 14.4x over 1h AND 5m pages; slow burn 6x over 6h AND 30m opens a ticket.
* Edge view independent of the cluster: CloudWatch ALB 5xx and unhealthy-target alarms (`modules/monitoring`).
* Policy: budget left = ship faster; budget exhausted = freeze risky releases and fix reliability.
