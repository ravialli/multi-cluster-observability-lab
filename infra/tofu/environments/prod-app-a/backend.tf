terraform {
  backend "gcs" {
    bucket = "project-02553732-afb0-4b3d-a64-tofu-state"
    prefix = "prod-app-a"
  }
}