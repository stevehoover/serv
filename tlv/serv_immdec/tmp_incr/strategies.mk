.DEFAULT_GOAL := all

strategies/serv_immdec.clk/sby_seq/status:
	@echo "Running strategy 'sby_seq' on 'serv_immdec.clk'.."
	@bash -c "cd strategies/serv_immdec.clk/sby_seq; source run.sh"

.PHONY: all summary
all: strategies/serv_immdec.clk/sby_seq/status
	$(MAKE) -f strategies.mk summary
summary:
	@rc=0 ; \
	while read f; do \
		p=$${f#strategies/} ; p=$${p%/*/status} ; \
		if grep -q "PASS" $$f ; then \
			echo "* Successfully proved equivalence of partition $$p" ; \
		else \
			echo "* Failed to prove equivalence of partition $$p" ; rc=1 ; \
		fi ; \
	done < summary_targets.list ; \
	if [ "$$rc" -eq 0 ] ; then \
		echo "* Successfully proved designs equivalent" ; \
	fi
