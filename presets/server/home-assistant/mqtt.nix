{ ... }:

{
  services.mosquitto = {
    enable = true;
    persistence = true;
    listeners = [{
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
      acl = [ "pattern readwrite #" ];
    }];
  };
}
