docs: .
	doxygen Doxyfile && make -C docs/latex && mv docs/latex/refman.pdf  epyc_linux_feature_doc.pdf
clean:
	rm -rf docs/ *.pdf
