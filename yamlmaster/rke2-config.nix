{ config, pkgs, ... }@inp:

{

  age.secrets = {
    agent-token = {
      file = ../secrets/rke2-agent-token.age;
    };
  };

  services.rke2 = {
    enable = true;
    serverAddr = "https://0.6.9.1:9345";
    role = "agent";
    nodeIP = "0.6.9.2";
    agentTokenFile = config.age.secrets.agent-token.path;
    nodeName = "yamlmaster";

  };

}
