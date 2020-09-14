resource "aws_key_pair" "ssh_connection" {
  key_name    = var.ssh_key_name
  public_key  = file(var.path_to_public_key)
}