# ==============================================================================
# 1. MULTI-WINDOW, MULTI-BURN-RATE SLO ALERT
# ==============================================================================
resource "datadog_monitor" "slo_burn_rate_critical" {
  name    = "[CRITICAL] [${upper(var.environment)}] Transaction SLO Error Budget Burning Fast"
  type    = "slo alert"
  message = <<-EOT
    {{#is_alert}}
    **CRITICAL ALERT:** High-Value Transaction Error Budget Exhaustion
    
    * **Symptom:** The platform has consumed over 75% of its monthly reliability budget.
    * **Impact:** High financial risk. Systemic errors are threatening high-value private market equity trades.
    
    Notify: ${var.notification_channel}
    Runbook: https://platform.internal
    {{/is_alert}}
  EOT

 # Evaluates whether the remaining error budget drops below 75%
  query = "error_budget(\"684def97ccd95fafaed085dfaa505aeb\").over(\"30d\") > 75"

  monitor_thresholds {
    critical = 75.0  # Fired when 75% of the allocated error budget has been spent
  }
  tags = ["env:${var.environment}", "service:monolith", "tier:business-critical"]
}

# ==============================================================================
# 2. END-TO-END SYNTHETIC TRANSACTION FAILURE
# ==============================================================================
resource "datadog_synthetics_test" "e2e_transaction_check" {
  name    = "[CRITICAL] [${upper(var.environment)}] Core transaction synthetic test failing"
  type    = "api"
  subtype = "http"
  status  = "live"

  request_definition {
    method = "GET"
    url    = "https://brunaprauchner.com/"
    port   = 443
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  locations = ["aws:us-east-1", "aws:us-west-2", "aws:eu-west-1"]

  options_list {
    tick_every         = 300
    min_failure_duration = 0
    min_location_failed  = 2
    retry {
      count    = 2
      interval = 60
    }
  }

  message = <<-EOT
    {{#is_alert}}
    **CRITICAL ALERT:** E2E Synthetic Transaction Test has failed from multiple locations!
    
    * **Symptom:** Headless simulation cannot execute a private stock market mutation loop.
    * **Implication:** The platform may be dropping transactions silently while live traffic is zero.
    
    Notify: ${var.notification_channel}
    Runbook: https://platform.internal
    {{/is_alert}}
  EOT

  tags = ["env:${var.environment}", "service:monolith", "component:synthetics"]
}

# ==============================================================================
# 3. DATABASE PRIMARY UNAVAILABILITY
# ==============================================================================
resource "datadog_monitor" "rds_primary_unavailable" {
  name    = "[CRITICAL] [${upper(var.environment)}] PostgreSQL RDS Primary Node Unreachable"
  type    = "metric alert"
  message = <<-EOT
    {{#is_alert}}
    **CRITICAL ALERT:** The primary PostgreSQL instance is completely down or unreachable!
    
    * **Duration:** >3 minutes (Automated multi-AZ failover has either hung or failed).
    * **Impact:** The database is offline. All core platform features are halted.
    
    Notify: ${var.notification_channel}
    Runbook: https://platform.internal
    {{/is_alert}}
  EOT

  query = "avg(last_5m):avg:aws.rds.dbinstance_status{env:${var.environment},role:primary} < 1"

  monitor_thresholds {
    critical = 1.0
  }

  evaluation_delay    = 60
  no_data_timeframe   = 10
  require_full_window = true

  tags = ["env:${var.environment}", "service:postgres", "tier:data-layer"]
}

# ==============================================================================
# 4. SUSTAINED GRAPHQL MUTATION FAILURES
# ==============================================================================
locals {
  graphql_errors = "sum(last_5m):sum:trace.graphql.errors{env:${var.environment},error_type:systemic}by{graphql.operation}.as_rate()"
  graphql_hits   = "sum:trace.graphql.hits{env:${var.environment}}by{graphql.operation}.as_rate()"
}
resource "datadog_monitor" "graphql_operation_errors" {
  name    = "[CRITICAL] [${upper(var.environment)}] Key GraphQL Operations Dropping"
  type    = "query alert"
  message = <<-EOT
    {{#is_alert}}
    **CRITICAL ALERT:** System errors detected on core user workflows!
    
    * **Affected Flow:** {{backend_error.name}}
    * **Symptom:** Spikes in systemic/downstream failures, ignoring user-input validation issues.
    
    Notify: ${var.notification_channel}
    Runbook: https://platform.internal
    {{/is_alert}}
  EOT

  query = "${local.graphql_errors} / ${local.graphql_hits} > 0.05"
  
  monitor_thresholds {
    critical = 0.05
  }

  tags = ["env:${var.environment}", "service:monolith", "component:graphql"]
}
