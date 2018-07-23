resource "aws_key_pair" "terranova" {
  key_name   = "terranova"
  public_key = "${file("~/.ssh/terranova.pub")}"
}
