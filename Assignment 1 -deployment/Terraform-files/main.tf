provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "wire-apps-rg"
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = "wireappsacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_postgresql_server" "postgresql" {
  name                = "api-postgresql"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  version             = "16"
  sku_name            = "Standard_D2ads_v5"
  storage_mb          = 5120
  administrator_login = "pgadmin"
  administrator_login_password = "Admin@123123!"
}

resource "azurerm_postgresql_database" "database" {
  name                = "wireappsdb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.postgresql.name
  charset             = "UTF8"
  collation           = "en_US.UTF8"
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = "wireapps-app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.app_subnet.id
  }
  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }
  frontend_port {
    name = "frontendPort"
    port = 80
  }
  backend_address_pool {
    name = "appGatewayBackendPool"
  }
  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }
  http_listener {
    name                           = "appGatewayHttpListener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
    ssl_certificate_name           = null
  }
  url_path_map {
    name                = "urlPathMap"
    default_backend_address_pool_name = "appGatewayBackendPool"
    default_backend_http_settings_name = "appGatewayBackendHttpSettings"
    path_rule {
      name                       = "webAppRule"
      paths                      = ["/web/*"]
      backend_address_pool_name  = "webAppBackendPool"
      backend_http_settings_name = "webAppBackendHttpSettings"
    }
    path_rule {
      name                       = "apiRule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "apiBackendPool"
      backend_http_settings_name = "apiBackendHttpSettings"
    }
  }
}

resource "azurerm_public_ip" "app_gateway_public_ip" {
  name                = "wireappsPublicIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "wireapps-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "wireapps-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "wireapps-app-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }

resource "azurerm_app_service" "web_app" {
  name                = "wireapps-web-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
    WEBSITES_PORT = 3000
  }
  site_config {
    app_command_line = ""
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/web-app:latest"
  }
}

resource "azurerm_app_service" "api_app" {
  name                = "wireapps-api-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
    WEBSITES_PORT = 5000
    DATABASE_URL = "postgresql://${azurerm_postgresql_server.postgresql.administrator_login}:${azurerm_postgresql_server.postgresql.administrator_login_password}@${azurerm_postgresql_server.postgresql.fqdn}:5432/${azurerm_postgresql_database.database.name}?sslmode=require"
  }
  site_config {
    app_command_line = ""
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/api-service:latest"
  }
}
