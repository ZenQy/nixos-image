# nixos-image

nixos image for low ram vps

---

## 使用

1. 生成镜像，例如：

> nix build .#vps

2. 将镜像存放在可以直链访问的地方，例如：https://f.940940.xyz/nixos.img.zst

3. 下载DD脚本

> wget https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh

4. 运行脚本

> # bash reinstall.sh dd --password 123@@@ --web-port 8888 --img=https://f.940940.xyz/nixos.img.zst

---

## 记录

- [x] 已在sailor上验证
