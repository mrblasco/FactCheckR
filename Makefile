# Makefile for preparing the R package

PACKAGE_NAME := FactCheckR
R_CMD := Rscript
CACHE := cache

all: 

docs:
	@echo "Generating documentation..."
	$(R_CMD) -e "devtools::document()"

data: create_data.R
	@echo "Creating data..."
	$(R_CMD) create_data.R

build: clean docs
	@echo "Building package..."
	$(R_CMD) -e "devtools::build()"

check:
	@echo "Checking package..."
	$(R_CMD) -e "devtools::check()"

install:
	@echo "Installing package..."
	$(R_CMD) -e "devtools::install()"

clean:
	@echo "Cleaning up..."
	@rm -rf *.tar.gz *.Rcheck
	@rm -rf $(CACHE)/__packages
	@find . -name "*.Rhistory" -delete
