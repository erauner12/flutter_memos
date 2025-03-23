# Testing with Mocks

Some tests in this project use Mockito for mocking dependencies. Before running the tests, you need to generate the mock classes.

## Generating Mocks

Run the following command from the project root:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Alternatively, use the provided shell script:

```sh
./test/build_mocks.sh
```

This will generate the necessary `.mocks.dart` files needed by the tests.

## Common Issues

If you encounter errors like:

- "Target of URI doesn't exist: 'memo_providers_test.mocks.dart'"
- "Undefined class 'MockApiService'"

It means you need to run the mock generation command.

## Automated Testing

When running tests in CI/CD, make sure to include the mock generation step in your pipeline before the test step.