# session2-practice3-cv · LaTeX CV Builder

Session 2 · Practice 3：用 GitHub Actions 自动编译 LaTeX 简历（CV）并自动发版。

> 参考实现：https://github.com/reveurmichael/cv_latex
> 模板来源：课程仓库 `session-2/CV_in_latex`

本仓库提供 **三种构建方式**（本地 / Docker / GitHub Actions），互为备份：

| 方式 | 优点 | 缺点 | 适用场景 |
|---|---|---|---|
| **本地** | 编译快、即时反馈、可离线、编辑器集成好 | 需装 LaTeX、依赖操作系统 | 日常编辑 |
| **Docker** | 环境一致、不用装 LaTeX、跨平台可复现 | 需装 Docker、首次较慢 | 团队协作、环境隔离 |
| **GitHub Actions** | 全自动、无需本地环境、自动发版 | 需要联网、迭代慢 | 正式产出、公开分享 |

## 目录

```
.github/workflows/build-cv.yml    # CI/CD 流水线（本练习重点）
main.tex                           # 简历正文，moderncv classic 模板，2 页
img/avatar.jpg                     # 头像，被 \photo{./img/avatar.jpg} 引用
Dockerfile                         # 本地 Docker 复现编译环境
docker-compose.yml                 # Docker Compose 方式
docker_build.py                    # 跨平台 Docker 构建脚本
docker_build.sh                    # Unix 版 Docker 构建脚本
config_vscode_local.py             # 生成 .vscode/settings.json（本地 LaTeX Workshop 配置）
config_vscode_devcontainer.py      # 生成 .devcontainer/devcontainer.json
Readme-Local.md                    # 本地构建详细说明
Readme-Docker.md                   # Docker 构建详细说明
Readme-GitHub-Actions.md           # GitHub Actions 详细说明
```

## 方式 A：GitHub Actions（自动编译 + 发版）

每次 push 到 `main`：

1. 云端装 TeX Live（`xu-cheng/latex-action`）
2. 编译 `main.tex` → `main.pdf`
3. PDF 推到孤儿分支 `release`
4. 创建 Release，tag `v<run_number>`，附件 `main.pdf`

**首次推送前必须先建空的 release 分支**，否则最后一步会失败：

```bash
git checkout --orphan release
git rm -rf .
git commit --allow-empty -m "create empty release branch"
git push origin release
git checkout main
```

之后修改 `main.tex` 并 push，就会自动出新的 Release。

## 方式 B：Docker

```bash
# 用 Python 脚本（跨平台）
python docker_build.py

# 或用 compose
docker compose build
docker compose run --rm cv-builder

# 或用 Docker CLI
docker build -t latex-cv .
docker run --rm -v "$(pwd)":/latex latex-cv
```

输出 `main.pdf` 到当前目录。

## 方式 C：本地 TeX Live

1. 安装 TeX Live（Windows 见 https://tug.org/texlive/windows.html，需同时装 Perl）
2. VSCode 安装 **LaTeX Workshop** 扩展
3. 运行 `python config_vscode_local.py` 生成 `.vscode/settings.json`
4. 打开 `main.tex`，按 `Ctrl+Alt+B` 编译，或保存时自动编译

命令行等价操作：

```bash
latexmk -pdf -interaction=nonstopmode main.tex
```

## 与课程原版 `CV_in_latex` 的差异

**模板和简历内容完全一致**，只修正了会导致构建失败的地方：

| 项目 | 原版 | 本仓库 | 原因 |
|---|---|---|---|
| `actions/checkout` | v3 | **v4** | v3 依赖 Node 16，GitHub 已弃用，运行会失败 |
| `xu-cheng/latex-action` | v2 | **v3** | 同上 |
| 创建 Release | `create-release@v1` + `upload-release-asset@v1` | **`gh release create`** | 这两个 action 已归档停维护 |
| release 分支 | `--orphan release` 后直接 push | `--orphan temp_release` 再 `push -f origin temp_release:release` | 后续步骤更稳 |
| Dockerfile | `COPY avatar.jpg /latex/` | `COPY img/ /latex/img/` | 原路径错误，会 `file not found` |
| Docker CMD | `pdflatex main.tex` | `latexmk -pdf ...` | 单次 pdflatex 图标/交叉引用不全 |

## 常见问题

| 报错 | 原因 / 解决 |
|---|---|
| `File 'moderncv.cls' not found` | TeX Live 缺宏包；latex-action 自带镜像已含，自己写 `pdflatex` 会缺 |
| `! Package simpleicons Error` | 需 `tlmgr install simpleicons`，Dockerfile 已包含 |
| `File './img/avatar.jpg' not found` | 头像未提交，或 COPY 路径错了 |
| Release 步骤 403 | 缺 `permissions: contents: write` |
| 首次编译慢 / 超时 | 拉 texlive 镜像层，3~6 分钟属正常 |
| 中文乱码 | 模板用 `CJKutf8`，本简历无中文正文；如加中文需 `\begin{CJK*}{UTF8}{gbsn}` 包裹 |
