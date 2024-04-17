# Gcov out-of-tree usage example

This is a proof-of-concept to illustrate how to compile executable with gcov support, install them in a Docker container, run your tests, copy the coverage artifacts to another container, and generate coverage reports.

## Project structure

The project structuring is:

```
.
├── include         # Header files
├── src             # Source code
├── Makefile        # Runs the PoC
└── README.md       # This file
```

All the outputs are placed here:

```
.
└── out
    ├── build       # The build outputs go here
    ├── container   # This simulates the docker image, so everything is installed here
    └── coverage    # At the end, the coverage reports are generated here
```

## Running the PoC

To run the proof-of-concept, clone this project to a directory, and run `make` from there.

## How does it work

The [Makefile](./Makefile) does the following:

1. Builds the sample app with coverage enabled.
2. Creates a simulated docker container by installing the app and associated gcno files.
3. Runs the app from within the Docker container, setting the appropriate environment variables for [cross-profiling with gcc and gcov](https://gcc.gnu.org/onlinedocs/gcc/Cross-profiling.html).
4. Post-processes the results, generating a coverage report.

These steps are triggered through Makefile dependencies. The default goal is `report-coverage` (step 4). Step 4 depends on step 3, 3 on 2, and 2 on 1. Running `make` without arguments therefore builds `report-coverage` (Step 4), which builds `run-test-in-docker` (Step 3) as a prerequisite, which builds `build-docker` (Step 2) as a prerequisite, which builds the app (Step 1) as a prerequisite.

The `run-test-in-docker` and `report-coverage` goals are set to run irrespective of whether the build outputs are already met (Uses [.PHONY](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html)). All other goals will not be rerun unless the inputs change.
