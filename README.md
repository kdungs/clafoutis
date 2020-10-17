# Clafoutis 🍒🥧

[[Dockerhub](https://hub.docker.com/r/kdungs/clafoutis)]

Bake tasty Raspberry Pi images with ease.

Clafoutis is a tool that allows you to build custom variants of RaspiOS.

It can either be used from within Gitlab CI or directly via `docker run`. In
the latter case, you'll have to bind-mount a local directory containing your
distribution's files.

For now, it will download the latest version of RaspiOS lite and build on top
of that. In the future, other versions will be supported.

> Clafoutis is a baked French dessert of fruit, traditionally black cherries,
> arranged in a buttered dish and covered with a thick flan-like batter.

So it's another fruit cake pun, ¯\\_(ツ)\_/¯.


## ⚠️ Warning

The following instructions will ask you to run `docker --privileged`.

Running Docker with `--privileged` is dangerous. Clafoutis needs it in order
to access loopback devices on the host system. Without this, the underlying
process cannot work.

There might be a better way to mount (writeable) images inside a Docker
container but I haven't found one, yet. I've tested `udiskctl` and
`guestmount`, but both require access to the host system in one way or
the other, e.g. in order to use FUSE. There is also [`mountlo`]() but it
requires FUSE, as well.

If you know of a way to run Clafoutis without privileges on the host system,
please let me know.


## Usage

You can also have a look at the [example
repository](https://github.com/kdungs/clafoutis-example).


### Configuration

Clafoutis expects you to point it to a directory containing your distribution's
files. You're completely free in how you structure that directory. The only
requirement is that it contains an executable file named `install.sh` at the
top level.

Personally, I'd recommend to mirror the Linux directory structure and `install`
files from your `install.sh` e.g.

```
dist
├── etc
│   └── systemd
│       └── system
│           └── myservice.service
├── install.sh
└── usr
    └── local
        └── bin
            └── mybinary
```

And in `install.sh`:

```bash
#!/bin/bash

set -e -u

here="$(cd "$(dirname "${0}")" && pwd)"

echo "Bonjour le monde!"

install -Dm700 "${here}/usr/local/bin/mybinary" /usr/local/bin/mybinary
install -Dm644 "${here}/etc/systemd/system/myservice.service" \
  /etc/systemd/system/myservice.service
systemctl enable myservice.service
```


### Run locally

```bash
docker run \
  --privileged \
  --volume=/absolute/path/to/dist:/dist:ro \
  --volume=/absolute/path/to/image:/image \
  kdungs/clafoutis:latest \
  --distdir /dist \
  --outdir /image \
  --name myimage
```


### Run in Gitlab CI

First, make sure you have a Runner configured that can run privileged
containers. It's probably best to [create a specific runner for your
project](https://docs.gitlab.com/ee/ci/runners/#create-a-specific-runner), in
order to limit its scope. Assign a specific tag to that runner, so you can
reference it in your `.gitlab-ci.yml`. I'll use `privileged` in this example.

```YAML
build-my-image:
  stage: release
  image: kdungs/clafoutis:latest
  tags:
    - privileged
  script:
    - clafoutis --zip -d $CI_PROJECT_DIR/dist
  artifacts:
    paths:
      - /image.zip
    expire_in: 1 day
```

You can test it locally through `gitlab-runner` via

```bash
gitlab-runner exec docker \
  --docker-pull-policy="if-not-present" \
  --docker-privileged=true \
  build-my-image
```


### Command line options

```
usage clafoutis [options]
  options:
     -d
     --distdir        Directory from which to install the distribution
                      Default '/dist'
     -n
     --name           Name of the resulting image
                      Will be extended with .img
                        or .zip if the -z option is selected
                      Default 'myimage'
     -o
     --outdir         Directory for the resulting image or zip file.
                      Use this when running locally and provide it with a
                        writable Docker volume
                      If not specified, the result will be located at /
                      Default: ''
     -z
     --zip            Zip the resulting image file
                      Default: false
     -h
     --help           Show this message and exit
```


## FAQ

### Why would I use this instead of [`pi-gen`](https://github.com/RPi-Distro/pi-gen)?

Pi-gen is amazing. It's the tool(chain) that is being used to create the
RaspiOS images that serve as a basis for Clafoutis. Their use case is to start
from zero and create a working Raspberry Pi operating sytem. That process,
however, takes a lot of time.

For use cases, where you just want to build upon the (lite) image or make minor
modifications, e.g. just change the default user and configure WiFi, it might
not be worth it to run the whole pi-gen.

The bootstrap process, including downloading the image, takes about a minute on
my machine with a 150 Mbit/s internet connection.


### Does this work with Github Actions?

tl;dr I don't know

There is documentation on how to [run self-hosted
runners](https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/about-self-hosted-runners)
and [how to work with
Dockerfiles](https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/dockerfile-support-for-github-actions).

If you figure it out, please let me know.


### Does this really only work for RaspiOS images?

From a technical perspective nothing should stop this from working with other
Linux distributions. There might be issues with the image format. Archlinux,
for example, uses `xorriso` to create ISO 9660 disk images which might not be
suited for this process.

I've only tested this with RaspiOS. If you try it with other distributions,
please report your findings.
