locals {
   region_code_map = {
    us-east4 = "use4"
    us-west2 = "usw2"
   }
   region_code = local.region_code_map[lower(replace(var.region, " ",""))]
}