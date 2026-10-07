environment    = "test"
project        = "my-portfolio"
aws_region     = "us-east-1"
allowed_origin = "https://portfolio.mathewmusango.test:8000,https://localhost:8000,https://127.0.0.1:8000"
tags = {
  project    = "my-portfolio"
  managed_by = "terraform"
  repo       = "mathewmusango/my-portfolio"
}
enable_vpc        = false
enable_waf        = false
enable_cloudfront = true

deletion_protection = false
