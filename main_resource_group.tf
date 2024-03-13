resource "aws_resourcegroups_group" "resourcegroups_group" {
  name = "${var.prefix}-group-${var.environment}"
  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],
      TagFilters = [
        {
          Key    = "Environment",
          Values = [var.environment]
        }
      ]
    })
  }
}
