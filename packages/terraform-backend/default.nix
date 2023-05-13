{ pkgs, lib, ... }:

pkgs.buildGoModule rec {
  pname = "terraform-backend";
  version = "0.1.1";

  subPackages = [ "cmd/terraform-backend.go" ];

  src = pkgs.fetchFromGitHub {
    owner = "nimbolus";
    repo = "terraform-backend";
    rev = "v${version}";
    hash = "sha256-Ck02ufPe0d4VVy7foZDTFHTDRTFoHkkNnDfnCSW0R6I=";
  };

  vendorHash = "sha256-krltDHLC6kW5H/JPfZoHo/UcT3+8MHaU5hbtl9lCsH8=";

  meta = with lib; {
    homepage = "https://github.com/nimbolus/terraform-backend";
    description = "A state backend server which implements the Terraform HTTP backend API";
    license = licenses.bsd3;
    maintainers = with maintainers; [ indeednotjames ];
  };
}
