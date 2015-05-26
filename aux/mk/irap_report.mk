#; -*- mode: Makefile;-*-
# =========================================================
# Copyright 2012-2015,  Nuno A. Fonseca (nuno dot fonseca at gmail dot com)
#
# This file is part of iRAP.
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with iRAP.  If not, see <http://www.gnu.org/licenses/>.
#
#
#    $Id: 0.1.3 Nuno Fonseca Fri Dec 21 11:56:56 2012$
# =========================================================
# Rules for creating the reports

BROWSER_DIR=jbrowse

ifndef CSS_FILE
CSS_FILE=irap.css
endif
PATH2CSS_FILE=$(IRAP_DIR)/aux/css/$(CSS_FILE)

ifndef report_qc_only
report_qc_only=n
endif


# 1- pat
define quiet_ls=
$(shell ls --color=never -1 $(1) 2>/dev/null)
endef
# 1 - pat
# return only the the first file (most recent file)
define quiet_ls1=
$(shell ls --color=never -1 -t $(1) 2>/dev/null| head -n 1)
endef

##################
# the report will be generated for which combinations of tools?
ifdef report_find_files
report_mappers:=$(mapper)
report_quant:=$(SUPPORTED_QUANT_METHODS)
report_equant:=$(SUPPORTED_EXON_QUANT_METHODS)
report_de:=$(SUPPORTED_DE_METHODS)
report_norm_methods:=$(SUPPORTED_NORM_METHODS)
report_norm_tools:=$(SUPPORTED_NORM_TOOLS)
else
# by default generate a report only for the options selected in the conf. file
ifneq ($(mapper),none)
report_mappers?=$(mapper)
endif
ifneq ($(quant_method),none)
report_quant?=$(quant_method)
endif
ifeq ($(exon_quant),y)
report_equant?=$(SUPPORTED_EXON_QUANT_METHODS)
else
report_equant?=
endif
report_de?=$(de_method)
#ifneq ($(quant_norm_tool),none)
report_norm_methods?=$(quant_norm_method)
report_norm_tools?=$(quant_norm_tool)
#endif
endif

#$(foreach v,report_mappers report_quant report_equant report_de, $(info $(v)=$($(v))))
#################################################################
# useful functions
define set_MAPPING_DIRS=
$(eval override MAPPING_DIRS:=$(foreach m,$(report_mappers), $(call quiet_ls, -d $(name)/$(m))))
endef
#$(eval override MAPPING_DIRS:=$(shell ls --color=never -d -1 $(name)/{$(shell echo $(SUPPORTED_MAPPERS) | sed 's/ /,/g')}  2>/dev/null ))

define set_QUANT_DIRS=
$(eval override QUANT_DIRS:=$(shell ls --color=never -d -1 $(shell echo $(foreach d,$(call mapping_dirs),$(foreach q,$(report_quant), $d/$q))) 2>/dev/null ))
endef

define set_DE_DIRS=
$(eval override DE_DIRS:=$(shell ls --color=never -d -1 $(shell echo $(foreach d,$(call quant_dirs),$(d)/{$(shell echo $(report_de)| sed 's/ /,/g')})) 2>/dev/null))
endef

# 1 - exp name
define set_GSE_HTML_FILES=
$(eval override GSE_HTML_FILES:=$(subst $(name)/,$(name)/report/,$(foreach d,$(call de_dirs,$(1)),$(foreach c,$(contrasts),$(subst .tsv,.html,$(call file_not_empty,$(call quiet_ls,$(d)/$(c)*.gse.*.tsv))))))) $(GSE_HTML_FILES)
endef


# 1 - exp name
# include only 'valid' contrasts
define set_DE_HTML_FILES=
$(eval override  DE_HTML_FILES=$(subst $(name)/,$(name)/report/,$(foreach d,$(call de_dirs,$(1)),$(foreach c,$(contrasts),$(subst .tsv,.html,$(call quiet_ls,$(d)/$(c)*_de.tsv))))))
endef

# mapper quant raw|nlib|rpkm gene|trans
define quant_target=
$(if $(call file_not_empty,$(call quiet_ls1,$(name)/$(1)/$(2)/$(4)s.$(3).$(2).tsv)), $(name)/report/quant/$(1)_x_$(2)/$(4)s.$(3).$(2).html, )
endef

# exon
define equant_target=
$(if $(call file_not_empty,$(call quiet_ls1,$(name)/$(1)/$(2)/exons.$(3).$(4).tsv)), $(name)/report/quant/$(1)_x_$(2)/exons.$(3).$(4).html, )
endef

# mapper gene_quant nm level nt
define nquant_target=
$(if $(call file_not_empty,$(call quiet_ls1,$(name)/$(1)/$(2)/$(4)s.$(3).$(2).$(5).tsv)), $(name)/report/quant/$(1)_x_$(2)/$(4)s.$(3).$(2).$(5).html, )
endef

# mapper quant_method norm_method norm_tool exon_quant_method
define enquant_target=
$(if $(call file_not_empty,$(call quiet_ls1,$(name)/$(1)/$(2)/exons.$(3).$(5).$(4).tsv)), $(name)/report/quant/$(1)_x_$(2)/exons.$(3).$(5).$(4).html, ) 
endef


define file_not_empty=
$(if $(call is_empty_file,$(1)),,$(1))
endef

define mapping_dirs=
$(strip $(call cached_var,MAPPING_DIRS))
endef

define quant_dirs=
$(strip $(call cached_var,QUANT_DIRS))
endef

define de_dirs=
$(strip $(call cached_var,DE_DIRS))
endef

#disable for atlas
ifdef atlas_run
define de_html_files=
endef
define gse_html_files=
endef
else
define de_html_files=
$(strip $(call cached_var,DE_HTML_FILES))
endef
define gse_html_files=
$(strip $(call cached_var,GSE_HTML_FILES))
endef

endif

# 
$(call p_debug, mapping_dirs=$(call mapping_dirs))
$(call p_debug, quant_dirs=$(call quant_dirs))
$(call p_debug, de_dirs=$(call de_dirs))
$(call p_debug, cached_vars=$(cached_vars))

# 1 - exp name
#define gse_html_files=
#$(subst $(name)/,$(name)/report/,$(foreach d,$(call de_dirs,$(1)),$(subst .tsv,.html,$(call quiet_ls,$(d)/*.gse.*.tsv))))
#endef



# 1 metric
# 2 TSV file
# 3 out dir
# 4 out file
# 5 title
# --anotation ....
#
define DE_tsv2html=
	tsvDE2html --flavour $(1) --tsv $(2) --out $(3)/$(4) --cut-off $(de_pvalue_cutoff) --species $(species) --feature $(call DEfilename2AL,$(2)) --browser ../../../$(BROWSER_DIR)/ --css ../../../$(CSS_FILE) --title "$(5)" -a $(annot_tsv) -m $(de_num_genes_per_table)
endef

# $(if $(findstring .kegg.,$1),--pathway)
# input,output,options,pipeline,contrast
define run_gse_report=
irap_report_gse --tsv $1 --out $2 $3  --gse_method "$(gse_tool):$(gse_method)" --pipeline $4 --contrast $5 --pvalue $(gse_pvalue)  --css ../../../$(CSS_FILE) 
endef


# 1 metric
# 2 TSV file
# 3 out dir
# 4 out file
# 5 title
# 6 feature
# --anotation ....
define GE_tsv2html=
	tsvGE2html -m $(1) --tsv $(2) --out $(3)/$(4) --species $(species)  --browser ../../../../$(BROWSER_DIR)/ --css ../../../../$(CSS_FILE) --title "$(5)" -a $(annot_tsv)  --gdef "$(call groupsdef2str)" --gnames "$(call groups2str)" -f $(6) --feat_mapping $(feat_mapping_file)
endef

#-x min value
#-r replicates
#-f feature (gene,exon,CDS)

#1 DEST FILE
#2 OUTDIR
#3 TSV FILE
define  gen_htseq_report=
	$(if $(3),irap_htseq_report.R $(2) $(3) $(de_min_count) && touch $(1),)
endef


ifndef IRAP_REPORT_MAIN_OPTIONS
IRAP_REPORT_MAIN_OPTIONS=
endif
# 
ifdef reuse_menu
IRAP_REPORT_MAIN_OPTIONS += --reuse-menu
endif

must_exist=$(if  $(realpath $(1)),,$(1))


clean_report: 
	@find $(name)/report/mapping/ $(name)/report/quant/ $(name)/report/de/  -maxdepth 1 -type f -exec rm -f {} \; 
	$(call p_info,Report folder partially cleaned up)

##############################################################################
# Produce a HTML report
#report: $(name)/report/index.html mapping_report quant_report de_report
phony_targets+=report_setup clean_report


report_setup: $(call must_exist,$(name)/report) $(call must_exist,$(name)/report/mapping/) $(call must_exist,$(name)/report/de/) $(call must_exist,$(name)/report/quant/) $(call rep_browse,report_browser_setup) $(call must_exist,$(name)/report/irap.css) $(call must_exist,$(name)/report/menu.css) $(feat_mapping_file)

$(name)/report/:
	mkdir -p $@

$(name)/report/mapping/:
	mkdir -p $@

$(name)/report/de/:
	mkdir -p $@

$(name)/report/quant/:
	mkdir -p $@

$(name)/report/irap.css: $(PATH2CSS_FILE)
	cp -f $< $@

$(name)/report/menu.css: $(IRAP_DIR)/aux/css/menu.css
	cp -f $< $@

#############################
# QC
phony_targets+=qc_report

qc_html_files=$(name)/report/qc.html

qc_report: $(qc_html_files)

ifeq ($(qc),none)
$(name)/report/qc.html: 

else
$(name)/report/qc.html: $(conf) $(call must_exist,$(name)/data/)
	irap_report_qc $(IRAP_REPORT_MAIN_OPTIONS) --conf $(conf) --rep_dir $(name)/report || ( rm -f $@ && exit 1)
endif

#############################
# TODO: info.html
phony_targets+=info_report
info_targets=$(name)/report/info.html $(name)/report/versions.html

info_report: report_setup $(info_targets)

$(name)/report/info.html: $(name)/report/$(call notdir,$(conf))
	irap_report_expinfo --conf $<  --css $(CSS_FILE) --out $@.tmp && mv $@.tmp $@

#
$(name)/report/versions.html: $(name)/report/software.tsv $(conf) 
	tsvSoftware2html -i $< -o $@.tmp && mv $@.tmp.html $@

$(name)/report/status.html:

$(name)/report/$(call notdir,$(conf)): $(conf)
	cp $< $@.tmp && mv $@.tmp $@

#############################
phony_targets+=mapping_report quant_report

mapping_report_targets=$(foreach m,$(call mapping_dirs), $(name)/report/mapping/$(shell basename $(m)).html) 

#$(name)/report/mapping/comparison.html 


mapping_report_files:
	echo $(call mapping_report_targets)
	echo $(call mapping_dirs)

print_mapping_dirs:
	echo $(MAPPING_DIRS)

mapping_report: report_setup $(call mapping_report_targets)


# files required for producing the mapping report
MAPPING_REPORT_PRE_STATS=$(foreach m,$(call mapping_dirs),  $(foreach p,$(pe),$(m)/$($(p)_dir)$(p).pe.hits.bam.stats $(m)/$($(p)_dir)$(p).pe.hits.bam.stats.csv $(m)/$($(p)_dir)$(p).pe.hits.bam.gene.stats) $(foreach s,$(se),$(m)/$($(s)_dir)$(s).se.hits.bam.stats.csv $(m)/$($(s)_dir)$(s).se.hits.bam.gene.stats $(m)/$($(s)_dir)$(s).se.hits.bam.stats))

# merge into a single file the statistics collected from the BAMs 
$(name)/%/stats_raw.tsv $(name)/%/stats_perc.tsv:  $(foreach p,$(pe),$(name)/%/$($(p)_dir)$(p).pe.hits.bam.stats.csv) $(foreach s,$(se),$(name)/%/$($(s)_dir)$(s).se.hits.bam.stats.csv)
	$(call pass_args_stdin,irap_bams2tsv,$(name)/$*/stats_raw.tsv, --pe "$(call remove_spaces,$(foreach p,$(pe),;$(name)/$*/$($(p)_dir)$(p).pe.hits.bam))" --se "$(call remove_spaces,$(foreach s,$(se),;$(name)/$*/$($(s)_dir)$(s).se.hits.bam))"  --pe_labels "$(call remove_spaces,$(foreach p,$(pe),;$(p)))" --se_labels "$(call remove_spaces,$(foreach s,$(se),;$(s)))" --out $(name)/$*/$*) && mv $(name)/$*/$*_mapping_stats_raw.tsv $(name)/$*/stats_raw.tsv && mv $(name)/$*/$*_mapping_stats_perc.tsv $(name)/$*/stats_perc.tsv

#
$(name)/%/featstats_raw.tsv $(name)/%/featstats_perc.tsv:  $(foreach p,$(pe),$(name)/%/$($(p)_dir)$(p).pe.hits.bam.stats) $(foreach s,$(se),$(name)/%/$($(s)_dir)$(s).se.hits.bam.stats)
	$(call pass_args_stdin,merge_featstats,$(name)/$*/featstats_raw.tsv, --header --stats "$(call remove_spaces,$(foreach p,$(pe),;$(name)/$*/$($(p)_dir)$(p).pe.hits.bam.stats))$(call remove_spaces,$(foreach p,$(se),;$(name)/$*/$($(p)_dir)$(p).se.hits.bam.stats))"  --labels "$(call remove_spaces,$(foreach p,$(pe) $(se),;$(p)))"  --out $(name)/$*/$*.tmp) && mv $(name)/$*/$*.tmp_featstats_raw.tsv $(name)/$*/featstats_raw.tsv && mv $(name)/$*/$*.tmp_featstats_perc.tsv $(name)/$*/featstats_perc.tsv

$(name)/%/genestats_raw.tsv $(name)/%/genestats_perc.tsv:  $(foreach p,$(pe),$(name)/%/$($(p)_dir)$(p).pe.hits.bam.gene.stats) $(foreach s,$(se),$(name)/%/$($(s)_dir)$(s).se.hits.bam.gene.stats)
	$(call pass_args_stdin,merge_featstats,$(name)/$*/genestats_raw.tsv, --stats "$(call remove_spaces,$(foreach p,$(pe),;$(name)/$*/$($(p)_dir)$(p).pe.hits.bam.gene.stats))$(call remove_spaces,$(foreach p,$(se),;$(name)/$*/$($(p)_dir)$(p).se.hits.bam.gene.stats))"  --labels "$(call remove_spaces,$(foreach p,$(pe) $(se),;$(p)))"  --out $(name)/$*/$*.gtmp) && mv $(name)/$*/$*.gtmp_featstats_raw.tsv $(name)/$*/genestats_raw.tsv && mv $(name)/$*/$*.gtmp_featstats_perc.tsv $(name)/$*/genestats_perc.tsv

# 
print_mapping_report_req: $(foreach m,$(mapping_dirs),$(name)/report/mapping/$(m).html_req)
$(name)/report/mapping/%.html_req:
	echo $(MAPPING_REPORT_PRE_STATS)

$(name)/report/mapping/%.html_doreq: $(MAPPING_REPORT_PRE_STATS)
	@echo "done"

# files required to produce the mapping report
mapping_report_req: $(MAPPING_REPORT_PRE_STATS)
	@echo "done"

# Mapping report for a specific mapper
$(name)/report/mapping/%.html: $(name)/%/  $(conf) $(call must_exist,$(name)/report/mapping/)  $(name)/%/stats_raw.tsv $(name)/%/stats_perc.tsv  $(name)/%/featstats_raw.tsv $(name)/%/featstats_perc.tsv  $(name)/%/genestats_raw.tsv 
	$(call pass_args_stdin,irap_report_mapping,$@, --out $(subst .html,,$@).1.html --mapper $* --bam_stats $(name)/$*/stats_raw.tsv --bam_statsp $(name)/$*/stats_perc.tsv --bam_fstats $(name)/$*/featstats_raw.tsv --bam_fstatsp $(name)/$*/featstats_perc.tsv --bam_gstats $(name)/$*/genestats_raw.tsv --css ../$(CSS_FILE) --cores $(max_threads) ) && mv $(subst .html,,$@).1.html  $@

# statistics per bam file
%.bam.gff3: %.bam $(gff3_file_abspath)
	bedtools coverage -abam $< -counts -b $(gff3_file_abspath) > $@.tmp && \
	mv $@.tmp $@

%.bam.stats: %.bam.gff3 
	mapping_feature_stats --in $< --out $@.tmp -c "`basename $*`" && mv $@.tmp $@

%.bam.stats.csv: %.bam 
	irapBAM2stats bam=$<

%.bam.gene.stats: %.bam $(name)/data/exons.bed $(name)/data/introns.bed
	echo -n "Exons	" > $@.tmp &&\
	bedtools intersect -abam $<  -b $(name)/data/exons.bed |samtools view -c - >> $@.tmp && echo >> $@ &&\
	echo -n "Introns	" >> $@.tmp &&\
	bedtools intersect -abam $<  -b $(name)/data/introns.bed |samtools view -c - >> $@.tmp && echo >> $@ && \
	expr `wc -l $@.tmp | cut -f 1 -d\ ` == 2 && \
	mv $@.tmp $@

# bed files required to get some extra stats
# exons.bed
$(name)/data/exons.bed: $(gff3_file_abspath) 
	cat $< | awk 'BEGIN{OFS="\t";} $$3=="exon" {print $$1,$$4,$$5}' | bedtools sort -i /dev/stdin | bedtools merge -i /dev/stdin > $@.tmp && \
	mv $@.tmp $@

# genes.bed
$(name)/data/genes.bed: $(gff3_file_abspath)
	cat $< | awk 'BEGIN{OFS="\t";} $$3=="gene" {print $$1,$$4,$$5}' |  bedtools sort -i /dev/stdin | bedtools merge -i /dev/stdin > $@.tmp && \
	mv $@.tmp $@

# introns
$(name)/data/introns.bed: $(name)/data/genes.bed $(name)/data/exons.bed
	bedtools subtract -a $< -b $(name)/data/exons.bed > $@.tmp && if [ `wc -l $@.tmp |cut -f 1 -d\ ` == 0 ]; then echo -e 'dummy_entry\t1\t1' > $@.tmp; fi && mv $@.tmp $@


# M
# 
define only_existing_files=
$(foreach f,$(1),$(if $(realpath $(f)),$(f) ,))
endef

define mappersFromReportPath=
$(subst /align_overall_comparison.png.tsv,,$(subst $(name)/report/mapping/,,$(1)))
endef

# only perform the comparison on the existing TSV files
$(name)/report/mapping/comparison.html: $(call only_existing_files,$(foreach m,$(call mapping_dirs), $(name)/report/mapping/$(shell basename $(m))/align_overall_comparison.png.tsv))
	mappers_comp_sum.R --tsv "$^" --labels "$(foreach f,$^, $(call mappersFromReportPath,$(f)))" --out $(@D)/comparison --css  ../../$(CSS_FILE) && touch $@
#	mappers_comp_sum.R --tsv "$^" --labels "$(foreach m,$(call mapping_dirs,$(name)), $(shell basename $(m)))" --out $(@D)/comparison --css  ../irap.css && touch $@


phony_targets+= 

########################
phony_targets+=quant_report quant_report_files
silent_targets+=quant_report quant_report_files

# define set_QUANT_HTML_FILES=
# $(eval override QUANT_HTML_FILES=$(foreach q,$(SUPPORTED_QUANT_METHODS),$(foreach m,$(SUPPORTED_MAPPERS),$(foreach f,gene exon transcript,$(foreach metric,raw nlib rpkm,$(call quant_target,$(m),$(q),$(metric),$(f)) ))))) $(QUANT_HTML_FILES)
# endef

# based on raw quantification and normalized expression values
define set_QUANT_HTML_FILES=
$(eval override QUANT_HTML_FILES=$(foreach f,$(foreach q,$(report_quant),$(foreach m,$(report_mappers),$(foreach l,gene transcript, $(foreach metric,raw nlib,$(call quant_target,$(m),$(q),$(metric),$(l)))))),$(f)) $(foreach f,$(foreach eqm,$(report_equant),$(foreach q,$(report_quant),$(foreach m,$(mapper),$(call equant_target,$(m),$(q),raw,$(eqm))))),$(f)) $(foreach f,$(foreach nm,$(report_norm_methods),$(foreach q,$(report_quant),$(foreach m,$(report_mappers),$(foreach l,gene transcript, $(foreach nt,$(report_norm_tools),$(call nquant_target,$(m),$(q),$(nm),$(l),$(nt))))))), $(f))) $(foreach f,$(foreach eqm,$(report_equant),$(foreach nm,$(report_norm_methods),$(foreach q,$(report_quant),$(foreach m,$(report_mappers), $(foreach nt,$(report_norm_tools),$(call enquant_target,$(m),$(q),$(nm),$(nt),$(eqm))))))), $(f))
endef


# disable for Atlas
ifdef atlas_run
define quant_html_files=
endef

else
define quant_html_files=
$(strip $(call cached_var,QUANT_HTML_FILES))
endef
endif

quant_report: report_setup $(call quant_html_files)

quant_report_files: 
	echo $(call quant_html_files)

#######################################
# Quant. at gene level

define ge_html2level=
$(subst transcript,CDS,$(patsubst %s,%,$(word 1,$(subst ., ,$(notdir $*)))))
endef

define ge_html2metric=
$(word 2,$(subst ., ,$(notdir $*)))
endef

# 
$(name)/report/quant/%.html: 
	$(call GE_tsv2html,$(call ge_html2metric,$*),$(call quiet_ls1,$(name)/$(subst _x_,/,$*).tsv),$(@D),$(notdir $*).t,$(subst _x_, x ,$(subst /,,$(dir $*))),$(call ge_html2level,$*)) && \
	cp $(subst .html,,$@).t.html $@


############################
# DE
phony_targets+=de_report de_report_files
silent_targets+=de_report_files

de_report: report_setup $(call de_html_files,$(name))

# just print the name of the files that will be produced
de_report_files:
	echo $(call de_html_files,$(name))


$(name)/report/%.genes_de.html: $(name)/%.genes_de.tsv $(annot_tsv)
	mkdir -p $(@D)
	$(call DE_tsv2html,$(subst _nd,,$(call DEfilepath2demethod,$@)),$<,$(@D),$(subst .html,,$(shell basename $@)),$(subst /, x ,$*))

############################
# GSE
phony_targets+=gse_report gse_report_files
silent_targets+=gse_report_files

# only generates the html iff the respective GSE tsv file exist
gse_report: report_setup $(call gse_html_files,$(name))

# just print the name of the files that will be produced
gse_report_files:
	echo $(call gse_html_files,$(name))


############################
# all targets
phony_targets+= report_all_targets

GEN_REPORT_QC_ONLY=$(if $(filter $(strip $(report_qc_only)),y),y,)

REPORT_TARGETS=report_setup $(info_targets)  $(if $(call GEN_REPORT_QC_ONLY), qc_report, qc_report mapping_report quant_report de_report gse_report )   end_report $(name)/report/about.html

#$(info $(REPORT_TARGETS))
report_all_targets:  $(REPORT_TARGETS)


$(name)/report/about.html: 
	cat $(IRAP_DIR)/aux/html/page.header.html $(IRAP_DIR)/aux/html/about.html  $(IRAP_DIR)/aux/html/page.footer.html >  $@


#########################
#mapping_report de_report
# TODO: remove/fix this in the future (currently necessary to update the menu)
phony_targets+=end_report

end_report: $(name)/report/index.html $(call must_exist,$(name)/report/irap.css)


# TODO: replace versions.html by info_report
# TODO $(call must_exist,$(name)/report/status.html)a
ifeq ($(report_qc_only),y)
$(name)/report/index.html: $(conf) $(info_targets) $(qc_html_files) $(call rep_browse,$(name)/report/jbrowse/index.html)  $(name)/report/about.html $(call must_exist,$(name)/report/irap.css) $(call must_exist,$(name)/report/menu.css)
	cp  $(name)/report/info.html $@ &&
	irap_report_main $(IRAP_REPORT_MAIN_OPTIONS) --conf $(conf) --rep_dir $(name)/report -m "" -q "" -d "" &&
	sleep 2 &&
	touch $@
else
$(name)/report/index.html: $(conf) $(info_targets)  $(call quant_html_files) $(qc_html_files) $(call mapping_report_targets) $(call de_html_files,$(name)) $(call gse_html_files,$(name))  $(call rep_browse,$(name)/report/jbrowse/index.html)  $(name)/report/about.html $(call must_exist,$(name)/report/irap.css) $(call must_exist,$(name)/report/menu.css)
	cp  $(name)/report/info.html $@ &&
	irap_report_main $(IRAP_REPORT_MAIN_OPTIONS) --conf $(conf) --rep_dir $(name)/report -m "$(call mapping_dirs)" -q "$(call quant_dirs,$(name))" -d "$(call de_dirs,$(name))" &&
	sleep 2 &&
	touch $@
endif
