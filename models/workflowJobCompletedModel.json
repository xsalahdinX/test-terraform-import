{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
      "action": {
        "type": "string",
        "enum": ["completed"]
      },
      "workflow_job": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer"
          },
          "run_id": {
            "type": "integer"
          },
          "workflow_name": {
            "type": "string"
          },
          "head_branch": {
            "type": "string"
          },
          "run_url": {
            "type": "string",
            "format": "uri"
          },
          "run_attempt": {
            "type": "integer"
          },
          "node_id": {
            "type": "string"
          },
          "head_sha": {
            "type": "string"
          },
          "url": {
            "type": "string",
            "format": "uri"
          },
          "html_url": {
            "type": "string",
            "format": "uri"
          },
          "status": {
            "type": "string"
          },
          "conclusion": {
            "type": "string"
          },
          "created_at": {
            "type": "string",
            "format": "date-time"
          },
          "started_at": {
            "type": "string",
            "format": "date-time"
          },
          "completed_at": {
            "type": "string",
            "format": "date-time"
          },
          "name": {
            "type": "string"
          },
          "steps": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                },
                "status": {
                  "type": "string"
                },
                "conclusion": {
                  "type": "string"
                },
                "number": {
                  "type": "integer"
                },
                "started_at": {
                  "type": "string",
                  "format": "date-time"
                },
                "completed_at": {
                  "type": "string",
                  "format": "date-time"
                }
              },
              "required": ["name", "status", "conclusion", "number", "started_at", "completed_at"]
            }
          },
          "check_run_url": {
            "type": "string",
            "format": "uri"
          },
          "labels": {
            "type": "array",
            "items": {
              "type": "string"
            }
          },
          "runner_id": {
            "type": "integer"
          },
          "runner_name": {
            "type": "string"
          },
          "runner_group_id": {
            "type": "integer"
          },
          "runner_group_name": {
            "type": "string"
          }
        },
        "required": [
          "id",
          "run_id",
          "workflow_name",
          "head_branch",
          "run_url",
          "run_attempt",
          "node_id",
          "head_sha",
          "url",
          "html_url",
          "status",
          "conclusion",
          "created_at",
          "started_at",
          "completed_at",
          "name",
          "steps",
          "check_run_url",
          "runner_id",
          "runner_name",
          "runner_group_id",
          "runner_group_name"
        ]
      },
      "repository": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer"
          },
          "node_id": {
            "type": "string"
          },
          "name": {
            "type": "string"
          },
          "full_name": {
            "type": "string"
          },
          "private": {
            "type": "boolean"
          },
          "owner": {
            "type": "object",
            "properties": {
              "login": {
                "type": "string"
              },
              "id": {
                "type": "integer"
              },
              "node_id": {
                "type": "string"
              },
              "avatar_url": {
                "type": "string",
                "format": "uri"
              },
              "url": {
                "type": "string",
                "format": "uri"
              },
              "html_url": {
                "type": "string",
                "format": "uri"
              }
            },
            "required": ["login", "id", "node_id", "avatar_url", "url", "html_url"]
          },
          "url": {
            "type": "string",
            "format": "uri"
          },
          "created_at": {
            "type": "string",
            "format": "date-time"
          },
          "updated_at": {
            "type": "string",
            "format": "date-time"
          },
          "pushed_at": {
            "type": "string",
            "format": "date-time"
          },
          "git_url": {
            "type": "string"
          },
          "ssh_url": {
            "type": "string"
          },
          "clone_url": {
            "type": "string",
            "format": "uri"
          }
        },
        "required": [
          "id",
          "node_id",
          "name",
          "full_name",
          "private",
          "owner",
          "url",
          "created_at",
          "updated_at",
          "pushed_at",
          "git_url",
          "ssh_url",
          "clone_url"
        ]
      },
      "organization": {
        "type": "object",
        "properties": {
          "login": {
            "type": "string"
          },
          "id": {
            "type": "integer"
          },
          "node_id": {
            "type": "string"
          },
          "url": {
            "type": "string",
            "format": "uri"
          },
          "repos_url": {
            "type": "string",
            "format": "uri"
          }
        },
        "required": ["login", "id", "node_id", "url", "repos_url"]
      },
      "enterprise": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer"
          },
          "slug": {
            "type": "string"
          },
          "name": {
            "type": "string"
          },
          "node_id": {
            "type": "string"
          },
          "avatar_url": {
            "type": "string",
            "format": "uri"
          }
        },
        "required": ["id", "slug", "name", "node_id", "avatar_url"]
      },
      "sender": {
        "type": "object",
        "properties": {
          "login": {
            "type": "string"
          },
          "id": {
            "type": "integer"
          },
          "node_id": {
            "type": "string"
          },
          "avatar_url": {
            "type": "string",
            "format": "uri"
          },
          "url": {
            "type": "string",
            "format": "uri"
          }
        },
        "required": ["login", "id", "node_id", "avatar_url", "url"]
      }
    },
    "required": ["action", "workflow_job", "repository", "organization", "enterprise", "sender"]
  }
