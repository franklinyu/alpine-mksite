
out := _out
md_sources := $(wildcard *.md) $(wildcard [a-z]*/*.md)
pages := $(patsubst %.md,$(out)/%.html, $(md_sources))

static_sources := $(shell find _static -type f)
static_out := $(patsubst _static/%,$(out)/%,$(static_sources))

git_atom_url := http://git.alpinelinux.org/cgit/aports/atom

all: $(pages) $(static_out)

$(out)/index.html: release.yaml git-commits.yaml

$(out)/%.html: %.md _default.template.html
	mkdir -p $(dir $@)
	lua _scripts/generate_page.lua $< $(filter %.yaml,$^) > $@.tmp
	mv $@.tmp $@

$(static_out): $(out)/%: _static/%
	mkdir -p $(dir $@)
	cp $< $@

clean:
	rm -f $(pages) $(static_out)

yaml_url := http://nl.alpinelinux.org/alpine/latest-stable/releases/x86_64/latest-releases.yaml

latest-releases.yaml:
	curl -J $(yaml_url) > $@.tmp
	mv $@.tmp $@

release.yaml: latest-releases.yaml
	lua -e 'y=require("yaml"); for _,v in pairs(y.load(io.read("*a"))) do if v.flavor == "alpine" then v.size_mb=math.floor(v.size/(1024*1024)); io.write(y.dump(v)) end end' > $@.tmp < $<
	mv $@.tmp $@

update-release:
	rm -f latest-releases.yaml
	$(MAKE)

git-commits.yaml: _scripts/atom-to-yaml.xsl
	curl $(git_atom_url) | xsltproc _scripts/atom-to-yaml.xsl - > $@.tmp
	mv $@.tmp $@

update-git-commits:
	rm -f git-commits.yaml
	$(MAKE)

