LATEXMK := latexmk

ifeq (k,$(findstring k,$(MAKEFLAGS)))
	LATEXMK += -f
endif

.PHONY: all pdfdvi preview monitor pdf

all: pdf

deploy: it-handbook.pdf config
	rsync -av it-handbook.pdf config ../../engineer-docs/docs/pdf/

dot.all_files := $(wildcard *.dot)
dot.eps_files := $(dot.all_files:.dot=.eps)

$(dot.eps_files): %.eps: %.dot
	dot -Tps $< -o $@
.PHONY: clean-dot
clean-dot:
	-rm -f $(dot.eps_files)

gnuplot.all_files  := $(filter-out %.make.gpi,$(wildcard *.gpi))
gnuplot.temp_files := $(gnuplot.all_files:.gpi=.make.gpi)
gnuplot.eps_files  := $(gnuplot.all_files:.gpi=.eps)

# $(call output-gpi,.gpi)
define output-gpi
{ \
  echo 'set terminal postscript enhanced eps color'; \
  echo 'set output "$(1:.gpi=.eps)"'; \
  cat $1; \
}
endef

$(gnuplot.temp_files): %.make.gpi: %.gpi
	$(call output-gpi,$<) > $@

$(gnuplot.eps_files): %.eps: %.make.gpi
	 gnuplot $<

.PHONY: clean-gnuplot
clean-gnuplot:
	-rm -f $(gnuplot.temp_files)

mpost.all_files	   := $(filter-out %mpgraph.mp,$(wildcard *.mp))
mpost.pdf_files	   := $(mpost.all_files:.mp=.pdf)
mpost.pdf_temps	   := $(mpost.all_files:.mp=-1.pdf)
mpost.eps_files	   := $(mpost.all_files:.mp=.eps)

$(mpost.pdf_temps): %-1.pdf: %.mp
	mptopdf $<

$(mpost.pdf_files): %.pdf: %-1.pdf
	cp $< $@

$(mpost.eps_files): %.eps: %.pdf
	convert $< $@

.PHONY: clean-mpost
clean-mpost:
	-rm -f $(mpost.pdf_temps)
	-rm -f $(mpost.eps_files)
	-rm -f $(mpost.all_files:.mp=)
	-rm -f $(mpost.all_files:.mp=-mpgraph.mpo)
	-rm -f $(mpost.all_files:.mp=-temp-mpgraph.mp)
	-rm -f $(mpost.all_files:.mp=-temp.dvi)
	-rm -f $(mpost.all_files:.mp=.1)
	-rm -f $(mpost.all_files:.mp=.mpx)
	-rm -f $(mpost.all_files:.mp=.eps)
	-rm -f mpgraph.mp

svg.all_files    := $(wildcard *.svg)
svg.eps_files    := $(svg.all_files:.svg=.eps)

$(svg.eps_files): %.eps: %.svg
	inkscape -T -E $@ $<

all_generated_eps := $(sort $(gnuplot.eps_files) $(dot.eps_files) $(mpost.eps_files) $(svg.eps_files))
all_eps := $(sort $(all_generated_eps) $(wildcard *.eps))
all_generated_images := $(all_generated_eps)
all_images := $(all_eps)
all_pdf_images := $(all_eps:.eps=.pdf)

dep_images := $(all_images)

.PHONY: clean clean-images
clean-images:
	-rm -f $(all_generated_images)
	-rm -f $(all_pdf_images)

.PHONY: images
images: $(dep_images)

clean: clean-images clean-mpost clean-gnuplot
	-rm -f *.out *.log
	$(LATEXMK) -C *.tex

pdf: $(dep_images)
	$(LATEXMK) -pdf

pdfdvi: $(dep_images)
	$(LATEXMK) -pdfdvi

preview: $(dep_images)
	$(LATEXMK) -pdf -pv

monitor: $(dep_images)
	$(LATEXMK) -pdf -pvc
