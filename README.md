# Hashicorp's Vault docker image with dev friendly default

![snyk logo](https://res.cloudinary.com/snyk/image/upload/v1468845142/favicon/favicon.ico)[To see snyk reports click here](https://app.snyk.io/org/glehmann/projects)

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
