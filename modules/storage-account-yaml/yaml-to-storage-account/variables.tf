variable "yaml_config_path" {
  description = "Path to the YAML configuration file."
  type        = string
}

variable "storage_container_ids" {
  description = "Map of container names to their resource IDs"
  type        = map(string)
}
