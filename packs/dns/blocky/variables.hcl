variable "job_name" {
  description = "The name to use as the job name which overrides using the pack name."
  type        = string
  default     = ""
}

variable "job_type" {
  description = "Specifies the Nomad scheduler to use."
  type        = string
  default     = "service"
}

variable "ui" {
  description = "Options to modify the presentation of the Job index page in the Web UI."
  type = object({
    description = string
    links = list(
      object({
        label = string
        url   = string
      })
    )
  })
  default = null
}

variable "region" {
  description = "The region where jobs will be deployed."
  type        = string
  default     = "global"
}

variable "namespace" {
  description = "The namespace in which to execute the job."
  type        = string
  default     = "default"
}

variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["*"]
}

variable "constraints" {
  description = "Additional constraints to apply to the job."
  type = list(
    object({
      attribute = string
      operator  = string
      value     = string
    })
  )
  default = []
}

variable "network" {
  description = "Networking requirements."
  type = object({
    mode = string
    ports = list(
      object({
        name         = string
        to           = number
        static       = number
        host_network = string
      })
    )
    dns = object({
      servers  = list(string)
      searches = list(string)
      options  = list(string)
    })
  })
  default = {
    mode = "bridge"
    ports = [
      {
        name         = "dns"
        to           = 53
        static       = 53
        host_network = "public"
      },
      {
        name         = "connect-proxy-blocky-http"
        to           = -1
        static       = 0
        host_network = "connect"
      },
      {
        name         = "connect-proxy-blocky-dns"
        to           = -1
        static       = 0
        host_network = "connect"
      }
    ]
    dns = null
  }
}

variable "services" {
  description = "Specifies integrations for service discovery."
  type = list(
    object({
      name     = string
      port     = string
      tags     = list(string)
      provider = string
      checks = list(
        object({
          address_mode = string
          args         = list(string)
          restart = object({
            limit           = number
            grace           = string
            ignore_warnings = bool
          })
          command         = string
          interval        = string
          method          = string
          body            = string
          name            = string
          path            = string
          expose          = bool
          port            = string
          protocol        = string
          task            = string
          timeout         = string
          type            = string
          tls_server_name = string
          tls_skip_verify = bool
          headers         = string
        })
      )
      connect = object({
        native = bool
        sidecar = object({
          task = object({
            resources = object({
              cpu    = number
              memory = number
            })
          })
          service = object({
            port = string
            proxy = object({
              expose = list(
                object({
                  path          = string
                  protocol      = string
                  local_port    = number
                  listener_port = string
                })
              )
              upstreams = list(
                object({
                  name = string
                  port = number
                })
              )
            })
          })
        })
      })
    })
  )
  default = [
    {
      name     = "blocky-http"
      port     = "4000"
      tags     = []
      provider = "consul"
      checks   = []
      connect = {
        native = false
        sidecar = {
          task = null
          service = {
            port = "connect-proxy-blocky-http"
            proxy = {
              expose    = []
              upstreams = []
            }
          }
        }
      }
    },
    {
      name     = "blocky-dns"
      port     = "53"
      tags     = []
      provider = "consul"
      checks   = []
      connect = {
        native = false
        sidecar = {
          task = null
          service = {
            port = "connect-proxy-blocky-dns"
            proxy = {
              expose    = []
              upstreams = []
            }
          }
        }
      }
    }
  ]
}

variable "vault" {
  description = "Allows a task to specify that it requires a token from a HashiCorp Vault server."
  type = object({
    env           = bool
    role          = string
    change_mode   = string
    change_signal = string
  })
  default = null
}

variable "consul" {
  description = "Specifies Consul configuration options specific to a task."
  type        = object({})
  default     = null
}

variable "docker_config" {
  description = "Docker driver task configuration."
  type = object({
    image      = string
    entrypoint = list(string)
    args       = list(string)
    volumes    = list(string)
    privileged = bool
  })
  default = {
    image      = "spx01/blocky:latest"
    entrypoint = null
    args       = ["--config=$${NOMAD_TASK_DIR}/blocky.yml"]
    volumes    = []
    privileged = false
  }
}

variable "templates" {
  description = "List of templates to render."
  type = list(
    object({
      data          = string
      destination   = string
      change_mode   = string
      change_signal = string
      env           = bool
    })
  )
  default = [
    {
      data          = <<EOH
---
ports:
  dns: 53
  http: 4000

upstreams:
  init:
    strategy: fast

  groups:
    default:
      - https://1.1.1.1/dns-query
      - https://1.0.0.1/dns-query

bootstrapDns:
  - upstream: https://1.1.1.1/dns-query
  - upstream: https://1.0.0.1/dns-query
      EOH
      destination   = "$${NOMAD_TASK_DIR}/blocky.yml"
      change_mode   = "restart"
      change_signal = null
      env           = false
    }
  ]
}

variable "environment" {
  description = "Environment variables to pass to task."
  type        = map(string)
  default     = {}
}

variable "artifacts" {
  description = "Instructs Nomad to fetch and unpack a remote resource."
  type = list(
    object({
      source      = string
      destination = string
      mode        = string
    })
  )
  default = []
}

variable "resources" {
  description = "The resource to assign to the application."
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 48,
    memory = 96
  }
}

variable "volumes" {
  description = "Volumes to require."
  type = list(
    object({
      name            = string
      type            = string
      source          = string
      read_only       = bool
      access_mode     = string
      attachment_mode = string
    })
  )
  default = []
}

variable "volume_mounts" {
  description = "Volumes to mount."
  type = list(
    object({
      volume        = string
      destination   = string
      read_only     = bool
      selinux_label = string
    })
  )
  default = []
}

variable "restart" {
  description = "Configures a task behavior on failure."
  type = object({
    attempts         = number
    delay            = string
    interval         = string
    mode             = string
    render_templates = bool
  })
  default = {
    mode             = "fail"
    delay            = "15s"
    interval         = "10m"
    attempts         = 3
    render_templates = false
  }
}

variable "identities" {
  description = "Allows a task access to its Workload Identity via an environment variable or file."
  type = list(
    object({
      name          = string
      env           = bool
      file          = bool
      audience      = list(string)
      change_mode   = string
      change_signal = string
    })
  )
  default = []
}
