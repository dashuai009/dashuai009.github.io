#let date = datetime(
  year: 2024,
  month: 10,
  day: 22,
)
#metadata((
  title: "配置电脑",
  subtitle: [CEF],
  author: "dashuai009",
  description: "一些软件的配置记录",
  pubDate: date.display(),
))<frontmatter>


== typst

#link("https://github.com/typst/typst")[官方github]
windows 安装和更新

```sh
winget install --id Typst.Typst
```

github release里下载t`ypst-x86_64-unknown-linux-musl.tar.xz`，然后解压缩，`chmod +x typst`

== docker

#link("https://docs.docker.com/engine/install/ubuntu/")[docker ubuntu 安装]

```sh
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done


# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update


sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```