# Hashicorp's Vault docker image with dev friendly default

This is a small wrapper on top of the base vault image that adds an
initialization script.

This scripts is mostly useful when you do container based dev so that you have a
vault instance ready to go without the trouble of unsealing it.

In production of course, you use cloud based auto unsealing features or you have
a bunch of admins ready to unseal on demand, but in development, you generally
don't want to bother doing that.

## Why did we provide our own helm chart instead of the official one?

Mostly because of a lack of time to do it properly. This helm chart was created
when we were still in the process of learning the kubernetes ecosystem and it
was a challenge per se.  In the future though, we will use the official one.

## How does it work?

Simple enough, it provides a vault-init.sh script that it run instead of
vault. This script takes care of initializing vault (adapting the configuration
to be able to init it properly), storing the unseal key in a clear text file.

Subsequent start will use the log file to extract the unseal key and vault will
be ready to go.

This is a simple and elegant way of having a development environment ready to be
used so that you can focus on the things that matter.

Again, don't use this in production, as the unseal key is stored in clear text
next to vault files. It would kind of break the whole idea of using vault in the
first place.

## Usage

### Standard

For stable (tagged) versions:

```
helm repo add vault https://gitlab.com/api/v4/projects/26476601/packages/helm/stable
helm search repo vault
```

For development versions:

```
helm repo add vault https://gitlab.com/api/v4/projects/26476601/packages/helm/dev
helm search repo vault --devel
```

### OCI

Add it as dependency in your `Chart.yml`

~~~yaml
dependencies:
  - name: vault
    version: "1.1.0"
    repository: "oci://xdev-tech/xdev-enterprise-business-network/vault/helm"
~~~


## Migrate from deployment to statefulset without loosing the data

You have to provide an existing claim. Something like:

```diff --git a/helm/identity/Chart.yaml b/helm/identity/Chart.yaml
index cba280b..843238a 100644
--- a/helm/identity/Chart.yaml
+++ b/helm/identity/Chart.yaml
@@ -29,4 +29,4 @@ dependencies:
     repository: "oci://registry.gitlab.com/xdev-tech/xdev-enterprise-business-network/keycloak/helm"
   - name: vault
     repository: "oci://registry.gitlab.com/xdev-tech/xdev-enterprise-business-network/vault/helm"
-    version: "1.3.2-develop.66"
+    version: "1.3.2-develop.73"
diff --git a/helm/identity/templates/vault-pvc.yaml b/helm/identity/templates/vault-pvc.yaml
new file mode 100644
index 0000000..37006fa
--- /dev/null
+++ b/helm/identity/templates/vault-pvc.yaml
@@ -0,0 +1,13 @@
+apiVersion: v1
+kind: PersistentVolumeClaim
+metadata:
+  name: {{ include "identity.fullname" . }}-vault
+  namespace: {{ .Release.Namespace }}
+  labels:
+    {{- include "identity.labels" . | nindent 4 }}
+spec:
+  accessModes:
+    - ReadWriteOnce
+  resources:
+    requests:
+      storage: 1Gi
diff --git a/helm/identity/values.yaml b/helm/identity/values.yaml
index 87797c2..9e3c300 100644
--- a/helm/identity/values.yaml
+++ b/helm/identity/values.yaml
@@ -250,8 +250,6 @@ global:
   dev: false

 vault:
-  deploymentStrategy:
-    type: Recreate
   ingress:
     enabled: true
     annotations:
@@ -277,3 +275,5 @@ vault:
   server:
     standalone:
       enabled: false
+  persistence:
+    existingClaim: '{{ .Release.Name }}-vault'
```
