
provider "aws" {
 region = "eu-west-1"
}

import {
 # ID of the cloud resource
 # Check provider documentation for importable resources and format
 id = "import-bucket-tf15"
 # Resource address
 to = aws_s3_bucket.this
}

import {
 # ID of the cloud resource
 # Check provider documentation for importable resources and format
 id = "import-bucket-tf15-2"
 # Resource address
 to = aws_s3_bucket.this2
}
