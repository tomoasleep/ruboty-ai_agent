# spec

This directory contains the RSpec files for testing the functionality of the `ruboty-ai_agent` gem.

## support/ directory

The `support/` directory contains helper files and shared contexts that can be used across multiple spec files to reduce duplication and improve readability.

### support/factories

The `factories/` directory contains factory definitions for creating test objects.

These factories can be used to easily generate instances of classes needed for testing without mocks.
Please prefer using real objects (in factories) over mocks to ensure that tests are more reliable and maintainable.

### support/mocks

The `mocks/` directory contains web mock definitions for simulating external dependencies.
When writing specs with external communications, please use web mocking from this directory.
