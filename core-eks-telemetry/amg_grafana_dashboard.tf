resource "grafana_dashboard" "kubernetes_overview" {
  count = var.grafana_api_token != null && var.grafana_api_token != "" && var.grafana_url != "http://localhost:3000" ? 1 : 0

  config_json = file("${path.module}/dashboards/kubernetes-overview.json")
  overwrite   = true
}
