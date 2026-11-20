FROM texlive/texlive:latest

# Packages required by main.tex (moderncv + CJK + icon packs)
RUN tlmgr install \
    moderncv \
    ulem \
    xcolor \
    geometry \
    cjk \
    fontawesome5 \
    simpleicons \
    lm \
    helvetic \
    tex-gyre

WORKDIR /latex

# Copy sources into the image so the build works without bind mounts
COPY main.tex /latex/
COPY img/ /latex/img/

CMD ["latexmk", "-pdf", "-interaction=nonstopmode", "-file-line-error", "main.tex"]
