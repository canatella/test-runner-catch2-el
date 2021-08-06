hello-world: src/main.cpp
	$(CC) -o $(@) $(<)

hello-world-test: tests/app_test.cpp
	$(CC) -o $(@) $(<)

clean:
	rm -fr hello-word hello-world-test

.PHONY: clean
