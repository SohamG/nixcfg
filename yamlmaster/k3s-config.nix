{ config, pkgs, ... }@inp:

{

  /*
    CRI-O Notes
    -----------
    - CRI is a bridge from Kube(let) to container runner like runc/crun/etc.
    - CRIO is an alternative for containerd, cannot be used together.
    - Replacing containerd in k3s means re-working networking/CNI.
    - CRI-O needs to interact with flannel.
    - CRIO runtime seems to be prone to race conditions, ALWAYS reboot after
      config change.
    - Need one conflist to bridge containers to flannel
    - Need another to make CRIO aware of flannel
    - MAKE SURE CIDRs ALIGN
    - Yamlmaster is now effectively 10.42.1.0/24. Only 255 containers?!
    - Specifying "10.42.1.0/16" creates an error as it wants .0.0 for /16!
    - The bandwidth plugin seems to be broken ??
    - flannel-wg is the *node* connection to the rest of kubes
    - cni0 is the *container* connection to the rest of the node
    - FreeIPA basically only works with CRI-O...
    - This was a bad idea.
  */

  age.secrets = {
    agent-token = {
      file = ../secrets/rke2-agent-token.age;
    };
  };

  services.k3s = {
    enable = true;
    serverAddr = "https://0.6.9.1:6443";
    role = "agent";
    # containerdConfigTemplate = ''
    # {{ template "base" . }}

    # [plugins."io.containerd.cri.v1.runtime"]
    # cgroup_writeable = true
    # [plugins."io.containerd.cri.v1.runtime'.containerd.runtimes."runc"]
    #    SystemdCgroup = true
    # '';

    extraFlags = [
      "--node-external-ip=0.6.9.2"
      # "--kube-apiserver-arg=feature-gates=UserNamespacesSupport=true"
      "--kubelet-arg=feature-gates=UserNamespacesSupport=true"
      # "--kubelet-arg=cgroup-driver=\"systemd\""
      # "--kube-controller-manager-arg feature-gates=UserNamespacesSupport=true"
      # "--kube-scheduler-arg feature-gates=UserNamespacesSupport=true"
      "--container-runtime-endpoint=/var/run/crio/crio.sock"
    ];
    tokenFile = config.age.secrets.agent-token.path;
    # nodeName = "yamlmaster";
    extraKubeletConfig = {
      cgroupDriver = "systemd";
      featureGates = {
        UserNamespacesSupport = true;
      };
    };
  };

  # Longhorn has FHS paths
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    "L+ /opt/cni/bin - - - - /var/lib/rancher/k3s/data/current/bin/"
  ];

  environment.systemPackages = with pkgs; [
    nfs-utils
    cri-o
  ];

  virtualisation.cri-o = {
    enable = true;
    settings = {
      crio.network = {
        # Flannel plugin
        plugin_dirs = [ "/var/lib/rancher/k3s/data/cni" ];
        network_dir = "/etc/cni/net.d/";
      };
    };
  };

  systemd.services.k3s.serviceConfig."LimitNOFILE" = pkgs.lib.mkForce "infinity";

  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };

  # Enabled from virt.cri-o.enable
  environment.etc."cni/net.d/99-loopback.conflist".enable = false;

  # Trailing commas in JSON will break Golang parsing!
  environment.etc."cni/net.d/20-flannel.conflist" = pkgs.lib.mkForce {
    enable = true;
    text = ''
          {
        "name":"cbr0",
        "cniVersion":"1.0.0",
        "plugins":[
          {
            "type":"flannel",
            "delegate":{
              "hairpinMode":true,
              "forceAddress":true,
              "isDefaultGateway":true
            }
          },
          {
            "type":"portmap",
            "capabilities":{
              "portMappings":true
            }
          }
        ]
      }
    '';
  };

  environment.etc."cni/net.d/10-crio-bridge.conflist" = pkgs.lib.mkForce {
    enable = true;
    text = ''
      {
        "cniVersion": "1.0.0",
        "name": "crio",
        "plugins": [
          {
            "type": "bridge",
            "bridge": "cni0",
            "isGateway": true,
            "ipMasq": true,
            "hairpinMode": true,
            "ipam": {
              "type": "host-local",
              "routes": [
                  { "dst": "0.0.0.0/0" }
              ],
              "ranges": [
                  [{ "subnet": "10.42.1.0/24" }]
              ]
            }
          }
        ]
      }

    '';
  };

}
