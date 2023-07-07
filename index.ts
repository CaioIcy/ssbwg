import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as fs from "fs";
import * as path from "path";

const config = new pulumi.Config();
const machineType = config.get("machineType") || "e2-micro";
const osImage = config.get("osImage") || "debian-11";
const instanceTag = config.get("instanceTag") || "wireguard";

const metadataStartupScript = fs.readFileSync(path.join(__dirname, "machine", "startup.sh"), "utf-8");

const network = new gcp.compute.Network("ssbwg-network", {
  autoCreateSubnetworks: false,
});

const subnet = new gcp.compute.Subnetwork("ssbwg-subnet", {
    ipCidrRange: "10.0.1.0/24",
    network: network.id,
});

const firewallWireGuard = new gcp.compute.Firewall("allow-wireguard", {
    allows: [{
      ports: ["51820"],
      protocol: "udp",
    }],
    network: network.selfLink,
    sourceRanges: ["0.0.0.0/0"],
    targetTags: [instanceTag],
});

const firewallSSH = new gcp.compute.Firewall("allow-ssh", {
    allows: [{
        ports: ["22"],
        protocol: "tcp",
    }],
    network: network.selfLink,
    sourceRanges: ["0.0.0.0/0"],
    targetTags: [instanceTag],
});

const staticIP = new gcp.compute.Address("ssbwg-ip", {
  addressType: "EXTERNAL",
  networkTier: "PREMIUM",
});

const instanceWithIp = new gcp.compute.Instance("ssbwg-sp", {
  machineType,
  metadataStartupScript, // Logs to /var/log/daemon.log in Debian

  tags: [instanceTag],
  bootDisk: {
    initializeParams: {
      image: osImage,
      type: "pd-standard",
    },
  },
  shieldedInstanceConfig: {
    enableSecureBoot: true,
    enableVtpm: false,
    enableIntegrityMonitoring: false,
  },
  networkInterfaces: [{
    subnetwork: subnet.selfLink,
    nicType: "GVNIC",
    accessConfigs: [{
      natIp: staticIP.address,
      networkTier: "PREMIUM",
    }],
  }],
  canIpForward: true,
  allowStoppingForUpdate: true,
},
{
  // Error 400: Invalid resource usage: 'External IP address: ... is already in-use.'
  // https://github.com/pulumi/pulumi/issues/4128
  deleteBeforeReplace: true,
});
