# Walkthrough of OpenShell snap

This branch is a PoC of a simpler, more secure and more easily managed OpenShell install and distribution experience.

The goal is this:

```
sudo snap install k8s --classic
sudo k8s bootstrap
sudo snap install registry openshell

openshell cluster init --registry localhost:5000
openshell sandbox create
```

This could be a `curl | bash` script but we don't publish those as a recommended practice :)

## Build it

You need `rockcraft` and `snapcraft` to build the Docker image and snap respectively.
The snap also embeds the VM runtime, so local builds need `gh` (to download the
prebuilt VM runtime artifacts) and Docker (to build the base rootfs tarball).

```
sudo snap install snapcraft --classic
sudo snap install rockcraft --classic
```

Make sure `curl` is installed and Docker is running before you build the snap.


This will prepare the embedded VM runtime artifacts if they are missing, build a rock (docker image),
and then build a snap which bundles that rock. Bundling the rock is a short term thing,
we will shortly be able to attach the rock as a resource for the snap, which can be pulled dynamically (and updated
independently).

  `./tasks/scripts/build-snap.sh`

I think Gemini also integrated build:snap into the mise tooling but I don't know mise so haven't tried to exercise that.

You should now see `openshell_<version>_<architecture>.snap` in the top-level directory. Since it has just been built
locally it is not signed, so Ubuntu will not trust it by default. You need to install it with the `--dangerous` flag to
acknowledge that:

```
sudo snap install ./openshell_<v>_<arch>.snap --dangerous
sudo snap connect openshell:kube-config
```

All of this would become `sudo snap install openshell` for a user once openshell is published in the store.

## Use it

You need K8s:

```
sudo snap install k8s --classic --channel=1.35-classic
sudo k8s bootstrap
sudo k8s status --wait-ready
mkdir $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $USER:$USER .kube/config
```

You should see a clean running k8s. If you want, test it out:

```
sudo snap install kubectl --classic --channel=1.35
kubectl get nodes
```

You need a Docker image registry:

```
sudo snap install registry
```

The registry should now be running on localhost:5000, feel free to test it with your fave OCI tools.

Now you need to initialize the cluster. This puts a daemonset on the k8s which installs a custom-written AppArmor profile
for the supervisor container. That gives the supervisor (and only the supervisor) the permissions it needs to setup
the sandboxes.

```
openshell cluster init --registry=localhost:5000
```

You should see a successful initialization. In theory this would work against a different registry, but you would also
need to configure your K8s to trust that registry. We're using a localhost K8s and a localhost registry in this walkthrough
so it should Just Work.

Now you can make a sandbox:

```
openshell sandbox create
```

... should drop you into a sandbox running on k8s.



# TODO

 - tests
 - figure out how best to provide certificates
 - figure out what to do with Alpine VM rootfs - chiselled rock?
 - documentation!

