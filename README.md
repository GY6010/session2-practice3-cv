# session2-practice3-cv

Session 2 · Practice 3：用 GitHub Actions 自动编译 LaTeX 简历（CV）并自动发版。

> 讲义原文只有一句：`See the folder CV_in_latex.`，模板来自
> https://github.com/reveurmichael/cv_latex
>
> 老师发来的成品 PDF（2 页，Barack Obama 示例简历）对应的就是仓库里这份
> `CV_in_latex/main.tex`，本仓库直接沿用它。

## 这个练习做什么

每次 push 到 `main`，GitHub Actions 会：

1. 在云端装好 TeX Live
2. 用 `xu-cheng/latex-action` 编译 `main.tex` → `main.pdf`
3. 把 PDF 推到孤儿分支 `release`（该分支只存 PDF，没有源码）
4. 创建 GitHub Release，tag 为 `v<run_number>`，附件是 `main.pdf`

## 目录

```
.github/workflows/build-cv.yml   # 流水线
main.tex                          # 简历正文（moderncv classic 模板，2 页）
img/avatar.jpg                    # 头像，被 main.tex 的 \photo 引用
Dockerfile                        # 本地用 Docker 复现同一编译环境
```

## 效果预览

编译后的 PDF 共 2 页，结构为：

```
Barack Obama, Ph.D.
  Education
  Work Experience
  Publications
  Programming and Development Skills
  Teaching
  Research Projects
  Languages
```

## 怎么编译

### 方式 A：GitHub Actions（本练习重点，无需本地装 LaTeX）

push 到 `main` 即可。首次推送前先建空的 `release` 分支：

```bash
git checkout --orphan release
git rm -rf .
git commit --allow-empty -m "create empty release branch"
git push origin release
git checkout main
```

### 方式 B：本地 Docker

```bash
docker build -t latex-cv .
docker run --rm -v "$(pwd)":/latex latex-cv
# 输出 main.pdf
```

### 方式 C：本地 TeX Live

```bash
latexmk -pdf main.tex
```

## 改简历

只改 `main.tex`，然后 `git add` / `commit` / `push`，Actions 会自动重编译并发新版本。

## 与讲义原版的差异（重要，不改会失败）

| 项目 | 讲义原版 | 本仓库 | 原因 |
|---|---|---|---|
| `actions/checkout` | v3 | **v4** | v3 依赖 Node 16，已被 GitHub 弃用 |
| `xu-cheng/latex-action` | v2 | **v3** | 同上 |
| 创建 Release | `actions/create-release@v1` + `upload-release-asset@v1` | **`gh release create`** | 这两个 action **已归档停维护**，运行会失败或卡住 |
| 推送 release 分支 | `git checkout --orphan release` | `--orphan temp_release` + `git push -f origin temp_release:release` | 避免后续步骤依赖本地分支名 |
| Dockerfile | `COPY avatar.jpg /latex/` | `COPY img/ /latex/img/` | 原路径错误（实际在 `img/` 下），会报 `file not found` |

## 常见报错

| 报错 | 原因 / 解决 |
|---|---|
| `File 'moderncv.cls' not found` | TeX Live 缺宏包。latex-action 默认镜像已含；自己写 `run: pdflatex` 就会缺 |
| `! Package simpleicons Error` | 缺 simpleicons 宏包，需 `tlmgr install simpleicons` |
| `File './img/avatar.jpg' not found` | 头像没一起提交，或 Dockerfile COPY 路径写错 |
| Release 步骤 403 | 缺 `permissions: contents: write` |
| 编译超时 | 首次拉 texlive 镜像层较慢，正常 2~5 分钟；超过 10 分钟检查日志 |
| 中文乱码 | 模板用了 `CJKutf8`，本份简历正文无中文，不受影响；若加中文需 `\begin{CJK*}{UTF8}{gbsn}` 包裹 |
