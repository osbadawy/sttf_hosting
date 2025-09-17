# SSM Document for running deployment commands
resource "aws_ssm_document" "deployment_document" {
  name            = "sttf-deployment-script"
  document_type   = "Command"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '2.2'
description: 'Deploy STTF API containers'
parameters:
  commands:
    type: StringList
    description: 'Commands to run'
mainSteps:
- action: aws:runShellScript
  name: deployContainer
  inputs:
    runCommand: '{{ commands }}'
DOC
}

