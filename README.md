# ssbwg: WireGuard VPN for Slippi

Based on [@jmlee337's solution](https://discuss.smash.today/@jmlee337/110555300578391389):
> Many Slippi players have consistent problems connecting to other players. They are often caused by routing or traversal issues outside of the players' control, often at the ISP level. In these cases, tunneling through a VPN can solve connection issues and even lower ping. Retail VPNs can work for individual players but don't scale to the population of a whole region. For example, many ISPs in the Philippines use CGNAT which makes it difficult to establish domestic P2P connections. To that end, I have created a VPN specifically for the Melee community in the Philippines using cloud compute...

This repository aims to be a reference for such an instance, if anyone else wishes to test this out quickly within their region with a fork. Pretty much the only things that need to change are in [Pulumi.prod.yaml](./Pulumi.prod.yaml).

## Technologies
Besides things mentioned in the original thread (WireGuard, WireSock, WireSockUI):
- [Pulumi](https://www.pulumi.com) (Pulumi Cloud for individuals is free!)
- [GCP](https://cloud.google.com)

Even if you don't want to use the same exact infrastructure setup, hopefully this is still useful. Note that in most other places the network interface will probably be `eth0` instead of `ens4`.

## Examples
Within the [examples](./examples) directory lies examples of what configurations will actually be generated in the server. All the keys here are fake, and `<<VM_EXTERNAL_IP_HERE>>` should also be replaced in your actual configuration.

## Deploying
```bash
$ gcloud auth application-default login
$ pulumi up --config="gcp:project=your-gcp-project"
```

Upon first boot, copy [machine/setup.sh](./machine/setup.sh) into the VM and run it. It will generate 253 peers (`10.0.2.2` ~ `10.0.2.254`), left in a `/etc/wireguard/peers.conf` for convenience, and update `/etc/wireguard/wg0.conf` accordingly.
