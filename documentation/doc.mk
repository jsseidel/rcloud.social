#
# This Makefile is used to generate the external documenation HTML files.
#

# Path to the base of the GUI documentation.
# This is the folder containing the version folder (e.g. 1.3,1.4,...)
ifndef DOC_DIR
  DOC_DIR = ../doc
endif

# Output directory
ifndef OUTDOC_DIR
  OUTDOC_DIR = ./out
endif

# Path from this makefile to the root of the source tree.
ifndef BASESRC
  BASESRC = ..
endif

# Path from the installed sub-topics (e.g tryit,gallery,tutorials, ...) index.html to the site root directory.
ifndef BASEPATH
  BASEPATH = ..
endif


# Path from the GUI doc 'doc.html' to the site root.
DOC_BASEPATH = ../../../$(BASEPATH)

# Get a list of the directories rooted on $(DOC_DIR)
DIRS  = $(shell find $(DOC_DIR) -type d)

# Find all files in folders listed in $(DIRS) with 'md' extension.
SRC =  $(foreach DIR,$(DIRS),$(wildcard $(DIR)/*.md))

# Generate an output file name for each src file.
DST =  $(foreach fn,$(SRC), $(subst .md,.html,$(subst $(DOC_DIR),$(OUTDOC_DIR),$(fn))))

# Create a list of output directories
DST_DIRS = $(foreach dir,$(DIRS),$(subst  $(DOC_DIR),$(OUTDOC_DIR),$(dir)))

# Create a list of source image dir's
SRC_IMG_DIRS = $(foreach src,$(SRC),$(dir $(src))img)

# Create a list of source images
SRC_IMG_FNS  = $(foreach dir,$(SRC_IMG_DIRS),$(wildcard $(dir)/*))

# Create a list of output image dirs
DST_IMG_DIRS = $(foreach dir,$(SRC_IMG_DIRS), $(subst $(DOC_DIR),$(OUTDOC_DIR),$(dir)))

# Create a list of output images
DST_IMG_FNS = $(foreach fn,$(SRC_IMG_FNS), $(subst $(DOC_DIR),$(OUTDOC_DIR),$(fn)))

# Helpfull abreviations.
HTML     = $(BASESRC)/html
EMPTY_PD = $(BASESRC)/empty.pd

# Form the header/footer template souce and destination names.
GEN_NAMES   = head body_top body_bottom
GEN_FNS     = $(foreach name,$(GEN_NAMES),doc_$(name).html)
GEN_TMPLS   = $(foreach name,$(GEN_NAMES),$(HTML)/$(name)_template.html)


all :  $(DST) $(DST_IMG_FNS)

clean-all : clean
	rm -f $(DST) $(DST_IMG_FNS)

clean :
	rm -f $(GEN_FNS)


define make-goal
$1: $2  doc_html.template $(GEN_FNS)
	mkdir -p $$(dir $$@)
	pandoc \
	--from=markdown \
	--to=html5 \
	--template=doc_html.template \
	--css=$(DOC_BASEPATH)/css/doc.css  \
	--include-in-head=doc_head.html \
	--include-before-body=doc_body_top.html \
	--include-after-body=doc_body_bottom.html \
	--toc --toc-depth=4 \
	-o $$@ $$<
endef

# Generate a recipe for each documenation markdown file
$(foreach fn,$(SRC),$(eval $(call make-goal,$(subst .md,.html, $(subst $(DOC_DIR),$(OUTDOC_DIR),$(fn))) ,$(fn))))

# Copy image files to the output tree
$(DST_IMG_FNS) : $(OUTDOC_DIR)/% : $(DOC_DIR)/%
	mkdir -p $(dir $@)
	cp $< $@

#
# Use $(BASESRC)/hmtl/*_template.html to generate a include
# files with the CSS,Javscript and href refrences pointing to the correct
# location.
#
# The globally referenced CSS and Javascript files are in folders in
# the site's root directory (css and js). The references to these
# files contained in the <style> and <script> tags of the client HTML
# files will therefore vary depending on their depth in the tree.
# 'href' attributes in the global page headers have a similar problem.
# This means the the references must be generated according to the
# location of the HTML files. We solve this by using a pandoc template
# file containing the global references (html/head_template.html)
# and filling in the path to the 'css' and 'js' folders using a
# variable.  The resulting output, head.html, is then inserted into
# the final output file by using the --include-in-header pandoc
# option.
$(GEN_FNS) : doc_%.html : $(HTML)/%_template.html
	pandoc --template=$< --variable=basepath:$(DOC_BASEPATH) -o $@ $(EMPTY_PD)


