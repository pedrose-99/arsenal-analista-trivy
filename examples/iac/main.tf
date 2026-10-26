resource "aws_s3_bucket" "datos" {
  bucket = "datos-publicos"
  acl    = "public-read"
}
